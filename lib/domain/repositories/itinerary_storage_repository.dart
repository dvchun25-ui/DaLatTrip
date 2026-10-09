import '../entities/generated_itinerary.dart';
import '../entities/trip_request.dart';

abstract class ItineraryStorageRepository {
  Future<void> save({
    required TripRequest request,
    required GeneratedItinerary itinerary,
  });
}
