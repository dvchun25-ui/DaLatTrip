import 'dart:io';

import 'package:dalattrip/core/constants/place_categories.dart';
import 'package:dalattrip/data/datasources/local_place_data_source.dart';
import 'package:dalattrip/data/models/place_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalPlaceDataSource', () {
    late LocalPlaceDataSource dataSource;

    setUp(() {
      dataSource = LocalPlaceDataSource();
    });

    test('getAllPlaces returns and caches exactly 200 places', () async {
      final firstLoad = await dataSource.getAllPlaces();
      final secondLoad = await dataSource.getAllPlaces();

      expect(firstLoad, hasLength(200));
      expect(identical(firstLoad, secondLoad), isTrue);
    });

    test('getPlaceById returns the expected place', () async {
      final place = await dataSource.getPlaceById('lac_tien_gioi');

      expect(place, isNotNull);
      expect(place!.name, 'Lạc Tiên Giới');
    });

    test('getPlacesByCategory returns normalized nature places', () async {
      final places = await dataSource.getPlacesByCategory(
        PlaceCategories.nature,
      );

      expect(places, isNotEmpty);
      expect(
        places.every(
          (place) => place.categories.contains(PlaceCategories.nature),
        ),
        isTrue,
      );
    });

    test('PlaceModel safely parses nullable fields and categories', () {
      final place = PlaceModel.fromJson({
        'id': 'nullable_place',
        'name': 'Địa điểm thiếu dữ liệu',
        'address': '',
        'categories': 'thiên nhiên;check-in',
        'description': null,
        'price_min': 0,
        'price_max': 100000,
        'visit_duration_minutes': 90,
        'open_time': '07:00',
        'close_time': '17:00',
        'latitude': null,
        'longitude': null,
        'rating': null,
        'indoor': false,
        'image_url': '',
        'source_url': '',
      });

      expect(place.address, isNull);
      expect(place.latitude, isNull);
      expect(place.longitude, isNull);
      expect(place.rating, isNull);
      expect(place.imageUrl, isNull);
      expect(place.categories, [
        PlaceCategories.nature,
        PlaceCategories.checkin,
      ]);
    });

    test('Explore feature no longer references samplePlaces', () async {
      final source = await File(
        'lib/features/explore/screens/explore_screen.dart',
      ).readAsString();

      expect(source, isNot(contains('TravelData.samplePlaces')));
    });
  });
}
