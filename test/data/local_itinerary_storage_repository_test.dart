import 'dart:convert';

import 'package:dalattrip/data/repositories/local_itinerary_storage_repository.dart';
import 'package:dalattrip/domain/entities/generated_itinerary.dart';
import 'package:dalattrip/domain/entities/itinerary_day.dart';
import 'package:dalattrip/domain/entities/itinerary_item.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/domain/entities/trip_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves compact itinerary JSON using place IDs', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalItineraryStorageRepository();

    await repository.save(request: _request, itinerary: _itinerary);

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(
      LocalItineraryStorageRepository.storageKey,
    );
    final decoded = jsonDecode(raw!) as List<dynamic>;
    final saved = decoded.single as Map<String, dynamic>;
    final itinerary = saved['itinerary'] as Map<String, dynamic>;
    final days = itinerary['days'] as List<dynamic>;
    final day = days.single as Map<String, dynamic>;
    final items = day['items'] as List<dynamic>;
    final placeItem = items.first as Map<String, dynamic>;

    expect(saved['request']['days'], 2);
    expect(itinerary['totalCost'], 100000);
    expect(placeItem['placeId'], 'tuyen_lam');
    expect(placeItem, isNot(contains('place')));
    expect(placeItem, isNot(contains('imageUrl')));
  });
}

const _request = TripRequest(
  days: 2,
  people: 2,
  totalBudget: 3000000,
  interests: ['nature'],
  transport: 'motorbike',
  pace: 'relaxed',
);

const _place = Place(
  id: 'tuyen_lam',
  name: 'Hồ Tuyền Lâm',
  categories: ['nature'],
  priceMin: 0,
  priceMax: 100000,
  visitDurationMinutes: 120,
  indoor: false,
  imageUrl: 'https://example.com/image.jpg',
);

const _itinerary = GeneratedItinerary(
  totalCost: 100000,
  totalDistance: 4.2,
  warnings: ['Cần kiểm tra giờ mở cửa'],
  days: [
    ItineraryDay(
      dayNumber: 1,
      totalCost: 100000,
      totalDistance: 4.2,
      items: [
        ItineraryItem(
          type: ItineraryItemType.place,
          title: 'Hồ Tuyền Lâm',
          startMinute: 480,
          endMinute: 600,
          place: _place,
          estimatedCost: 100000,
          note: 'Phù hợp thiên nhiên',
        ),
      ],
    ),
  ],
);
