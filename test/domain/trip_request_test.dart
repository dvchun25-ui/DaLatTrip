import 'package:dalattrip/core/constants/place_categories.dart';
import 'package:dalattrip/features/plan/controllers/create_trip_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateTripController', () {
    test('maps valid form state to TripRequest', () {
      final controller = CreateTripController()
        ..setDays(3)
        ..setPeople(2)
        ..setTotalBudget(5000000)
        ..setTransport('motorbike')
        ..setPace('balanced')
        ..setInterests([PlaceCategories.nature, PlaceCategories.cafe]);

      final request = controller.createTripRequest();

      expect(request.isValid, isTrue);
      expect(request.days, 3);
      expect(request.people, 2);
      expect(request.totalBudget, 5000000);
      expect(request.interests, [PlaceCategories.nature, PlaceCategories.cafe]);
      expect(request.transport, 'motorbike');
      expect(request.pace, 'balanced');
    });

    test('rejects invalid days, people, budget and empty interests', () {
      final controller = CreateTripController()
        ..setDays(1)
        ..setPeople(0)
        ..setTotalBudget(0);

      expect(controller.validateTripDetails(), isNotNull);
      expect(() => controller.createTripRequest(), throwsStateError);
    });
  });
}
