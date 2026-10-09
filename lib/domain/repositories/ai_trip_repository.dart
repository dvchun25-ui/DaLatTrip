import '../entities/ai_trip_parse_result.dart';

abstract class AiTripRepository {
  Future<AiTripParseResult> parseTripRequest({
    required String message,
    Map<String, dynamic>? previousData,
  });
}
