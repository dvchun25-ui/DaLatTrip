import 'package:flutter/foundation.dart';

import '../../../core/constants/place_categories.dart';
import '../../../core/utils/category_mapper.dart';
import '../../../data/datasources/local_place_data_source.dart';
import '../../../data/repositories/place_repository_impl.dart';
import '../../../domain/entities/place.dart';
import '../../../domain/repositories/place_repository.dart';

class ExploreController extends ChangeNotifier {
  final PlaceRepository _repository;

  ExploreController({PlaceRepository? repository})
      : _repository =
            repository ??
            PlaceRepositoryImpl(localDataSource: LocalPlaceDataSource());

  bool isLoading = false;
  String? errorMessage;
  List<Place> places = const [];
  List<Place> filteredPlaces = const [];

  String _keyword = '';
  String? _selectedCategory;

  String get keyword => _keyword;
  String? get selectedCategory => _selectedCategory;

  Future<void> loadPlaces() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      places = List<Place>.unmodifiable(await _repository.getAllPlaces());
      assert(
        places.length == 200,
        'Expected 200 places, loaded ${places.length}.',
      );
      _applyFilters();
    } catch (error) {
      errorMessage = 'Không thể tải danh sách địa điểm: $error';
      places = const [];
      filteredPlaces = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void searchPlaces(String keyword) {
    _keyword = keyword.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = CategoryMapper.normalize(category) ?? category;
    _applyFilters();
    notifyListeners();
  }

  void clearFilter() {
    _selectedCategory = null;
    _keyword = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final normalizedKeywordCategory = CategoryMapper.normalize(_keyword);
    filteredPlaces = List<Place>.unmodifiable(
      places.where((place) {
        final matchesCategory = _selectedCategory == null ||
            place.categories.contains(_selectedCategory) ||
            (_selectedCategory == PlaceCategories.attraction &&
                (place.categories.contains(PlaceCategories.culture) ||
                    place.categories.contains(PlaceCategories.adventure)));
        if (!matchesCategory) return false;
        if (_keyword.isEmpty) return true;

        final categoryText = place.categories
            .map(CategoryMapper.displayName)
            .join(' ')
            .toLowerCase();
        final searchableText = [
          place.name,
          place.address ?? '',
          place.description ?? '',
          categoryText,
        ].join(' ').toLowerCase();
        return searchableText.contains(_keyword) ||
            (normalizedKeywordCategory != null &&
                place.categories.contains(normalizedKeywordCategory));
      }),
    );
  }
}
