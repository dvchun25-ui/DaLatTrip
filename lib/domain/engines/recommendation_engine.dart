import 'dart:math' as math;

import '../../core/utils/category_mapper.dart';
import '../entities/place.dart';
import '../entities/scored_place.dart';
import '../entities/trip_request.dart';

class RecommendationEngine {
  static const double _interestWeight = 0.40;
  static const double _budgetWeight = 0.20;
  static const double _ratingWeight = 0.15;
  static const double _distanceWeight = 0.15;
  static const double _diversityWeight = 0.10;

  List<ScoredPlace> recommend({
    required TripRequest request,
    required List<Place> places,
    int limit = 25,
  }) {
    if (!request.isValid || limit <= 0) return const [];

    final candidates = places.where(_isValidCandidate).toList(growable: false);
    if (candidates.isEmpty) return const [];

    final targetCount = math.min(limit, candidates.length);
    final selected = <ScoredPlace>[];
    final remaining = List<Place>.of(candidates);
    final categoryUsage = <String, int>{};

    while (selected.length < targetCount && remaining.isNotEmpty) {
      ScoredPlace? best;
      Place? bestPlace;

      for (final place in remaining) {
        final scored = _scorePlace(
          request: request,
          place: place,
          categoryUsage: categoryUsage,
        );
        if (best == null ||
            scored.totalScore > best.totalScore ||
            (scored.totalScore == best.totalScore &&
                place.name.compareTo(best.place.name) < 0)) {
          best = scored;
          bestPlace = place;
        }
      }

      if (best == null || bestPlace == null) break;
      selected.add(best);
      remaining.remove(bestPlace);
      for (final category in bestPlace.categories) {
        categoryUsage.update(category, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    selected.sort((a, b) {
      final scoreComparison = b.totalScore.compareTo(a.totalScore);
      if (scoreComparison != 0) return scoreComparison;
      return a.place.name.compareTo(b.place.name);
    });
    return List<ScoredPlace>.unmodifiable(selected);
  }

  bool _isValidCandidate(Place place) {
    return place.id.trim().isNotEmpty &&
        place.name.trim().isNotEmpty &&
        place.categories.isNotEmpty &&
        place.visitDurationMinutes > 0;
  }

  ScoredPlace _scorePlace({
    required TripRequest request,
    required Place place,
    required Map<String, int> categoryUsage,
  }) {
    final interestScore = _interestScore(request, place);
    final budgetScore = _budgetScore(request, place);
    final ratingScore = _ratingScore(place);
    final distanceScore = _distanceScore(request, place);
    final diversityScore = _diversityScore(place, categoryUsage);
    final totalScore = _clampScore(
      interestScore * _interestWeight +
          budgetScore * _budgetWeight +
          ratingScore * _ratingWeight +
          distanceScore * _distanceWeight +
          diversityScore * _diversityWeight,
    );

    return ScoredPlace(
      place: place,
      totalScore: totalScore,
      interestScore: interestScore,
      budgetScore: budgetScore,
      ratingScore: ratingScore,
      distanceScore: distanceScore,
      diversityScore: diversityScore,
      reasons: List.unmodifiable(
        _buildReasons(
          request: request,
          place: place,
          interestScore: interestScore,
          budgetScore: budgetScore,
        ),
      ),
    );
  }

  double _interestScore(TripRequest request, Place place) {
    final requested = request.interests.toSet();
    if (requested.isEmpty) return 0;
    final matched = requested.intersection(place.categories.toSet()).length;
    return _clampScore(matched / requested.length);
  }

  double _budgetScore(TripRequest request, Place place) {
    final dailyBudget = request.totalBudget / request.days;
    final activityBudgetPerDay = dailyBudget * 0.35;
    final placesPerDay = switch (request.pace) {
      'relaxed' => 3,
      'packed' => 5,
      _ => 4,
    };
    final placeBudget = activityBudgetPerDay / placesPerDay;
    if (placeBudget <= 0) return 0;

    final averagePlaceCost = (place.priceMin + place.priceMax) / 2;
    if (averagePlaceCost <= 0 || averagePlaceCost <= placeBudget) return 1;
    return _clampScore(placeBudget / averagePlaceCost);
  }

  double _ratingScore(Place place) {
    final rating = place.rating;
    if (rating == null) return 0.6;
    return _clampScore(rating / 5);
  }

  double _distanceScore(TripRequest request, Place place) {
    // TripRequest currently stores a human-readable start location, not a
    // coordinate pair. Keep a neutral fallback until geocoding is introduced.
    if (request.startLocation == null ||
        place.latitude == null ||
        place.longitude == null) {
      return 0.5;
    }
    return 0.5;
  }

  double _diversityScore(Place place, Map<String, int> categoryUsage) {
    if (categoryUsage.isEmpty) return 1;
    final leastUsedCategory = place.categories
        .map((category) => categoryUsage[category] ?? 0)
        .reduce(math.min);
    return _clampScore(1 / (leastUsedCategory + 1));
  }

  List<String> _buildReasons({
    required TripRequest request,
    required Place place,
    required double interestScore,
    required double budgetScore,
  }) {
    final reasons = <String>[];
    final matchedInterests = request.interests
        .where(place.categories.contains)
        .map(CategoryMapper.displayName)
        .toList(growable: false);

    if (interestScore > 0 && matchedInterests.isNotEmpty) {
      reasons.add(
        'Phù hợp với sở thích ${matchedInterests.join(' và ').toLowerCase()}',
      );
    }
    if (budgetScore >= 0.75) {
      reasons.add('Phù hợp ngân sách chuyến đi');
    }
    if ((place.rating ?? 0) >= 4.5) {
      reasons.add('Được người dùng đánh giá cao');
    }
    if (place.categories.length >= 3) {
      reasons.add('Kết hợp nhiều loại trải nghiệm');
    }
    if (reasons.isEmpty) {
      reasons.add(
        'Thời lượng tham quan ${place.visitDurationMinutes} phút phù hợp để sắp xếp lịch trình',
      );
    }
    return reasons;
  }

  double _clampScore(num value) => value.clamp(0.0, 1.0).toDouble();
}
