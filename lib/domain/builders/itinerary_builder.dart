import 'dart:math' as math;

import '../../core/utils/distance_utils.dart';
import '../entities/generated_itinerary.dart';
import '../entities/itinerary_day.dart';
import '../entities/itinerary_item.dart';
import '../entities/place.dart';
import '../entities/scored_place.dart';
import '../entities/trip_request.dart';

class ItineraryBuilder {
  static const int _defaultDayStart = 8 * 60;
  static const int _lunchStart = 11 * 60 + 30;
  static const int _latestLunchStart = 13 * 60 + 30;
  static const int _dayEnd = 19 * 60;

  GeneratedItinerary build({
    required TripRequest request,
    required List<ScoredPlace> scoredPlaces,
    Map<int, String> dayPaces = const {},
    Map<int, int> dayStartMinutes = const {},
    Set<int> indoorOnlyDays = const {},
  }) {
    if (!request.isValid) {
      return const GeneratedItinerary(
        days: [],
        totalCost: 0,
        totalDistance: 0,
        warnings: ['Thông tin chuyến đi chưa hợp lệ.'],
      );
    }

    final warnings = <String>{};
    final candidates = _uniqueCandidates(scoredPlaces);
    final targetsPerDay = List.generate(
      request.days,
      (index) => _placeRange(dayPaces[index + 1] ?? request.pace).$2,
    );
    final groups = _clusterByDay(
      candidates: candidates,
      dayCount: request.days,
      targetsPerDay: targetsPerDay,
      indoorOnlyDays: indoorOnlyDays,
    );

    final days = <ItineraryDay>[];
    for (var index = 0; index < request.days; index++) {
      final ordered = _orderForTravel(groups[index]);
      days.add(
        _scheduleDay(
          dayNumber: index + 1,
          candidates: ordered,
          request: request,
          warnings: warnings,
          dayStartMinute: dayStartMinutes[index + 1] ?? _defaultDayStart,
        ),
      );
    }

    for (final day in days) {
      final range = _placeRange(dayPaces[day.dayNumber] ?? request.pace);
      final count = day.placeItems.length;
      if (count < range.$1) {
        warnings.add(
          'Ngày ${day.dayNumber} chỉ xếp được $count địa điểm do giới hạn thời gian mở cửa.',
        );
      }
    }

    return GeneratedItinerary(
      days: List<ItineraryDay>.unmodifiable(days),
      totalCost: days.fold(0, (sum, day) => sum + day.totalCost),
      totalDistance: days.fold(0.0, (sum, day) => sum + day.totalDistance),
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  List<ScoredPlace> _uniqueCandidates(List<ScoredPlace> input) {
    final byId = <String, ScoredPlace>{};
    for (final candidate in input) {
      final place = candidate.place;
      if (place.id.trim().isEmpty ||
          place.name.trim().isEmpty ||
          place.categories.isEmpty ||
          place.visitDurationMinutes <= 0) {
        continue;
      }
      final current = byId[place.id];
      if (current == null || candidate.totalScore > current.totalScore) {
        byId[place.id] = candidate;
      }
    }
    final result = byId.values.toList();
    result.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return result;
  }

  List<List<ScoredPlace>> _clusterByDay({
    required List<ScoredPlace> candidates,
    required int dayCount,
    required List<int> targetsPerDay,
    required Set<int> indoorOnlyDays,
  }) {
    final groups = List.generate(dayCount, (_) => <ScoredPlace>[]);
    final remaining = List<ScoredPlace>.of(candidates);

    for (
      var dayIndex = 0;
      dayIndex < dayCount && remaining.isNotEmpty;
      dayIndex++
    ) {
      final group = groups[dayIndex];
      final indoorOnly = indoorOnlyDays.contains(dayIndex + 1);
      final firstIndex = remaining.indexWhere(
        (candidate) => !indoorOnly || candidate.place.indoor,
      );
      if (firstIndex < 0) continue;
      group.add(remaining.removeAt(firstIndex));
      final targetPerDay = targetsPerDay[dayIndex];

      while (group.length < targetPerDay && remaining.isNotEmpty) {
        final eligible = remaining
            .where((candidate) => !indoorOnly || candidate.place.indoor)
            .toList(growable: false);
        if (eligible.isEmpty) break;
        final eligibleIndex = _closestCandidateIndex(group, eligible);
        final next = eligible[eligibleIndex];
        remaining.remove(next);
        group.add(next);
      }
    }

    return groups;
  }

  int _closestCandidateIndex(
    List<ScoredPlace> group,
    List<ScoredPlace> remaining,
  ) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    var foundKnownDistance = false;

    for (var index = 0; index < remaining.length; index++) {
      final candidate = remaining[index];
      final distances = group
          .map((selected) => _knownDistance(selected.place, candidate.place))
          .whereType<double>();
      if (distances.isEmpty) continue;

      final distance = distances.reduce(math.min);
      if (!foundKnownDistance || distance < bestDistance) {
        foundKnownDistance = true;
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  List<ScoredPlace> _orderForTravel(List<ScoredPlace> group) {
    if (group.length < 2) return List<ScoredPlace>.of(group);
    final remaining = List<ScoredPlace>.of(group)..removeAt(0);
    final ordered = <ScoredPlace>[group.first];

    while (remaining.isNotEmpty) {
      final current = ordered.last.place;
      var bestIndex = 0;
      var bestDistance = double.infinity;
      for (var index = 0; index < remaining.length; index++) {
        final distance = _knownDistance(current, remaining[index].place);
        if (distance != null && distance < bestDistance) {
          bestDistance = distance;
          bestIndex = index;
        }
      }
      ordered.add(remaining.removeAt(bestIndex));
    }
    return ordered;
  }

  ItineraryDay _scheduleDay({
    required int dayNumber,
    required List<ScoredPlace> candidates,
    required TripRequest request,
    required Set<String> warnings,
    required int dayStartMinute,
  }) {
    final items = <ItineraryItem>[
      ItineraryItem(
        type: ItineraryItemType.meal,
        title: 'Ăn sáng',
        startMinute: dayStartMinute - 30,
        endMinute: dayStartMinute,
        estimatedCost: 50000 * request.people,
        note: 'Nạp năng lượng trước khi bắt đầu lịch trình.',
      ),
    ];
    var cursor = dayStartMinute;
    var lunchInserted = false;
    Place? previousPlace;

    for (final candidate in candidates) {
      final place = candidate.place;
      final travel = _travelFrom(previousPlace, place, request.transport);
      final duration = place.visitDurationMinutes;

      if (!lunchInserted &&
          cursor < _latestLunchStart &&
          cursor + travel.minutes + duration > 12 * 60 + 15) {
        cursor = _insertLunchAndRest(
          items: items,
          cursor: cursor,
          people: request.people,
        );
        lunchInserted = true;
      }

      final arrival = cursor + travel.minutes;
      final openMinute = _parseClock(place.openTime) ?? 0;
      final closeMinute = _parseClock(place.closeTime) ?? 24 * 60;
      final visitStart = math.max(arrival, openMinute);
      final visitEnd = visitStart + duration;

      if (visitEnd > closeMinute || visitEnd > _dayEnd) {
        warnings.add(
          'Không thể xếp ${place.name} vào ngày $dayNumber trước giờ đóng cửa.',
        );
        continue;
      }

      items.add(
        ItineraryItem(
          type: ItineraryItemType.travel,
          title: previousPlace == null
              ? 'Di chuyển đến ${place.name}'
              : 'Di chuyển đến điểm tiếp theo',
          startMinute: cursor,
          endMinute: arrival,
          distanceKm: travel.distanceKm,
          estimatedCost: _travelCost(request.transport, travel.distanceKm),
          note: travel.estimated
              ? 'Thời gian ước tính do địa điểm chưa đủ tọa độ.'
              : '${travel.distanceKm.toStringAsFixed(1)} km',
        ),
      );

      if (visitStart > arrival) {
        items.add(
          ItineraryItem(
            type: ItineraryItemType.rest,
            title: 'Nghỉ ngơi và chờ mở cửa',
            startMinute: arrival,
            endMinute: visitStart,
          ),
        );
      }

      final averageCost = ((place.priceMin + place.priceMax) / 2).round();
      items.add(
        ItineraryItem(
          type: ItineraryItemType.place,
          title: place.name,
          startMinute: visitStart,
          endMinute: visitEnd,
          place: place,
          estimatedCost: averageCost * request.people,
          note: candidate.reasons.isEmpty ? null : candidate.reasons.first,
        ),
      );
      if (travel.estimated && previousPlace != null) {
        warnings.add(
          'Một số quãng đường ngày $dayNumber được ước tính vì thiếu tọa độ.',
        );
      }
      cursor = visitEnd;
      previousPlace = place;
    }

    if (!lunchInserted) {
      cursor = _insertLunchAndRest(
        items: items,
        cursor: cursor,
        people: request.people,
      );
      if (cursor > _latestLunchStart + 80) {
        warnings.add('Ngày $dayNumber có giờ ăn trưa muộn.');
      }
    }

    items.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return ItineraryDay(
      dayNumber: dayNumber,
      items: List<ItineraryItem>.unmodifiable(items),
      totalCost: items.fold(0, (sum, item) => sum + item.estimatedCost),
      totalDistance: items.fold(0.0, (sum, item) => sum + item.distanceKm),
    );
  }

  int _insertLunchAndRest({
    required List<ItineraryItem> items,
    required int cursor,
    required int people,
  }) {
    var start = math.max(cursor, _lunchStart);
    if (start > _latestLunchStart) start = cursor;

    if (start > cursor) {
      items.add(
        ItineraryItem(
          type: ItineraryItemType.rest,
          title: 'Nghỉ ngơi',
          startMinute: cursor,
          endMinute: start,
        ),
      );
    }
    items.add(
      ItineraryItem(
        type: ItineraryItemType.meal,
        title: start > _latestLunchStart ? 'Ăn trưa muộn' : 'Ăn trưa',
        startMinute: start,
        endMinute: start + 60,
        estimatedCost: 100000 * people,
        note: 'Ưu tiên quán ăn gần khu vực đang tham quan.',
      ),
    );
    items.add(
      ItineraryItem(
        type: ItineraryItemType.rest,
        title: 'Nghỉ sau bữa trưa',
        startMinute: start + 60,
        endMinute: start + 80,
      ),
    );
    return start + 80;
  }

  _TravelEstimate _travelFrom(Place? from, Place to, String transport) {
    if (from == null) {
      return const _TravelEstimate(minutes: 20, distanceKm: 0, estimated: true);
    }

    final distance = _knownDistance(from, to);
    if (distance == null) {
      return const _TravelEstimate(minutes: 20, distanceKm: 0, estimated: true);
    }
    final speed = switch (transport) {
      'walking' => 4.5,
      'car' || 'taxi' => 28.0,
      _ => 24.0,
    };
    final minutes = math.max(10, (distance / speed * 60).ceil() + 5);
    return _TravelEstimate(
      minutes: math.min(minutes, 90),
      distanceKm: distance,
      estimated: false,
    );
  }

  int _travelCost(String transport, double distanceKm) {
    final rate = switch (transport) {
      'walking' => 0,
      'motorbike' => 3000,
      'car' => 8000,
      'taxi' => 15000,
      _ => 0,
    };
    return (distanceKm * rate).round();
  }

  double? _knownDistance(Place from, Place to) {
    if (from.latitude == null ||
        from.longitude == null ||
        to.latitude == null ||
        to.longitude == null) {
      return null;
    }
    return DistanceUtils.haversineKilometers(
      startLatitude: from.latitude!,
      startLongitude: from.longitude!,
      endLatitude: to.latitude!,
      endLongitude: to.longitude!,
    );
  }

  int? _parseClock(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  (int, int) _placeRange(String pace) {
    return switch (pace) {
      'relaxed' => (2, 3),
      'packed' => (4, 5),
      _ => (3, 4),
    };
  }
}

class _TravelEstimate {
  final int minutes;
  final double distanceKm;
  final bool estimated;

  const _TravelEstimate({
    required this.minutes,
    required this.distanceKm,
    required this.estimated,
  });
}
