import 'dart:convert';

import 'package:dalattrip/core/network/api_client.dart';
import 'package:dalattrip/data/repositories/mapbox_route_repository_impl.dart';
import 'package:dalattrip/domain/entities/map_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses Mapbox route returned by FastAPI', () async {
    late http.Request capturedRequest;
    final repository = MapboxRouteRepositoryImpl(
      apiClient: ApiClient(
        baseUrl: 'http://test/api/v1',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'coordinates': [
                {'latitude': 11.94, 'longitude': 108.44},
                {'latitude': 11.95, 'longitude': 108.45},
              ],
              'distanceKm': 3.25,
              'durationMinutes': 14,
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.getRoute(
      coordinates: const [
        MapCoordinate(latitude: 11.94, longitude: 108.44),
        MapCoordinate(latitude: 11.95, longitude: 108.45),
      ],
      transport: 'motorbike',
    );

    expect(capturedRequest.url.path, '/api/v1/maps/route');
    expect(jsonDecode(capturedRequest.body)['profile'], 'driving');
    expect(result.distanceKm, 3.25);
    expect(result.durationMinutes, 14);
    expect(result.coordinates, hasLength(2));
    expect(result.estimated, isFalse);
  });

  test('does not call backend when fewer than two coordinates exist', () async {
    var calls = 0;
    final repository = MapboxRouteRepositoryImpl(
      apiClient: ApiClient(
        baseUrl: 'http://test/api/v1',
        httpClient: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      ),
    );

    final result = await repository.getRoute(
      coordinates: const [MapCoordinate(latitude: 11.94, longitude: 108.44)],
      transport: 'walking',
    );

    expect(calls, 0);
    expect(result.estimated, isTrue);
  });
}
