import 'package:dalattrip/domain/entities/itinerary_day.dart';
import 'package:dalattrip/domain/entities/itinerary_item.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/features/plan/widgets/itinerary_command_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _place = Place(
  id: 'q_coffee',
  name: 'Q Coffee',
  categories: ['cafe'],
  priceMin: 0,
  priceMax: 100000,
  visitDurationMinutes: 60,
  indoor: true,
);

const _day = ItineraryDay(
  dayNumber: 1,
  items: [
    ItineraryItem(
      type: ItineraryItemType.place,
      title: 'Q Coffee',
      startMinute: 480,
      endMinute: 540,
      place: _place,
    ),
  ],
  totalCost: 0,
  totalDistance: 0,
);

void main() {
  testWidgets('place is optional and only selected after user taps it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ItineraryCommandSheet(day: _day)),
      ),
    );

    ChoiceChip chip = tester.widget(find.byType(ChoiceChip));
    expect(chip.selected, isFalse);

    await tester.tap(find.byType(ChoiceChip));
    await tester.pump();
    chip = tester.widget(find.byType(ChoiceChip));
    expect(chip.selected, isTrue);

    await tester.tap(find.byType(ChoiceChip));
    await tester.pump();
    chip = tester.widget(find.byType(ChoiceChip));
    expect(chip.selected, isFalse);
  });
}
