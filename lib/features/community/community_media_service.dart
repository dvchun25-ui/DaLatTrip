import 'dart:io';

import '../../data/repositories/supabase_media_repository.dart';
import '../../domain/repositories/media_repository.dart';

class CommunityMediaService {
  CommunityMediaService({MediaRepository? mediaRepository})
    : _mediaRepository = mediaRepository ?? SupabaseMediaRepository();

  final MediaRepository _mediaRepository;

  Future<String> uploadPostMedia({
    required File file,
    required String firebaseUid,
    required String postId,
  }) => _mediaRepository.uploadCommunityMedia(
    file: file,
    firebaseUid: firebaseUid,
    postId: postId,
  );
}
