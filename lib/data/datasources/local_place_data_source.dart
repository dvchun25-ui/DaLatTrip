import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/place_model.dart';

class LocalPlaceDataSource {
  static const String assetPath = 'assets/data/dalat_places.json';

  final AssetBundle _assetBundle;
  List<PlaceModel>? _cachedPlaces;

  LocalPlaceDataSource({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  Future<List<PlaceModel>> getAllPlaces() async {
    final cached = _cachedPlaces;
    if (cached != null) return cached;

    final rawJson = await _assetBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException(
        'dalat_places.json phải chứa một JSON array.',
      );
    }

    final places = decoded
        .map((item) {
          if (item is! Map) {
            throw const FormatException(
              'Mỗi địa điểm phải là một JSON object.',
            );
          }
          return PlaceModel.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);

    assert(
      places.length == 200,
      'Expected 200 places, loaded ${places.length}.',
    );
    debugPrint('Loaded ${places.length} places from dalat_places.json');
    _cachedPlaces = List<PlaceModel>.unmodifiable(places);
    return _cachedPlaces!;
  }

  Future<PlaceModel?> getPlaceById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;
    final places = await getAllPlaces();
    for (final place in places) {
      if (place.id == normalizedId) return place;
    }
    return null;
  }

  Future<List<PlaceModel>> getPlacesByCategory(String category) async {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final places = await getAllPlaces();
    return List<PlaceModel>.unmodifiable(
      places.where((place) => place.categories.contains(normalized)),
    );
  }
}
