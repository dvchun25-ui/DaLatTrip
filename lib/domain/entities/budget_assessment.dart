class BudgetAssessment {
  final int tripBudget;
  final int estimatedCost;
  final int remainingBudget;
  final bool isWithinBudget;
  final List<String> warnings;

  const BudgetAssessment({
    required this.tripBudget,
    required this.estimatedCost,
    required this.remainingBudget,
    required this.isWithinBudget,
    this.warnings = const [],
  });
}
