import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../check_in_upload_service.dart';
import '../../domain/entities/check_in_entry.dart';

class CheckInMediaSaveResult {
  final String localPath;
  final String? mediaUrl;
  final Object? uploadError;

  const CheckInMediaSaveResult({
    required this.localPath,
    this.mediaUrl,
    this.uploadError,
  });

  bool get uploaded => mediaUrl != null && mediaUrl!.isNotEmpty;
  String get primaryPath => uploaded ? mediaUrl! : localPath;
}

class CheckInMediaService {
  static final CheckInMediaService instance = CheckInMediaService._internal();
  factory CheckInMediaService() => instance;
  CheckInMediaService._internal();

  /// Lưu file media (ảnh hoặc video 3s) vào bộ nhớ cục bộ persistent
  Future<CheckInMediaSaveResult> saveMedia({
    required String roomId,
    required String userId,
    required String checkInId,
    required File sourceFile,
    required CheckInMediaType mediaType,
    required DateTime capturedAt,
    required int durationSeconds,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = mediaType == CheckInMediaType.video ? 'mp4' : 'jpg';
    final targetDir = Directory(
      '${docsDir.path}/dalattrip/checkins/$roomId/$userId',
    );

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetPath = '${targetDir.path}/$checkInId.$ext';
    debugPrint('Lưu media checkin persistent tại: $targetPath');
    final savedFile = await sourceFile.copy(targetPath);
    try {
      final mediaUrl = await CheckInUploadService().upload(
        file: savedFile,
        firebaseUid: userId,
        roomId: roomId,
        mediaType: mediaType,
        capturedAt: capturedAt,
        durationSeconds: durationSeconds,
      );
      return CheckInMediaSaveResult(
        localPath: savedFile.path,
        mediaUrl: mediaUrl,
      );
    } catch (error) {
      debugPrint('Không tải được check-in lên Supabase: $error');
      return CheckInMediaSaveResult(
        localPath: savedFile.path,
        uploadError: error,
      );
    }
  }
}
