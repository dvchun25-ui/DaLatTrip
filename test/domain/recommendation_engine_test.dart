import 'package:dalattrip/core/constants/place_categories.dart';
import 'package:dalattrip/data/datasources/local_place_data_source.dart';
import 'package:dalattrip/domain/engines/recommendation_engine.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/domain/entities/trip_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const request = TripRequest(
    days: 3,
    people: 2,
    totalBudget: 5000000,
    interests: [PlaceCategories.nature, PlaceCategories.cafe],
    transport: 'motorbike',
    pace: 'balanced',
  );

  group('RecommendationEngine', () {
    late List<Place> places;
    late RecommendationEngine engine;

    setUpAll(() async {
      places = await LocalPlaceDataSource().getAllPlaces();
    });

    setUp(() {
      engine = RecommendationEngine();
    });

    test('returns 25 scored places for the POC request', () {
      final result = engine.recommend(request: request, places: places);

      expect(result, hasLength(25));
    });

    test('scores are within 0-1 and sorted descending', () {
      final result = engine.recommend(request: request, places: places);

      for (final item in result) {
        expect(item.totalScore, inInclusiveRange(0.0, 1.0));
        expect(item.interestScore, inInclusiveRange(0.0, 1.0));
        expect(item.budgetScore, inInclusiveRange(0.0, 1.0));
        expect(item.ratingScore, inInclusiveRange(0.0, 1.0));
        expect(item.distanceScore, inInclusiveRange(0.0, 1.0));
        expect(item.diversityScore, inInclusiveRange(0.0, 1.0));
      }
      for (var index = 1; index < result.length; index++) {
        expect(
          result[index - 1].totalScore,
          greaterThanOrEqualTo(result[index].totalScore),
        );
      }
    });

    test('applies diversity and generates data-driven reasons', () {
      final result = engine.recommend(request: request, places: places);
      final diversityScores = result.map((item) => item.diversityScore).toSet();
      final selectedCategories = result
          .expand((item) => item.place.categories)
          .toSet();

      expect(diversityScores.length, greaterThan(1));
      expect(selectedCategories.length, greaterThan(1));
      expect(result.every((item) => item.reasons.isNotEmpty), isTrue);
    });

    test('does not crash when optional place data is null or empty', () {
      const nullablePlace = Place(
        id: 'nullable_place',
        name: 'Địa điểm thiếu dữ liệu',
        categories: [PlaceCategories.nature],
        priceMin: 0,
        priceMax: 100000,
        visitDurationMinutes: 90,
        indoor: false,
      );

      final result = engine.recommend(
        request: request,
        places: const [nullablePlace],
      );

      expect(result, hasLength(1));
      expect(result.first.ratingScore, 0.6);
      expect(result.first.distanceScore, 0.5);
    });

    test('filters structurally invalid places', () {
      const invalid = Place(
        id: '',
        name: '',
        categories: [],
        priceMin: 0,
        priceMax: 0,
        visitDurationMinutes: 0,
        indoor: false,
      );

      final result = engine.recommend(
        request: request,
        places: const [invalid],
      );

      expect(result, isEmpty);
    });
  });
}
