import '../../domain/entities/itinerary_command.dart';

class ItineraryCommandModel extends ItineraryCommand {
  const ItineraryCommandModel({
    required super.action,
    super.placeId,
    super.category,
    super.dayNumber,
    super.pace,
    super.totalBudget,
    super.startMinute,
  });

  factory ItineraryCommandModel.fromJson(Map<String, dynamic> json) {
    final action = switch (json['action']) {
      'remove_place' => ItineraryCommandAction.removePlace,
      'add_category' => ItineraryCommandAction.addCategory,
      'adjust_day_pace' => ItineraryCommandAction.adjustDayPace,
      'adjust_day_start' => ItineraryCommandAction.adjustDayStart,
      'update_budget' => ItineraryCommandAction.updateBudget,
      'replace_outdoor' => ItineraryCommandAction.replaceOutdoor,
      _ => throw const FormatException('Action sửa lịch trình không hợp lệ.'),
    };
    return ItineraryCommandModel(
      action: action,
      placeId: json['placeId'] as String?,
      category: json['category'] as String?,
      dayNumber: (json['dayNumber'] as num?)?.toInt(),
      pace: json['pace'] as String?,
      totalBudget: (json['totalBudget'] as num?)?.toInt(),
      startMinute: (json['startMinute'] as num?)?.toInt(),
    );
  }
}
