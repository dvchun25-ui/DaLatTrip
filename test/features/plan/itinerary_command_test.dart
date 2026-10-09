import 'package:dalattrip/domain/entities/itinerary_command.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/domain/entities/trip_request.dart';
import 'package:dalattrip/domain/repositories/itinerary_command_repository.dart';
import 'package:dalattrip/domain/repositories/place_repository.dart';
import 'package:dalattrip/features/plan/controllers/itinerary_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCommandRepository implements ItineraryCommandRepository {
  ItineraryCommand next;
  String? selectedPlaceId;
  int? selectedDay;

  _FakeCommandRepository(this.next);

  @override
  Future<ItineraryCommand> parseCommand({
    required String message,
    String? selectedPlaceId,
    int? selectedDay,
    required List<ItineraryCommandPlaceContext> places,
  }) async {
    this.selectedPlaceId = selectedPlaceId;
    this.selectedDay = selectedDay;
    return next;
  }
}

class _FakePlaceRepository implements PlaceRepository {
  final List<Place> places = List.generate(
    30,
    (index) => Place(
      id: 'place_$index',
      name: 'Điểm $index',
      categories: [index.isEven ? 'nature' : 'cafe'],
      priceMin: 10000,
      priceMax: 30000,
      visitDurationMinutes: 60,
      openTime: '07:00',
      closeTime: '20:00',
      latitude: 11.9 + index / 1000,
      longitude: 108.4 + index / 1000,
      rating: 5 - index / 100,
      indoor: index.isOdd,
    ),
  );

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
  Future<List<Place>> getPlacesByCategory(String category) async =>
      places.where((place) => place.categories.contains(category)).toList();
}

const _request = TripRequest(
  days: 2,
  people: 2,
  totalBudget: 5000000,
  interests: ['nature'],
  transport: 'motorbike',
  pace: 'balanced',
);

void main() {
  test('remove_place excludes the selected place and replans', () async {
    final commands = _FakeCommandRepository(
      const ItineraryCommand(
        action: ItineraryCommandAction.removePlace,
        placeId: 'place_0',
      ),
    );
    final controller = ItineraryController(
      placeRepository: _FakePlaceRepository(),
      commandRepository: commands,
    );
    await controller.generate(_request);
    expect(
      controller.itinerary!.days
          .expand((day) => day.placeItems)
          .any((item) => item.place!.id == 'place_0'),
      isTrue,
    );

    await controller.applyCommand(
      'Bỏ địa điểm này',
      selectedPlaceId: 'place_0',
      selectedDay: 1,
    );

    expect(commands.selectedPlaceId, 'place_0');
    expect(
      controller.itinerary!.days
          .expand((day) => day.placeItems)
          .any((item) => item.place!.id == 'place_0'),
      isFalse,
    );
    expect(controller.commandErrorMessage, isNull);
  });

  test('update_budget changes the request before replanning', () async {
    final commands = _FakeCommandRepository(
      const ItineraryCommand(
        action: ItineraryCommandAction.updateBudget,
        totalBudget: 4000000,
      ),
    );
    final controller = ItineraryController(
      placeRepository: _FakePlaceRepository(),
      commandRepository: commands,
    );
    await controller.generate(_request);
    await controller.applyCommand('Giảm ngân sách xuống 4 triệu');

    expect(controller.currentRequest!.totalBudget, 4000000);
    expect(controller.itinerary, isNotNull);
  });

  test('day-specific relaxed pace makes day 2 lighter', () async {
    final commands = _FakeCommandRepository(
      const ItineraryCommand(
        action: ItineraryCommandAction.adjustDayPace,
        dayNumber: 2,
        pace: 'relaxed',
      ),
    );
    final controller = ItineraryController(
      placeRepository: _FakePlaceRepository(),
      commandRepository: commands,
    );
    await controller.generate(_request);
    await controller.applyCommand('Ngày 2 đi nhẹ hơn', selectedDay: 2);

    expect(
      controller.itinerary!.days[1].placeItems.length,
      lessThanOrEqualTo(3),
    );
  });

  test('replace_outdoor keeps the selected day indoors', () async {
    final commands = _FakeCommandRepository(
      const ItineraryCommand(
        action: ItineraryCommandAction.replaceOutdoor,
        dayNumber: 2,
      ),
    );
    final controller = ItineraryController(
      placeRepository: _FakePlaceRepository(),
      commandRepository: commands,
    );
    await controller.generate(_request);
    await controller.applyCommand(
      'Đổi địa điểm ngoài trời vì trời mưa',
      selectedDay: 2,
    );

    expect(
      controller.itinerary!.days[1].placeItems.every(
        (item) => item.place!.indoor,
      ),
      isTrue,
    );
  });

  test('adjust_day_start rebuilds day 1 from 10:00', () async {
    final commands = _FakeCommandRepository(
      const ItineraryCommand(
        action: ItineraryCommandAction.adjustDayStart,
        dayNumber: 1,
        startMinute: 600,
      ),
    );
    final controller = ItineraryController(
      placeRepository: _FakePlaceRepository(),
      commandRepository: commands,
    );
    await controller.generate(_request);
    await controller.applyCommand(
      'Tôi muốn nghỉ ngơi ngày 1 bắt đầu từ 10g',
      selectedDay: 1,
    );

    final firstTravel = controller.itinerary!.days.first.items.firstWhere(
      (item) => item.title.startsWith('Di chuyển'),
    );
    expect(firstTravel.startMinute, 600);
    expect(controller.commandErrorMessage, isNull);
  });
}
