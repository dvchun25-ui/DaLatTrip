import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Explore, Detail, Favorites and Itinerary share PlaceImage', () {
    const files = [
      'lib/features/explore/screens/explore_screen.dart',
      'lib/features/explore/screens/place_detail_screen.dart',
      'lib/features/favorites/screens/favorites_screen.dart',
      'lib/features/plan/screens/itinerary_screen.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('PlaceImage('),
        reason: '$path phải sử dụng PlaceImage.',
      );
    }
  });
}
