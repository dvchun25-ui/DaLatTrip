import 'dart:math' as math;

class DistanceUtils {
  DistanceUtils._();

  static double haversineKilometers({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _toRadians(endLatitude - startLatitude);
    final longitudeDelta = _toRadians(endLongitude - startLongitude);
    final startLatitudeRadians = _toRadians(startLatitude);
    final endLatitudeRadians = _toRadians(endLatitude);

    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
