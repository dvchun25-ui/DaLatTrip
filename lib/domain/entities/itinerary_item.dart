import 'place.dart';

enum ItineraryItemType { place, travel, meal, rest }

class ItineraryItem {
  final ItineraryItemType type;
  final String title;
  final int startMinute;
  final int endMinute;
  final Place? place;
  final double distanceKm;
  final int estimatedCost;
  final String? note;

  const ItineraryItem({
    required this.type,
    required this.title,
    required this.startMinute,
    required this.endMinute,
    this.place,
    this.distanceKm = 0,
    this.estimatedCost = 0,
    this.note,
  });

  int get durationMinutes => endMinute - startMinute;

  String get timeLabel =>
      '${_formatMinute(startMinute)} - ${_formatMinute(endMinute)}';

  static String _formatMinute(int value) {
    final normalized = value.clamp(0, 24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
