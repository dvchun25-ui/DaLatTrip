import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/supabase_media_repository.dart';
import '../../domain/repositories/media_repository.dart';
import 'data/local_avatar_repository.dart';
import 'data/repositories/firestore_user_repository.dart';

class AvatarUploadResult {
  final String displayPath;
  final bool uploaded;
  final String? errorMessage;

  const AvatarUploadResult({
    required this.displayPath,
    required this.uploaded,
    this.errorMessage,
  });
}

class AvatarController {
  AvatarController({
    FirebaseAuth? auth,
    ImagePicker? picker,
    MediaRepository? mediaRepository,
    LocalAvatarRepository? localRepository,
    FirestoreUserRepository? userRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _picker = picker ?? ImagePicker(),
       _mediaRepository = mediaRepository ?? SupabaseMediaRepository(),
       _localRepository = localRepository ?? LocalAvatarRepository.instance,
       _userRepository = userRepository ?? FirestoreUserRepository.instance;

  final FirebaseAuth _auth;
  final ImagePicker _picker;
  final MediaRepository _mediaRepository;
  final LocalAvatarRepository _localRepository;
  final FirestoreUserRepository _userRepository;

  Future<AvatarUploadResult?> pickAndUploadAvatar() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập để đổi ảnh đại diện.');
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final source = File(picked.path);
    final localPath = await _localRepository.saveAvatar(user.uid, source);
    if (localPath == null) {
      throw StateError('Không thể lưu ảnh đại diện cục bộ.');
    }

    try {
      final avatarUrl = await _mediaRepository.uploadAvatar(
        file: source,
        firebaseUid: user.uid,
      );
      await _userRepository.updateAvatarUrl(user.uid, avatarUrl);
      return AvatarUploadResult(displayPath: avatarUrl, uploaded: true);
    } catch (error) {
      return AvatarUploadResult(
        displayPath: localPath,
        uploaded: false,
        errorMessage: error.toString(),
      );
    }
  }
}
