import '../../domain/entities/ai_trip_parse_result.dart';
import '../../domain/entities/trip_request.dart';

class AiTripParseResultModel extends AiTripParseResult {
  const AiTripParseResultModel({
    required super.status,
    super.tripRequest,
    super.collectedData,
    super.missingFields,
    super.questions,
    super.message,
  });

  factory AiTripParseResultModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] == 'ready'
        ? AiTripParseStatus.ready
        : AiTripParseStatus.needsMoreInfo;
    final tripJson = json['tripRequest'];
    final collectedJson = json['collectedData'];
    return AiTripParseResultModel(
      status: status,
      tripRequest: status == AiTripParseStatus.ready && tripJson is Map
          ? _tripRequestFromJson(Map<String, dynamic>.from(tripJson))
          : null,
      collectedData: collectedJson is Map
          ? Map<String, dynamic>.from(collectedJson)
          : const {},
      missingFields: _stringList(json['missingFields']),
      questions: _stringList(json['questions']),
      message: json['message']?.toString(),
    );
  }

  static TripRequest _tripRequestFromJson(Map<String, dynamic> json) {
    return TripRequest(
      days: (json['days'] as num).toInt(),
      people: (json['people'] as num).toInt(),
      totalBudget: (json['totalBudget'] as num).toInt(),
      interests: _stringList(json['interests']),
      transport: json['transport'].toString(),
      pace: json['pace'].toString(),
      startLocation: _nullableString(json['startLocation']),
      specialRequirements: _stringList(json['specialRequirements']),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return List<String>.unmodifiable(
      value.map((item) => item.toString()).where((item) => item.isNotEmpty),
    );
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
