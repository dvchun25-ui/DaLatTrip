import 'package:dalattrip/core/constants/place_categories.dart';
import 'package:dalattrip/data/datasources/local_place_data_source.dart';
import 'package:dalattrip/domain/builders/itinerary_builder.dart';
import 'package:dalattrip/domain/engines/recommendation_engine.dart';
import 'package:dalattrip/domain/entities/itinerary_item.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/domain/entities/scored_place.dart';
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

  group('ItineraryBuilder with real dataset', () {
    late List<ScoredPlace> recommendations;

    setUpAll(() async {
      final places = await LocalPlaceDataSource().getAllPlaces();
      recommendations = RecommendationEngine().recommend(
        request: request,
        places: places,
      );
    });

    test('creates the requested days without duplicate places', () {
      final result = ItineraryBuilder().build(
        request: request,
        scoredPlaces: recommendations,
      );
      final placeIds = result.days
          .expand((day) => day.placeItems)
          .map((item) => item.place!.id)
          .toList();

      expect(result.days, hasLength(request.days));
      expect(placeIds.toSet(), hasLength(placeIds.length));
      expect(result.totalCost, greaterThan(0));
      expect(result.totalDistance, greaterThanOrEqualTo(0));
    });

    test('obeys balanced pace and inserts travel, meals and rest', () {
      final result = ItineraryBuilder().build(
        request: request,
        scoredPlaces: recommendations,
      );

      for (final day in result.days) {
        expect(day.placeItems.length, inInclusiveRange(3, 4));
        expect(
          day.items.any((item) => item.type == ItineraryItemType.travel),
          isTrue,
        );
        expect(
          day.items.any((item) => item.type == ItineraryItemType.meal),
          isTrue,
        );
        expect(
          day.items.any((item) => item.type == ItineraryItemType.rest),
          isTrue,
        );
      }
    });

    test('has no overlapping slots and never visits after closing time', () {
      final result = ItineraryBuilder().build(
        request: request,
        scoredPlaces: recommendations,
      );

      for (final day in result.days) {
        for (var index = 1; index < day.items.length; index++) {
          expect(
            day.items[index - 1].endMinute,
            lessThanOrEqualTo(day.items[index].startMinute),
          );
        }
        for (final item in day.placeItems) {
          final close = _parseClock(item.place!.closeTime);
          if (close != null) {
            expect(item.endMinute, lessThanOrEqualTo(close));
          }
        }
      }
    });
  });

  test('clusters nearby coordinate groups into the same day', () {
    final places = <Place>[
      _place('a1', 11.9400, 108.4400),
      _place('b1', 11.8000, 108.3000),
      _place('a2', 11.9410, 108.4410),
      _place('b2', 11.8010, 108.3010),
      _place('a3', 11.9420, 108.4420),
      _place('b3', 11.8020, 108.3020),
    ];
    final scored = List.generate(
      places.length,
      (index) => _scored(places[index], 1 - index * 0.01),
    );
    const clusteringRequest = TripRequest(
      days: 2,
      people: 1,
      totalBudget: 2000000,
      interests: [PlaceCategories.nature],
      transport: 'motorbike',
      pace: 'relaxed',
    );

    final result = ItineraryBuilder().build(
      request: clusteringRequest,
      scoredPlaces: scored,
    );
    final firstDayIds = result.days.first.placeItems
        .map((item) => item.place!.id.substring(0, 1))
        .toSet();
    final secondDayIds = result.days.last.placeItems
        .map((item) => item.place!.id.substring(0, 1))
        .toSet();

    expect(firstDayIds, {'a'});
    expect(secondDayIds, {'b'});
  });

  test('skips a place that cannot be visited before closing', () {
    const earlyClosing = Place(
      id: 'closed',
      name: 'Đóng cửa sớm',
      categories: [PlaceCategories.nature],
      priceMin: 0,
      priceMax: 0,
      visitDurationMinutes: 120,
      openTime: '08:00',
      closeTime: '08:30',
      indoor: false,
    );
    const validRequest = TripRequest(
      days: 2,
      people: 1,
      totalBudget: 1000000,
      interests: [PlaceCategories.nature],
      transport: 'walking',
      pace: 'relaxed',
    );

    final result = ItineraryBuilder().build(
      request: validRequest,
      scoredPlaces: [_scored(earlyClosing, 1)],
    );

    expect(result.days.expand((day) => day.placeItems), isEmpty);
    expect(
      result.warnings.any((warning) => warning.contains('đóng cửa')),
      isTrue,
    );
  });

  test('waits until the place opens before starting the visit', () {
    const opensLate = Place(
      id: 'opens_late',
      name: 'Mở cửa muộn',
      categories: [PlaceCategories.nature],
      priceMin: 0,
      priceMax: 0,
      visitDurationMinutes: 60,
      openTime: '10:00',
      closeTime: '18:00',
      indoor: false,
    );
    const validRequest = TripRequest(
      days: 2,
      people: 1,
      totalBudget: 1000000,
      interests: [PlaceCategories.nature],
      transport: 'walking',
      pace: 'relaxed',
    );

    final result = ItineraryBuilder().build(
      request: validRequest,
      scoredPlaces: [_scored(opensLate, 1)],
    );
    final visit = result.days.first.placeItems.single;

    expect(visit.startMinute, greaterThanOrEqualTo(10 * 60));
    expect(
      result.days.first.items.any(
        (item) =>
            item.type == ItineraryItemType.rest &&
            item.title.contains('chờ mở cửa'),
      ),
      isTrue,
    );
  });

  for (final paceExpectation in const [
    ('relaxed', 2, 3),
    ('balanced', 3, 4),
    ('packed', 4, 5),
  ]) {
    test('${paceExpectation.$1} pace stays in its daily place range', () {
      final places = List.generate(
        10,
        (index) => _place(
          'place_$index',
          11.94 + index * 0.0001,
          108.44 + index * 0.0001,
        ),
      );
      final scored = List.generate(
        places.length,
        (index) => _scored(places[index], 1 - index * 0.01),
      );
      final paceRequest = TripRequest(
        days: 2,
        people: 1,
        totalBudget: 3000000,
        interests: const [PlaceCategories.nature],
        transport: 'motorbike',
        pace: paceExpectation.$1,
      );

      final result = ItineraryBuilder().build(
        request: paceRequest,
        scoredPlaces: scored,
      );

      for (final day in result.days) {
        expect(
          day.placeItems.length,
          inInclusiveRange(paceExpectation.$2, paceExpectation.$3),
        );
      }
    });
  }
}

Place _place(String id, double latitude, double longitude) {
  return Place(
    id: id,
    name: id,
    categories: const [PlaceCategories.nature],
    priceMin: 0,
    priceMax: 100000,
    visitDurationMinutes: 60,
    openTime: '08:00',
    closeTime: '18:00',
    latitude: latitude,
    longitude: longitude,
    indoor: false,
  );
}

ScoredPlace _scored(Place place, double score) {
  return ScoredPlace(
    place: place,
    totalScore: score,
    interestScore: 1,
    budgetScore: 1,
    ratingScore: 0.8,
    distanceScore: 0.5,
    diversityScore: 1,
    reasons: const ['Phù hợp sở thích'],
  );
}

int? _parseClock(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}
