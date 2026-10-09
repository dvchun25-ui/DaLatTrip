import 'package:flutter/foundation.dart';
import '../../../../core/services/location_service.dart';
import '../../../../data/datasources/local_place_data_source.dart';
import '../../../../data/models/place_model.dart';

class CheckInLocationInfo {
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String placeName;
  final String formattedLabel;

  const CheckInLocationInfo({
    this.latitude,
    this.longitude,
    this.placeId,
    required this.placeName,
    required this.formattedLabel,
  });
}

class CheckInLocationService {
  static final CheckInLocationService instance = CheckInLocationService._internal();
  factory CheckInLocationService() => instance;
  CheckInLocationService._internal();

  final LocationService _locationService = LocationService();
  final LocalPlaceDataSource _placeDataSource = LocalPlaceDataSource();

  /// Lấy vị trí GPS hiện tại và tìm địa điểm Đà Lạt gần nhất từ dataset
  Future<CheckInLocationInfo> getCurrentCheckInLocation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos == null) {
        return const CheckInLocationInfo(
          placeName: 'Đà Lạt',
          formattedLabel: '📍 Đà Lạt',
        );
      }

      // Tìm địa điểm trong dataset gần GPS user nhất
      final places = await _placeDataSource.getAllPlaces();
      PlaceModel? nearestPlace;
      double minDistance = double.infinity;

      for (final place in places) {
        if (place.latitude != null && place.longitude != null) {
          final dist = _locationService.calculateDistanceInKm(
            startLat: pos.latitude,
            startLng: pos.longitude,
            endLat: place.latitude!,
            endLng: place.longitude!,
          );
          if (dist < minDistance) {
            minDistance = dist;
            nearestPlace = place;
          }
        }
      }

      // Nếu địa điểm gần nhất trong bán kính 15km
      if (nearestPlace != null && minDistance < 15.0) {
        return CheckInLocationInfo(
          latitude: pos.latitude,
          longitude: pos.longitude,
          placeId: nearestPlace.id,
          placeName: nearestPlace.name,
          formattedLabel: '📍 ${nearestPlace.name} · Đà Lạt',
        );
      }

      return CheckInLocationInfo(
        latitude: pos.latitude,
        longitude: pos.longitude,
        placeName: 'Hồ Xuân Hương, Đà Lạt',
        formattedLabel: '📍 Hồ Xuân Hương · Đà Lạt',
      );
    } catch (e) {
      debugPrint('Lỗi checkin location: $e');
      return const CheckInLocationInfo(
        placeName: 'Đà Lạt',
        formattedLabel: '📍 Đà Lạt',
      );
    }
  }
}
