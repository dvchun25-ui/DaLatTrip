import '../../../domain/entities/place.dart';
import '../../../core/constants/api_constants.dart';

/// Trả về nguồn ảnh đã cấu hình cho một địa điểm.
///
/// Thứ tự ưu tiên:
/// 1. Asset cục bộ — hiển thị ngay, không cần chờ mạng hay cache.
/// 2. URL/đường dẫn backend — dùng để tương thích với dữ liệu từ API.
///
/// Không tìm ảnh lúc runtime; dữ liệu đã được chuẩn bị trước bằng script.
class PlaceImageService {
  const PlaceImageService();

  String? getImageUrl(Place place) {
    // 1. Ưu tiên imageUrl cố định nếu có
    final customImage = place.imageUrl?.trim();
    if (customImage != null && customImage.isNotEmpty) {
      if (customImage.startsWith('/')) {
        return Uri.parse(ApiConstants.baseUrl).resolve(customImage).toString();
      }
      return customImage;
    }

    return null;
  }

  void clearCache() {}
}
