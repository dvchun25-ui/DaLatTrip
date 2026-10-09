import 'place.dart';

class ScoredPlace {
  final Place place;
  final double totalScore;
  final double interestScore;
  final double budgetScore;
  final double ratingScore;
  final double distanceScore;
  final double diversityScore;
  final List<String> reasons;

  const ScoredPlace({
    required this.place,
    required this.totalScore,
    required this.interestScore,
    required this.budgetScore,
    required this.ratingScore,
    required this.distanceScore,
    required this.diversityScore,
    required this.reasons,
  });
}
