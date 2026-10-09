class MapCoordinate {
  final double latitude;
  final double longitude;

  const MapCoordinate({required this.latitude, required this.longitude});
}

class MapRoute {
  final List<MapCoordinate> coordinates;
  final double distanceKm;
  final int durationMinutes;
  final bool estimated;

  const MapRoute({
    required this.coordinates,
    required this.distanceKm,
    required this.durationMinutes,
    this.estimated = false,
  });
}
