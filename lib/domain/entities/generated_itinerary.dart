import 'itinerary_day.dart';

class GeneratedItinerary {
  final List<ItineraryDay> days;
  final int totalCost;
  final double totalDistance;
  final List<String> warnings;

  const GeneratedItinerary({
    required this.days,
    required this.totalCost,
    required this.totalDistance,
    this.warnings = const [],
  });
}
