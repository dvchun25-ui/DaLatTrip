import '../entities/budget_assessment.dart';
import '../entities/generated_itinerary.dart';
import '../entities/trip_request.dart';

class BudgetEngine {
  BudgetAssessment evaluate({
    required TripRequest request,
    required GeneratedItinerary itinerary,
  }) {
    final remaining = request.totalBudget - itinerary.totalCost;
    final warnings = <String>[];
    if (remaining < 0) {
      warnings.add(
        'Chi phí dự kiến vượt ngân sách ${_money(-remaining)}. Hãy đổi địa điểm hoặc giảm nhịp độ.',
      );
    } else if (itinerary.totalCost > request.totalBudget * 0.9) {
      warnings.add('Chi phí dự kiến đã sử dụng hơn 90% ngân sách chuyến đi.');
    }
    return BudgetAssessment(
      tripBudget: request.totalBudget,
      estimatedCost: itinerary.totalCost,
      remainingBudget: remaining,
      isWithinBudget: remaining >= 0,
      warnings: List.unmodifiable(warnings),
    );
  }

  String _money(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }
}
