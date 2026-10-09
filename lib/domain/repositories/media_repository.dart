import 'dart:io';

abstract class MediaRepository {
  Future<String> uploadAvatar({
    required File file,
    required String firebaseUid,
  });

  Future<String> uploadCheckInPhoto({
    required File file,
    required String firebaseUid,
    required String roomId,
    DateTime? capturedAt,
  });

  Future<String> uploadCheckInVideo({
    required File file,
    required String firebaseUid,
    required String roomId,
    required int durationSeconds,
    DateTime? capturedAt,
  });

  Future<String> uploadCommunityMedia({
    required File file,
    required String firebaseUid,
    required String postId,
  });

  Future<String> uploadChatMedia({
    required File file,
    required String firebaseUid,
    required String conversationId,
  });

  Future<void> deleteMedia({required String bucket, required String path});

  String getMediaUrl({required String bucket, required String path});
}
