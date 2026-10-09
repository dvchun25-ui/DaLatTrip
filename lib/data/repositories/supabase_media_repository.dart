import 'dart:io';

import '../../domain/repositories/media_repository.dart';
import '../services/supabase_storage_service.dart';

class SupabaseMediaRepository implements MediaRepository {
  SupabaseMediaRepository({SupabaseStorageService? storageService})
    : _storage = storageService ?? SupabaseStorageService();

  final SupabaseStorageService _storage;

  @override
  Future<String> uploadAvatar({
    required File file,
    required String firebaseUid,
  }) => _storage.uploadAvatar(file: file, firebaseUid: firebaseUid);

  @override
  Future<String> uploadCheckInPhoto({
    required File file,
    required String firebaseUid,
    required String roomId,
    DateTime? capturedAt,
  }) => _storage.uploadCheckInPhoto(
    file: file,
    firebaseUid: firebaseUid,
    roomId: roomId,
    capturedAt: capturedAt,
  );

  @override
  Future<String> uploadCheckInVideo({
    required File file,
    required String firebaseUid,
    required String roomId,
    required int durationSeconds,
    DateTime? capturedAt,
  }) => _storage.uploadCheckInVideo(
    file: file,
    firebaseUid: firebaseUid,
    roomId: roomId,
    durationSeconds: durationSeconds,
    capturedAt: capturedAt,
  );

  @override
  Future<String> uploadCommunityMedia({
    required File file,
    required String firebaseUid,
    required String postId,
  }) => _storage.uploadCommunityMedia(
    file: file,
    firebaseUid: firebaseUid,
    postId: postId,
  );

  @override
  Future<String> uploadChatMedia({
    required File file,
    required String firebaseUid,
    required String conversationId,
  }) => _storage.uploadChatMedia(
    file: file,
    firebaseUid: firebaseUid,
    conversationId: conversationId,
  );

  @override
  Future<void> deleteMedia({required String bucket, required String path}) =>
      _storage.deleteMedia(bucket: bucket, path: path);

  @override
  String getMediaUrl({required String bucket, required String path}) =>
      _storage.getMediaUrl(bucket: bucket, path: path);
}
