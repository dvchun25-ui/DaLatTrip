import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache ảnh địa điểm dùng chung toàn ứng dụng.
///
/// Ảnh ít được xem nhất sẽ tự bị loại khi vượt quá 50 file hoặc không được
/// sử dụng trong 30 ngày. Hệ điều hành vẫn có thể dọn thư mục cache khi cần.
class PlaceImageCache {
  PlaceImageCache._();

  static const key = 'dalattripPlaceThumbnailsV2';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50,
    ),
  );

}
