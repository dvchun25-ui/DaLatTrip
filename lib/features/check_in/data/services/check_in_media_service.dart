import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/check_in_entry.dart';

class CheckInMediaService {
  static final CheckInMediaService instance = CheckInMediaService._internal();
  factory CheckInMediaService() => instance;
  CheckInMediaService._internal();

  /// Lưu file media (ảnh hoặc video 3s) vào bộ nhớ cục bộ persistent
  Future<String> saveMedia({
    required String roomId,
    required String userId,
    required String checkInId,
    required File sourceFile,
    required CheckInMediaType mediaType,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = mediaType == CheckInMediaType.video ? 'mp4' : 'jpg';
    final targetDir = Directory('${docsDir.path}/dalattrip/checkins/$roomId/$userId');

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetPath = '${targetDir.path}/$checkInId.$ext';
    debugPrint('Lưu media checkin persistent tại: $targetPath');
    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }
}
