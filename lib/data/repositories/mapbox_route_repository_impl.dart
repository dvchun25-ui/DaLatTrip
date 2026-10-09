import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/map_route.dart';
import '../../domain/repositories/map_route_repository.dart';

class MapboxRouteRepositoryImpl implements MapRouteRepository {
  static const _mapboxToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');
  final ApiClient _apiClient;

  MapboxRouteRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<MapRoute> getRoute({
    required List<MapCoordinate> coordinates,
    required String transport,
  }) async {
    if (coordinates.length < 2) {
      return MapRoute(
        coordinates: coordinates,
        distanceKm: 0,
        durationMinutes: 0,
        estimated: true,
      );
    }

    // 1. Thử gọi trực tiếp Mapbox Directions API nếu có Mapbox Public Token
    if (_mapboxToken.isNotEmpty) {
      try {
        final mapboxRoute = await _fetchFromMapboxApi(coordinates, transport);
        if (mapboxRoute != null) {
          return mapboxRoute;
        }
      } catch (e) {
        debugPrint('Lỗi gọi Mapbox Directions API trực tiếp: $e');
      }
    }

    // 2. Thử gọi qua Backend API server nếu có
    try {
      final response = await _apiClient.post(
        ApiConstants.mapRoute,
        body: {
          'coordinates': coordinates
              .map(
                (coordinate) => {
                  'latitude': coordinate.latitude,
                  'longitude': coordinate.longitude,
                },
              )
              .toList(growable: false),
          'profile': _profileFor(transport),
        },
      );
      final routeCoordinates = (response['coordinates'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (coordinate) => MapCoordinate(
              latitude: (coordinate['latitude'] as num).toDouble(),
              longitude: (coordinate['longitude'] as num).toDouble(),
            ),
          )
          .toList(growable: false);

      if (routeCoordinates.isNotEmpty) {
        return MapRoute(
          coordinates: routeCoordinates,
          distanceKm: (response['distanceKm'] as num).toDouble(),
          durationMinutes: (response['durationMinutes'] as num).round(),
        );
      }
    } catch (e) {
      debugPrint('Lỗi kết nối Backend API route: $e');
    }

    // 3. Fallback: Nối tọa độ các điểm dừng
    return MapRoute(
      coordinates: coordinates,
      distanceKm: _calculateStraightDistance(coordinates),
      durationMinutes: (coordinates.length - 1) * 15,
      estimated: true,
    );
  }

  Future<MapRoute?> _fetchFromMapboxApi(
    List<MapCoordinate> coordinates,
    String transport,
  ) async {
    final profile = _profileFor(transport);
    final coordsString = coordinates
        .map((c) => '${c.longitude.toStringAsFixed(6)},${c.latitude.toStringAsFixed(6)}')
        .join(';');

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$profile/$coordsString?geometries=geojson&overview=full&access_token=$_mapboxToken',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes != null && routes.isNotEmpty) {
        final firstRoute = routes.first as Map<String, dynamic>;
        final distanceMeters = (firstRoute['distance'] as num).toDouble();
        final durationSeconds = (firstRoute['duration'] as num).toDouble();
        final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
        final rawCoords = geometry?['coordinates'] as List<dynamic>? ?? [];

        final routeCoords = rawCoords.map((point) {
          final list = point as List<dynamic>;
          return MapCoordinate(
            longitude: (list[0] as num).toDouble(),
            latitude: (list[1] as num).toDouble(),
          );
        }).toList();

        return MapRoute(
          coordinates: routeCoords,
          distanceKm: distanceMeters / 1000.0,
          durationMinutes: (durationSeconds / 60.0).round(),
          estimated: false,
        );
      }
    }
    return null;
  }

  double _calculateStraightDistance(List<MapCoordinate> coords) {
    double total = 0;
    for (int i = 0; i < coords.length - 1; i++) {
      final lat1 = coords[i].latitude;
      final lon1 = coords[i].longitude;
      final lat2 = coords[i + 1].latitude;
      final lon2 = coords[i + 1].longitude;
      total += _haversine(lat1, lon1, lat2, lon2);
    }
    return total;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (dLat / 2) * (dLat / 2) +
        _degToRad(lat1) * _degToRad(lat2) * (dLon / 2) * (dLon / 2);
    return r * 2 * (a < 1 ? a : 1);
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  String _profileFor(String transport) {
    return switch (transport.toLowerCase()) {
      'walking' || 'đi bộ' => 'walking',
      'cycling' || 'xe đạp' => 'cycling',
      _ => 'driving',
    };
  }
}
