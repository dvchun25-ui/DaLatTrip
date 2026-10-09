import '../constants/place_categories.dart';

class CategoryMapper {
  CategoryMapper._();

  static const Map<String, String> _aliases = {
    // Tham quan -> attraction
    'tham quan': PlaceCategories.attraction,
    'tham quan du lịch': PlaceCategories.attraction,
    'thamquan': PlaceCategories.attraction,
    'attraction': PlaceCategories.attraction,
    'attractions': PlaceCategories.attraction,

    // Ăn uống -> food
    'ăn uống': PlaceCategories.food,
    'an uong': PlaceCategories.food,
    'food': PlaceCategories.food,
    'ẩm thực': PlaceCategories.food,
    'am thuc': PlaceCategories.food,

    // Quán cafe -> cafe
    'quán cafe': PlaceCategories.cafe,
    'quan cafe': PlaceCategories.cafe,
    'cà phê': PlaceCategories.cafe,
    'ca phe': PlaceCategories.cafe,
    'cafe': PlaceCategories.cafe,
    'coffee': PlaceCategories.cafe,

    // Check-in -> checkin
    'check-in': PlaceCategories.checkin,
    'checkin': PlaceCategories.checkin,
    'chụp ảnh': PlaceCategories.checkin,
    'chup anh': PlaceCategories.checkin,

    // Thiên nhiên -> nature
    'thiên nhiên': PlaceCategories.nature,
    'thien nhien': PlaceCategories.nature,
    'nature': PlaceCategories.nature,

    // Văn hóa -> culture
    'văn hóa': PlaceCategories.culture,
    'văn hoá': PlaceCategories.culture,
    'van hoa': PlaceCategories.culture,
    'culture': PlaceCategories.culture,

    // Vui chơi -> entertainment
    'vui chơi': PlaceCategories.entertainment,
    'vui choi': PlaceCategories.entertainment,
    'entertainment': PlaceCategories.entertainment,

    // Khách sạn -> hotel
    'khách sạn': PlaceCategories.hotel,
    'khach san': PlaceCategories.hotel,
    'hotel': PlaceCategories.hotel,

    // Legacy / bổ trợ
    'thư giãn': PlaceCategories.relax,
    'thu gian': PlaceCategories.relax,
    'nghỉ dưỡng': PlaceCategories.relax,
    'nghi duong': PlaceCategories.relax,
    'lãng mạn': PlaceCategories.relax,
    'lang man': PlaceCategories.relax,
    'relax': PlaceCategories.relax,
    'khám phá': PlaceCategories.adventure,
    'kham pha': PlaceCategories.adventure,
    'phiêu lưu': PlaceCategories.adventure,
    'phieu luu': PlaceCategories.adventure,
    'adventure': PlaceCategories.adventure,
    'gia đình': PlaceCategories.family,
    'gia dinh': PlaceCategories.family,
    'family': PlaceCategories.family,
  };

  static const Map<String, String> _displayNames = {
    PlaceCategories.attraction: 'Tham quan',
    PlaceCategories.food: 'Ăn uống',
    PlaceCategories.cafe: 'Quán cafe',
    PlaceCategories.checkin: 'Check-in',
    PlaceCategories.nature: 'Thiên nhiên',
    PlaceCategories.culture: 'Văn hóa',
    PlaceCategories.entertainment: 'Vui chơi',
    PlaceCategories.hotel: 'Khách sạn',
    PlaceCategories.relax: 'Thư giãn',
    PlaceCategories.adventure: 'Khám phá',
    PlaceCategories.family: 'Gia đình',
  };

  static String? normalize(String? category) {
    if (category == null) return null;
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _aliases[normalized];
  }

  static List<String> parseDatasetCategories(Object? value) {
    if (value == null) return const [];

    final seen = <String>{};
    final result = <String>[];
    for (final raw in value.toString().split(';')) {
      final category = normalize(raw);
      if (category != null && seen.add(category)) {
        result.add(category);
      }
    }
    return result;
  }

  static String displayName(String category) {
    return _displayNames[normalize(category) ?? category] ?? category;
  }
}
