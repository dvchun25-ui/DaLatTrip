import '../entities/itinerary_command.dart';

class LocalItineraryCommandParser {
  const LocalItineraryCommandParser();

  ItineraryCommand? parse({
    required String message,
    String? selectedPlaceId,
    int? selectedDay,
    required List<ItineraryCommandPlaceContext> places,
  }) {
    final text = _fold(message);

    if (_containsAny(text, ['bo ', 'xoa ', 'loai '])) {
      final placeId = _resolvePlace(
        text,
        selectedPlaceId: selectedPlaceId,
        places: places,
      );
      if (placeId == null) return null;
      return ItineraryCommand(
        action: ItineraryCommandAction.removePlace,
        placeId: placeId,
        usedLocalFallback: true,
      );
    }

    if (text.contains('them') &&
        _containsAny(text, ['cafe', 'coffee', 'ca phe'])) {
      return const ItineraryCommand(
        action: ItineraryCommandAction.addCategory,
        category: 'cafe',
        usedLocalFallback: true,
      );
    }

    if (text.contains('ngay') &&
        _containsAny(text, ['nhe hon', 'thu gian', 'chill'])) {
      final day = _extractDay(text) ?? selectedDay;
      if (day == null) return null;
      return ItineraryCommand(
        action: ItineraryCommandAction.adjustDayPace,
        dayNumber: day,
        pace: 'relaxed',
        usedLocalFallback: true,
      );
    }

    if (text.contains('ngay') &&
        _containsAny(text, ['bat dau', 'tu luc', 'khoi hanh'])) {
      final day = _extractDay(text) ?? selectedDay;
      final startMinute = _extractStartMinute(text);
      if (day == null || startMinute == null) return null;
      return ItineraryCommand(
        action: ItineraryCommandAction.adjustDayStart,
        dayNumber: day,
        startMinute: startMinute,
        usedLocalFallback: true,
      );
    }

    if (text.contains('mua') &&
        _containsAny(text, ['ngoai troi', 'doi dia diem'])) {
      return ItineraryCommand(
        action: ItineraryCommandAction.replaceOutdoor,
        dayNumber: _extractDay(text) ?? selectedDay,
        usedLocalFallback: true,
      );
    }

    final budget = _extractBudget(text);
    if (budget != null && _containsAny(text, ['ngan sach', 'giam', 'doi'])) {
      return ItineraryCommand(
        action: ItineraryCommandAction.updateBudget,
        totalBudget: budget,
        usedLocalFallback: true,
      );
    }
    return null;
  }

  String? _resolvePlace(
    String text, {
    required String? selectedPlaceId,
    required List<ItineraryCommandPlaceContext> places,
  }) {
    if (text.contains('nay')) return selectedPlaceId;
    final matches = places
        .where((place) => text.contains(_fold(place.name)))
        .toList(growable: false);
    if (matches.length == 1) return matches.single.id;
    return selectedPlaceId;
  }

  int? _extractDay(String text) {
    final match = RegExp(r'ngay\s*(\d+)').firstMatch(text);
    return int.tryParse(match?.group(1) ?? '');
  }

  int? _extractStartMinute(String text) {
    final match = RegExp(
      r'(?:bat dau|tu luc|khoi hanh|tu)\D{0,12}(\d{1,2})'
      r'(?:\s*(?:g|gio|:)\s*(\d{1,2})?)?',
    ).firstMatch(text);
    final hour = int.tryParse(match?.group(1) ?? '');
    final minute = int.tryParse(match?.group(2) ?? '0');
    if (hour == null || minute == null || minute >= 60) return null;
    final result = hour * 60 + minute;
    return result >= 360 && result <= 960 ? result : null;
  }

  int? _extractBudget(String text) {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(trieu|nghin|k)\b',
    ).firstMatch(text);
    if (match == null) return null;
    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (amount == null) return null;
    final multiplier = match.group(2) == 'trieu' ? 1000000 : 1000;
    return (amount * multiplier).round();
  }

  bool _containsAny(String value, List<String> patterns) {
    return patterns.any(value.contains);
  }

  String _fold(String value) {
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const target =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = value.toLowerCase();
    for (var index = 0; index < source.length; index++) {
      result = result.replaceAll(source[index], target[index]);
    }
    return result;
  }
}
