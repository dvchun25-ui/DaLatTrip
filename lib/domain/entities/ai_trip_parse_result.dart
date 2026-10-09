import 'trip_request.dart';

enum AiTripParseStatus { needsMoreInfo, ready }

class AiTripParseResult {
  final AiTripParseStatus status;
  final TripRequest? tripRequest;
  final Map<String, dynamic> collectedData;
  final List<String> missingFields;
  final List<String> questions;
  final String? message;

  const AiTripParseResult({
    required this.status,
    this.tripRequest,
    this.collectedData = const {},
    this.missingFields = const [],
    this.questions = const [],
    this.message,
  });
}
