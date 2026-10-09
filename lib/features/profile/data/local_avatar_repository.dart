import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract class AvatarRepository {
  Future<String?> saveAvatar(String uid, File imageFile);
  Future<String?> getAvatarPath(String uid);
  Future<void> deleteAvatar(String uid);
}

class LocalAvatarRepository implements AvatarRepository {
  static final LocalAvatarRepository instance = LocalAvatarRepository._internal();
  factory LocalAvatarRepository() => instance;
  LocalAvatarRepository._internal();

  Future<Directory> _getAvatarDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${docsDir.path}/dalattrip/avatars');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    return avatarDir;
  }

  @override
  Future<String?> saveAvatar(String uid, File imageFile) async {
    try {
      final dir = await _getAvatarDir();
      final targetPath = '${dir.path}/$uid.jpg';
      final savedFile = await imageFile.copy(targetPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Lỗi saveAvatar: $e');
      return null;
    }
  }

  @override
  Future<String?> getAvatarPath(String uid) async {
    try {
      final dir = await _getAvatarDir();
      final file = File('${dir.path}/$uid.jpg');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      debugPrint('Lỗi getAvatarPath: $e');
    }
    return null;
  }

  @override
  Future<void> deleteAvatar(String uid) async {
    try {
      final dir = await _getAvatarDir();
      final file = File('${dir.path}/$uid.jpg');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Lỗi deleteAvatar: $e');
    }
  }
}
