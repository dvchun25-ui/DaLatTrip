import 'package:dalattrip/domain/entities/generated_itinerary.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/domain/entities/trip_request.dart';
import 'package:dalattrip/domain/repositories/itinerary_storage_repository.dart';
import 'package:dalattrip/domain/repositories/place_repository.dart';
import 'package:dalattrip/features/plan/controllers/itinerary_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const request = TripRequest(
    days: 2,
    people: 2,
    totalBudget: 3000000,
    interests: ['nature'],
    transport: 'motorbike',
    pace: 'relaxed',
  );

  late _FakePlaceRepository placeRepository;
  late _FakeStorageRepository storageRepository;
  late ItineraryController controller;

  setUp(() {
    placeRepository = _FakePlaceRepository(_places(24));
    storageRepository = _FakeStorageRepository();
    controller = ItineraryController(
      placeRepository: placeRepository,
      storageRepository: storageRepository,
    );
  });

  tearDown(() => controller.dispose());

  test(
    'generate creates a dynamic itinerary for every requested day',
    () async {
      await controller.generate(request);

      expect(controller.errorMessage, isNull);
      expect(controller.itinerary, isNotNull);
      expect(controller.itinerary!.days, hasLength(2));
      expect(
        controller.itinerary!.days.expand((day) => day.placeItems),
        isNotEmpty,
      );
    },
  );

  test('regenerate chooses a new set of places', () async {
    await controller.generate(request);
    final firstIds = _placeIds(controller.itinerary!);

    await controller.regenerate(request);
    final regeneratedIds = _placeIds(controller.itinerary!);

    expect(regeneratedIds, isNotEmpty);
    expect(regeneratedIds.intersection(firstIds), isEmpty);
  });

  test(
    'replacePlace excludes the selected place and rebuilds schedule',
    () async {
      await controller.generate(request);
      final replacedId = _placeIds(controller.itinerary!).first;

      await controller.replacePlace(request, replacedId);

      expect(_placeIds(controller.itinerary!), isNot(contains(replacedId)));
    },
  );

  test(
    'save delegates the current result to local storage repository',
    () async {
      await controller.generate(request);
      await controller.save(request);

      expect(storageRepository.savedRequest, same(request));
      expect(storageRepository.savedItinerary, same(controller.itinerary));
      expect(controller.isSaved, isTrue);
    },
  );
}

Set<String> _placeIds(GeneratedItinerary itinerary) => itinerary.days
    .expand((day) => day.placeItems)
    .map((item) => item.place!.id)
    .toSet();

List<Place> _places(int count) {
  return List.generate(
    count,
    (index) => Place(
      id: 'place_$index',
      name: 'Địa điểm ${index.toString().padLeft(2, '0')}',
      categories: const ['nature'],
      priceMin: 0,
      priceMax: 100000,
      visitDurationMinutes: 75,
      openTime: '07:00',
      closeTime: '19:00',
      latitude: 11.94 + index * 0.0001,
      longitude: 108.44 + index * 0.0001,
      rating: 4.5,
      indoor: false,
    ),
  );
}

class _FakePlaceRepository implements PlaceRepository {
  final List<Place> places;

  _FakePlaceRepository(this.places);

  @override
  Future<List<Place>> getAllPlaces() async => places;

  @override
  Future<Place?> getPlaceById(String id) async {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  @override
  Future<List<Place>> getPlacesByCategory(String category) async => places
      .where((place) => place.categories.contains(category))
      .toList(growable: false);
}

class _FakeStorageRepository implements ItineraryStorageRepository {
  TripRequest? savedRequest;
  GeneratedItinerary? savedItinerary;

  @override
  Future<void> save({
    required TripRequest request,
    required GeneratedItinerary itinerary,
  }) async {
    savedRequest = request;
    savedItinerary = itinerary;
  }
}
