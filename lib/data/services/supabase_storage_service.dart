import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client_provider.dart';

class MediaUploadException implements Exception {
  final String message;
  final Object? cause;

  const MediaUploadException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SupabaseStorageService {
  SupabaseStorageService({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;

  SupabaseClient get _client =>
      _providedClient ?? SupabaseClientProvider.client;

  static const String avatarsBucket = 'avatars';
  static const String checkInsBucket = 'checkins';
  static const String communityBucket = 'community';
  static const String chatMediaBucket = 'chat-media';

  static const int _maxAvatarBytes = 3 * 1024 * 1024;
  static const int _maxPhotoBytes = 8 * 1024 * 1024;
  static const int _maxVideoBytes = 20 * 1024 * 1024;

  Future<String> uploadAvatar({
    required File file,
    required String firebaseUid,
  }) async {
    _requireCurrentUser(firebaseUid);
    final prepared = await _prepareJpeg(
      file,
      maxDimension: 768,
      quality: 84,
      maxBytes: _maxAvatarBytes,
    );
    try {
      return await _upload(
        bucket: avatarsBucket,
        path: '$firebaseUid/avatar.jpg',
        file: prepared,
        contentType: 'image/jpeg',
        upsert: true,
      );
    } finally {
      await _deleteTemporaryFile(prepared, original: file);
    }
  }

  Future<String> uploadCheckInPhoto({
    required File file,
    required String firebaseUid,
    required String roomId,
    DateTime? capturedAt,
  }) async {
    _requireCurrentUser(firebaseUid);
    final prepared = await _prepareJpeg(
      file,
      maxDimension: 1600,
      quality: 82,
      maxBytes: _maxPhotoBytes,
    );
    final timestamp = (capturedAt ?? DateTime.now()).millisecondsSinceEpoch;
    try {
      return await _upload(
        bucket: checkInsBucket,
        path: '$firebaseUid/${_safeSegment(roomId)}/$timestamp.jpg',
        file: prepared,
        contentType: 'image/jpeg',
      );
    } finally {
      await _deleteTemporaryFile(prepared, original: file);
    }
  }

  Future<String> uploadCheckInVideo({
    required File file,
    required String firebaseUid,
    required String roomId,
    required int durationSeconds,
    DateTime? capturedAt,
  }) async {
    _requireCurrentUser(firebaseUid);
    if (durationSeconds < 1 || durationSeconds > 3) {
      throw const MediaUploadException(
        'Video check-in phải dài tối đa 3 giây.',
      );
    }
    await _validateFile(file, maxBytes: _maxVideoBytes);
    final timestamp = (capturedAt ?? DateTime.now()).millisecondsSinceEpoch;
    return _upload(
      bucket: checkInsBucket,
      path: '$firebaseUid/${_safeSegment(roomId)}/$timestamp.mp4',
      file: file,
      contentType: 'video/mp4',
    );
  }

  Future<String> uploadCommunityMedia({
    required File file,
    required String firebaseUid,
    required String postId,
  }) async {
    _requireCurrentUser(firebaseUid);
    return _uploadGenericMedia(
      bucket: communityBucket,
      prefix: '$firebaseUid/${_safeSegment(postId)}',
      file: file,
    );
  }

  Future<String> uploadChatMedia({
    required File file,
    required String firebaseUid,
    required String conversationId,
  }) async {
    _requireCurrentUser(firebaseUid);
    return _uploadGenericMedia(
      bucket: chatMediaBucket,
      prefix: '$firebaseUid/${_safeSegment(conversationId)}',
      file: file,
    );
  }

  Future<void> deleteMedia({
    required String bucket,
    required String path,
  }) async {
    _validateBucket(bucket);
    try {
      await _client.storage
          .from(bucket)
          .remove([path])
          .timeout(const Duration(seconds: 30));
    } catch (error) {
      throw MediaUploadException('Không thể xóa media trên Supabase.', error);
    }
  }

  String getMediaUrl({required String bucket, required String path}) {
    _validateBucket(bucket);
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> _uploadGenericMedia({
    required String bucket,
    required String prefix,
    required File file,
  }) async {
    final extension = _extension(file.path);
    final isVideo = extension == 'mp4' || extension == 'mov';
    if (isVideo) {
      await _validateFile(file, maxBytes: _maxVideoBytes);
      return _upload(
        bucket: bucket,
        path: '$prefix/${DateTime.now().millisecondsSinceEpoch}.mp4',
        file: file,
        contentType: 'video/mp4',
      );
    }

    final prepared = await _prepareJpeg(
      file,
      maxDimension: 1600,
      quality: 82,
      maxBytes: _maxPhotoBytes,
    );
    try {
      return await _upload(
        bucket: bucket,
        path: '$prefix/${DateTime.now().millisecondsSinceEpoch}.jpg',
        file: prepared,
        contentType: 'image/jpeg',
      );
    } finally {
      await _deleteTemporaryFile(prepared, original: file);
    }
  }

  Future<String> _upload({
    required String bucket,
    required String path,
    required File file,
    required String contentType,
    bool upsert = false,
  }) async {
    _validateBucket(bucket);
    await _validateFile(
      file,
      maxBytes: contentType.startsWith('video/')
          ? _maxVideoBytes
          : _maxPhotoBytes,
    );
    try {
      await _client.storage
          .from(bucket)
          .upload(
            path,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: upsert,
              contentType: contentType,
            ),
          )
          .timeout(const Duration(seconds: 45));
      return getMediaUrl(bucket: bucket, path: path);
    } on StorageException catch (error) {
      throw MediaUploadException(
        'Supabase Storage từ chối tải media: ${error.message}',
        error,
      );
    } on TimeoutException catch (error) {
      throw MediaUploadException('Tải media quá thời gian cho phép.', error);
    } catch (error) {
      throw MediaUploadException('Không thể tải media lên Supabase.', error);
    }
  }

  Future<File> _prepareJpeg(
    File source, {
    required int maxDimension,
    required int quality,
    required int maxBytes,
  }) async {
    await _validateFile(source, maxBytes: 30 * 1024 * 1024);
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const MediaUploadException('Định dạng ảnh không được hỗ trợ.');
      }
      final resized =
          decoded.width > maxDimension || decoded.height > maxDimension
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDimension : null,
              height: decoded.height > decoded.width ? maxDimension : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;
      final encoded = img.encodeJpg(resized, quality: quality);
      if (encoded.length > maxBytes) {
        throw MediaUploadException(
          'Ảnh sau khi nén vẫn vượt quá ${maxBytes ~/ (1024 * 1024)} MB.',
        );
      }
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/dalattrip_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(encoded, flush: true);
      return tempFile;
    } on MediaUploadException {
      rethrow;
    } catch (error) {
      throw MediaUploadException(
        'Không thể xử lý ảnh trước khi tải lên.',
        error,
      );
    }
  }

  Future<void> _validateFile(File file, {required int maxBytes}) async {
    if (!await file.exists()) {
      throw const MediaUploadException('Không tìm thấy file media.');
    }
    final length = await file.length();
    if (length <= 0) {
      throw const MediaUploadException('File media rỗng.');
    }
    if (length > maxBytes) {
      throw MediaUploadException(
        'File vượt quá ${maxBytes ~/ (1024 * 1024)} MB.',
      );
    }
  }

  void _requireCurrentUser(String firebaseUid) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw const MediaUploadException('Bạn cần đăng nhập để tải media.');
    }
    if (firebaseUid != currentUid) {
      throw const MediaUploadException(
        'Không thể tải media thay cho người dùng khác.',
      );
    }
  }

  void _validateBucket(String bucket) {
    const allowed = {
      avatarsBucket,
      checkInsBucket,
      communityBucket,
      chatMediaBucket,
    };
    if (!allowed.contains(bucket)) {
      throw const MediaUploadException('Bucket media không hợp lệ.');
    }
  }

  String _safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  String _extension(String path) {
    final index = path.lastIndexOf('.');
    return index < 0 ? '' : path.substring(index + 1).toLowerCase();
  }

  Future<void> _deleteTemporaryFile(File file, {required File original}) async {
    if (file.path == original.path) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('Không xóa được ảnh tạm: $error');
    }
  }
}
