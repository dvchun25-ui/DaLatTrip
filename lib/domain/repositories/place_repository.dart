import '../entities/place.dart';

abstract class PlaceRepository {
  Future<List<Place>> getAllPlaces();

  Future<Place?> getPlaceById(String id);

  Future<List<Place>> getPlacesByCategory(String category);
}
