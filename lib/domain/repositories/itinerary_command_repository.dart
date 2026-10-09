import '../entities/itinerary_command.dart';

abstract interface class ItineraryCommandRepository {
  Future<ItineraryCommand> parseCommand({
    required String message,
    String? selectedPlaceId,
    int? selectedDay,
    required List<ItineraryCommandPlaceContext> places,
  });
}
