import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../data/datasources/local_place_data_source.dart';
import '../../../data/repositories/ai_trip_repository_impl.dart';
import '../../../data/repositories/place_repository_impl.dart';
import '../../../domain/builders/itinerary_builder.dart';
import '../../../domain/engines/budget_engine.dart';
import '../../../domain/engines/recommendation_engine.dart';
import '../../../domain/entities/ai_trip_parse_result.dart';
import '../../../domain/entities/budget_assessment.dart';
import '../../../domain/entities/clarification_question.dart';
import '../../../domain/entities/generated_itinerary.dart';
import '../../../domain/entities/trip_request.dart';
import '../../../domain/repositories/ai_trip_repository.dart';
import '../../../domain/repositories/place_repository.dart';
import '../../../domain/services/clarification_service.dart';

enum TripPlanningState {
  initial,
  parsing,
  askingQuestions,
  generating,
  success,
  error,
}

enum TripPlanningMessageRole { user, assistant }

class TripPlanningMessage {
  final TripPlanningMessageRole role;
  final String text;

  const TripPlanningMessage({required this.role, required this.text});
}

class TripPlanningController extends ChangeNotifier {
  final AiTripRepository _aiTripRepository;
  final PlaceRepository _placeRepository;
  final RecommendationEngine _recommendationEngine;
  final ItineraryBuilder _itineraryBuilder;
  final BudgetEngine _budgetEngine;
  final ClarificationService _clarificationService;

  TripPlanningController({
    AiTripRepository? aiTripRepository,
    PlaceRepository? placeRepository,
    RecommendationEngine? recommendationEngine,
    ItineraryBuilder? itineraryBuilder,
    BudgetEngine? budgetEngine,
    ClarificationService? clarificationService,
  }) : _aiTripRepository =
           aiTripRepository ?? AiTripRepositoryImpl(apiClient: ApiClient()),
       _placeRepository =
           placeRepository ??
           PlaceRepositoryImpl(localDataSource: LocalPlaceDataSource()),
       _recommendationEngine = recommendationEngine ?? RecommendationEngine(),
       _itineraryBuilder = itineraryBuilder ?? ItineraryBuilder(),
       _budgetEngine = budgetEngine ?? BudgetEngine(),
       _clarificationService = clarificationService ?? ClarificationService();

  TripPlanningState state = TripPlanningState.initial;
  String? errorMessage;
  AiTripParseResult? parseResult;
  TripRequest? tripRequest;
  GeneratedItinerary? itinerary;
  BudgetAssessment? budgetAssessment;
  List<ClarificationQuestion> questions = const [];
  Map<String, dynamic> _collectedData = const {};

  final List<TripPlanningMessage> messages = [
    const TripPlanningMessage(
      role: TripPlanningMessageRole.assistant,
      text:
          'Hãy mô tả chuyến đi Đà Lạt bạn mong muốn. Mình sẽ hỏi thêm tối đa 3 câu mỗi lượt.',
    ),
  ];

  bool get isBusy =>
      state == TripPlanningState.parsing ||
      state == TripPlanningState.generating;

  Future<void> submitMessage(String value) async {
    final message = value.trim();
    if (message.isEmpty || isBusy) return;

    messages.add(
      TripPlanningMessage(role: TripPlanningMessageRole.user, text: message),
    );
    state = TripPlanningState.parsing;
    errorMessage = null;
    questions = const [];
    notifyListeners();

    try {
      final parsed = await _aiTripRepository.parseTripRequest(
        message: message,
        previousData: _collectedData.isEmpty ? null : _collectedData,
      );
      parseResult = parsed;
      _collectedData = Map<String, dynamic>.unmodifiable(parsed.collectedData);
      if (parsed.status == AiTripParseStatus.needsMoreInfo ||
          parsed.tripRequest == null) {
        _askQuestions(parsed);
        return;
      }

      tripRequest = parsed.tripRequest;
      messages.add(
        const TripPlanningMessage(
          role: TripPlanningMessageRole.assistant,
          text: 'Đã đủ thông tin. Mình đang tối ưu lịch trình cho bạn…',
        ),
      );
      await _generateItinerary(parsed.tripRequest!);
    } catch (error) {
      _setError('Không thể hoàn thành kế hoạch: $error');
    }
  }

  Future<void> answerQuickOption(ClarificationOption option) {
    return submitMessage(option.answer);
  }

  void _askQuestions(AiTripParseResult parsed) {
    questions = _clarificationService.buildQuestions(
      missingFields: parsed.missingFields,
      collectedData: parsed.collectedData,
    );
    state = TripPlanningState.askingQuestions;
    messages.add(
      TripPlanningMessage(
        role: TripPlanningMessageRole.assistant,
        text: parsed.message ?? 'Mình cần thêm một vài thông tin.',
      ),
    );
    notifyListeners();
  }

  Future<void> _generateItinerary(TripRequest request) async {
    state = TripPlanningState.generating;
    notifyListeners();
    final places = await _placeRepository.getAllPlaces();
    final recommendations = _recommendationEngine.recommend(
      request: request,
      places: places,
      limit: 75,
    );
    var generated = _itineraryBuilder.build(
      request: request,
      scoredPlaces: recommendations,
    );
    if (generated.days.length != request.days) {
      throw StateError('Không thể tạo đủ ${request.days} ngày.');
    }

    final assessment = _budgetEngine.evaluate(
      request: request,
      itinerary: generated,
    );
    if (assessment.warnings.isNotEmpty) {
      generated = GeneratedItinerary(
        days: generated.days,
        totalCost: generated.totalCost,
        totalDistance: generated.totalDistance,
        warnings: List.unmodifiable([
          ...generated.warnings,
          ...assessment.warnings,
        ]),
      );
    }
    itinerary = generated;
    budgetAssessment = assessment;
    state = TripPlanningState.success;
    messages.add(
      const TripPlanningMessage(
        role: TripPlanningMessageRole.assistant,
        text: 'Lịch trình đã sẵn sàng.',
      ),
    );
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    state = TripPlanningState.error;
    messages.add(
      TripPlanningMessage(
        role: TripPlanningMessageRole.assistant,
        text: message,
      ),
    );
    notifyListeners();
  }

  void reset() {
    state = TripPlanningState.initial;
    errorMessage = null;
    parseResult = null;
    tripRequest = null;
    itinerary = null;
    budgetAssessment = null;
    questions = const [];
    _collectedData = const {};
    messages
      ..clear()
      ..add(
        const TripPlanningMessage(
          role: TripPlanningMessageRole.assistant,
          text: 'Bạn muốn chuyến đi Đà Lạt như thế nào?',
        ),
      );
    notifyListeners();
  }
}
