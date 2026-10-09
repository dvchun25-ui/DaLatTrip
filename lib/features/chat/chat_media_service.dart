import 'dart:io';

import '../../data/repositories/supabase_media_repository.dart';
import '../../domain/repositories/media_repository.dart';

class ChatMediaService {
  ChatMediaService({MediaRepository? mediaRepository})
    : _mediaRepository = mediaRepository ?? SupabaseMediaRepository();

  final MediaRepository _mediaRepository;

  Future<String> uploadMessageMedia({
    required File file,
    required String firebaseUid,
    required String conversationId,
  }) => _mediaRepository.uploadChatMedia(
    file: file,
    firebaseUid: firebaseUid,
    conversationId: conversationId,
  );
}
