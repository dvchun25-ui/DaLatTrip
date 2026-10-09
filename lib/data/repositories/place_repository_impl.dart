import '../../core/utils/category_mapper.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/local_place_data_source.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final LocalPlaceDataSource localDataSource;

  PlaceRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Place>> getAllPlaces() => localDataSource.getAllPlaces();

  @override
  Future<Place?> getPlaceById(String id) => localDataSource.getPlaceById(id);

  @override
  Future<List<Place>> getPlacesByCategory(String category) {
    final normalized = CategoryMapper.normalize(category);
    if (normalized == null) return Future.value(const []);
    return localDataSource.getPlacesByCategory(normalized);
  }
}
