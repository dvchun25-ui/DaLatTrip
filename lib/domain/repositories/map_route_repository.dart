import '../entities/map_route.dart';

abstract class MapRouteRepository {
  Future<MapRoute> getRoute({
    required List<MapCoordinate> coordinates,
    required String transport,
  });
}
