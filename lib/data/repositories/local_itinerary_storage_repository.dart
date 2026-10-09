import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/generated_itinerary.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/repositories/itinerary_storage_repository.dart';

class LocalItineraryStorageRepository implements ItineraryStorageRepository {
  static const String storageKey = 'saved_itineraries_v1';
  static const int _maximumSavedItineraries = 20;

  final Future<SharedPreferences> Function() _preferencesLoader;

  LocalItineraryStorageRepository({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  @override
  Future<void> save({
    required TripRequest request,
    required GeneratedItinerary itinerary,
  }) async {
    final preferences = await _preferencesLoader();
    final storedValue = preferences.getString(storageKey);
    final saved = <Object?>[];

    if (storedValue != null && storedValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedValue);
        if (decoded is List) saved.addAll(decoded);
      } on FormatException {
        // Recover from invalid legacy data by starting a clean local list.
      }
    }

    saved.insert(0, _serialize(request, itinerary));
    if (saved.length > _maximumSavedItineraries) {
      saved.removeRange(_maximumSavedItineraries, saved.length);
    }

    final didSave = await preferences.setString(storageKey, jsonEncode(saved));
    if (!didSave) {
      throw StateError('Thiết bị từ chối lưu lịch trình.');
    }
  }

  Map<String, Object?> _serialize(
    TripRequest request,
    GeneratedItinerary itinerary,
  ) {
    return {
      'id': DateTime.now().toUtc().toIso8601String(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'request': {
        'days': request.days,
        'people': request.people,
        'totalBudget': request.totalBudget,
        'interests': request.interests,
        'transport': request.transport,
        'pace': request.pace,
        'startLocation': request.startLocation,
        'specialRequirements': request.specialRequirements,
      },
      'itinerary': {
        'totalCost': itinerary.totalCost,
        'totalDistance': itinerary.totalDistance,
        'warnings': itinerary.warnings,
        'days': itinerary.days
            .map(
              (day) => {
                'dayNumber': day.dayNumber,
                'totalCost': day.totalCost,
                'totalDistance': day.totalDistance,
                'items': day.items
                    .map(
                      (item) => {
                        'type': item.type.name,
                        'title': item.title,
                        'startMinute': item.startMinute,
                        'endMinute': item.endMinute,
                        'placeId': item.place?.id,
                        'distanceKm': item.distanceKm,
                        'estimatedCost': item.estimatedCost,
                        'note': item.note,
                      },
                    )
                    .toList(growable: false),
              },
            )
            .toList(growable: false),
      },
    };
  }
}
