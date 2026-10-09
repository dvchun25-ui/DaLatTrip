enum ItineraryCommandAction {
  removePlace,
  addCategory,
  adjustDayPace,
  adjustDayStart,
  updateBudget,
  replaceOutdoor,
}

class ItineraryCommand {
  final ItineraryCommandAction action;
  final String? placeId;
  final String? category;
  final int? dayNumber;
  final String? pace;
  final int? totalBudget;
  final int? startMinute;
  final bool usedLocalFallback;

  const ItineraryCommand({
    required this.action,
    this.placeId,
    this.category,
    this.dayNumber,
    this.pace,
    this.totalBudget,
    this.startMinute,
    this.usedLocalFallback = false,
  });
}

class ItineraryCommandPlaceContext {
  final String id;
  final String name;
  final int dayNumber;
  final bool indoor;

  const ItineraryCommandPlaceContext({
    required this.id,
    required this.name,
    required this.dayNumber,
    required this.indoor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dayNumber': dayNumber,
    'indoor': indoor,
  };
}
