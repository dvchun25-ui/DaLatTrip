import 'itinerary_item.dart';

class ItineraryDay {
  final int dayNumber;
  final List<ItineraryItem> items;
  final int totalCost;
  final double totalDistance;

  const ItineraryDay({
    required this.dayNumber,
    required this.items,
    required this.totalCost,
    required this.totalDistance,
  });

  List<ItineraryItem> get placeItems => List<ItineraryItem>.unmodifiable(
    items.where((item) => item.type == ItineraryItemType.place),
  );
}
