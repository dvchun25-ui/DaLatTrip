import '../../../domain/entities/ai_trip_parse_result.dart';
import '../../../domain/repositories/ai_trip_repository.dart';
import 'trip_planning_controller.dart';

export 'trip_planning_controller.dart';

/// Compatibility wrapper for code created before TASK 10.
@Deprecated('Use TripPlanningController instead.')
class AiTripController extends TripPlanningController {
  AiTripController({AiTripRepository? repository})
    : super(aiTripRepository: repository);

  bool get isReady => tripRequest != null && tripRequest!.isValid;
  AiTripParseResult? get result => parseResult;
}
