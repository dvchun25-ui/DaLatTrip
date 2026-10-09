import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service quản lý định vị GPS và tính toán khoảng cách thực tế.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Tọa độ mặc định trung tâm Đà Lạt (Hồ Xuân Hương / Chợ Đà Lạt)
  static const double defaultLat = 11.9404;
  static const double defaultLng = 108.4383;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Lấy vị trí GPS hiện tại của thiết bị (có fallback nếu không có quyền/tắt GPS)
  Future<Position?> getCurrentLocation() async {
    if (kIsWeb) {
      return _fallbackPosition();
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service disabled, using default Da Lat center');
        return _fallbackPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return _fallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return _fallbackPosition();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _fallbackPosition();
    }
  }

  /// Tính khoảng cách (km) từ điểm A đến điểm B
  double calculateDistanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000.0;
  }

  /// Tính khoảng cách từ vị trí GPS hiện tại (hoặc trung tâm Đà Lạt) tới địa điểm
  double? getDistanceToPlaceInKm(double? targetLat, double? targetLng) {
    if (targetLat == null || targetLng == null) return null;
    final pos = _currentPosition ?? _fallbackPosition();
    return calculateDistanceInKm(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: targetLat,
      endLng: targetLng,
    );
  }

  /// Định dạng chuỗi khoảng cách hiển thị m/km mượt mà
  String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  Position _fallbackPosition() {
    return Position(
      longitude: defaultLng,
      latitude: defaultLat,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
