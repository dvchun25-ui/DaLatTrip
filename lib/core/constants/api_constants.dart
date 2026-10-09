import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return kIsWeb
        ? 'http://localhost:8000/api/v1'
        : 'http://10.0.2.2:8000/api/v1';
  }

  static const String parseTripRequest = '/ai/parse-trip-request';
  static const String parseItineraryCommand = '/ai/parse-itinerary-command';
  static const String mapRoute = '/maps/route';

  static String placePhoto(String placeId) {
    return '/places/${Uri.encodeComponent(placeId)}/photo';
  }
}
