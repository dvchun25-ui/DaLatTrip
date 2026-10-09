import 'package:dalattrip/domain/entities/ai_trip_parse_result.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/domain/entities/trip_request.dart';
import 'package:dalattrip/domain/repositories/ai_trip_repository.dart';
import 'package:dalattrip/domain/repositories/place_repository.dart';
import 'package:dalattrip/features/trip/controllers/trip_planning_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiTripRepository implements AiTripRepository {
  int callCount = 0;
  Map<String, dynamic>? lastPreviousData;

  @override
  Future<AiTripParseResult> parseTripRequest({
    required String message,
    Map<String, dynamic>? previousData,
  }) async {
    callCount++;
    lastPreviousData = previousData;

    if (callCount == 1) {
      return const AiTripParseResult(
        status: AiTripParseStatus.needsMoreInfo,
        message: 'Mình cần thêm một số thông tin để lên lịch trình chính xác.',
        missingFields: ['totalBudget', 'transport', 'pace'],
        collectedData: {
          'days': 3,
          'people': 2,
          'interests': ['nature', 'cafe'],
        },
      );
    }

    return const AiTripParseResult(
      status: AiTripParseStatus.ready,
      message: 'Đã đủ thông tin!',
      tripRequest: TripRequest(
        days: 3,
        people: 2,
        totalBudget: 5000000,
        interests: ['nature', 'cafe'],
        transport: 'motorbike',
        pace: 'relaxed',
      ),
      collectedData: {
        'days': 3,
        'people': 2,
        'totalBudget': 5000000,
        'interests': ['nature', 'cafe'],
        'transport': 'motorbike',
        'pace': 'relaxed',
      },
    );
  }
}

class _FakePlaceRepository implements PlaceRepository {
  @override
  Future<List<Place>> getAllPlaces() async {
    return List.generate(
      30,
      (i) => Place(
        id: 'place_$i',
        name: 'Địa điểm $i',
        categories: [i % 2 == 0 ? 'nature' : 'cafe'],
        rating: 4.5,
        visitDurationMinutes: 90,
        priceMin: 20000,
        priceMax: 50000,
        latitude: 11.9404 + (i * 0.005),
        longitude: 108.4380 + (i * 0.005),
        description: 'Mô tả $i',
        indoor: false,
      ),
    );
  }

  @override
  Future<List<Place>> getPlacesByCategory(String category) async => [];

  Future<List<Place>> getPlacesByCategories(List<String> categories) async =>
      [];

  @override
  Future<Place?> getPlaceById(String id) async => null;

  Future<List<Place>> searchPlaces(String query) async => [];
}

void main() {
  group('TripPlanningController (TASK 10)', () {
    late _FakeAiTripRepository aiRepository;
    late _FakePlaceRepository placeRepository;
    late TripPlanningController controller;

    setUp(() {
      aiRepository = _FakeAiTripRepository();
      placeRepository = _FakePlaceRepository();
      controller = TripPlanningController(
        aiTripRepository: aiRepository,
        placeRepository: placeRepository,
      );
    });

    test('starts with initial state', () {
      expect(controller.state, TripPlanningState.initial);
      expect(controller.messages.length, 1);
      expect(controller.tripRequest, isNull);
      expect(controller.itinerary, isNull);
    });

    test(
      'full flow: text input -> parse -> ask missing -> complete -> generate itinerary & budget',
      () async {
        final states = <TripPlanningState>[];
        controller.addListener(() {
          states.add(controller.state);
        });

        // Step 1: User enters incomplete text
        await controller.submitMessage(
          'Đi Đà Lạt 3 ngày 2 người thích cafe và thiên nhiên',
        );

        expect(controller.state, TripPlanningState.askingQuestions);
        expect(controller.questions.length, 3);
        expect(controller.questions.map((q) => q.field).toList(), [
          'totalBudget',
          'transport',
          'pace',
        ]);

        // Step 2: User answers via quick option or text
        await controller.submitMessage(
          '5 triệu, đi xe máy, lịch trình thư giãn',
        );

        expect(aiRepository.lastPreviousData?['days'], 3);
        expect(aiRepository.lastPreviousData?['people'], 2);

        expect(controller.state, TripPlanningState.success);
        expect(controller.tripRequest, isNotNull);
        expect(controller.tripRequest!.isValid, isTrue);
        expect(controller.itinerary, isNotNull);
        expect(controller.itinerary!.days.length, 3);
        expect(controller.budgetAssessment, isNotNull);

        // Verify states transition sequence
        expect(states, contains(TripPlanningState.parsing));
        expect(states, contains(TripPlanningState.askingQuestions));
        expect(states, contains(TripPlanningState.generating));
        expect(states, contains(TripPlanningState.success));
      },
    );

    test('handles error state properly', () async {
      final throwingAiRepo = _ThrowingAiTripRepository();
      final errorController = TripPlanningController(
        aiTripRepository: throwingAiRepo,
        placeRepository: placeRepository,
      );

      await errorController.submitMessage('Đi chơi 3 ngày');
      expect(errorController.state, TripPlanningState.error);
      expect(errorController.errorMessage, isNotNull);
    });

    test('reset clears state and messages', () async {
      await controller.submitMessage('Đi 3 ngày');
      controller.reset();

      expect(controller.state, TripPlanningState.initial);
      expect(controller.tripRequest, isNull);
      expect(controller.itinerary, isNull);
      expect(controller.questions, isEmpty);
    });
  });
}

class _ThrowingAiTripRepository implements AiTripRepository {
  @override
  Future<AiTripParseResult> parseTripRequest({
    required String message,
    Map<String, dynamic>? previousData,
  }) async {
    throw Exception('API Server error');
  }
}
