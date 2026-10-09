import 'dart:io';

import '../../data/repositories/supabase_media_repository.dart';
import '../../domain/repositories/media_repository.dart';
import 'domain/entities/check_in_entry.dart';

class CheckInUploadService {
  CheckInUploadService({MediaRepository? mediaRepository})
    : _mediaRepository = mediaRepository ?? SupabaseMediaRepository();

  final MediaRepository _mediaRepository;

  Future<String> upload({
    required File file,
    required String firebaseUid,
    required String roomId,
    required CheckInMediaType mediaType,
    required DateTime capturedAt,
    required int durationSeconds,
  }) {
    if (mediaType == CheckInMediaType.video) {
      return _mediaRepository.uploadCheckInVideo(
        file: file,
        firebaseUid: firebaseUid,
        roomId: roomId,
        durationSeconds: durationSeconds,
        capturedAt: capturedAt,
      );
    }
    return _mediaRepository.uploadCheckInPhoto(
      file: file,
      firebaseUid: firebaseUid,
      roomId: roomId,
      capturedAt: capturedAt,
    );
  }
}
