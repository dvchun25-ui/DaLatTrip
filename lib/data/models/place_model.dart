import '../../core/utils/category_mapper.dart';
import '../../domain/entities/place.dart';

class PlaceModel extends Place {
  const PlaceModel({
    required super.id,
    required super.name,
    super.address,
    required super.categories,
    super.description,
    required super.priceMin,
    required super.priceMax,
    required super.visitDurationMinutes,
    super.openTime,
    super.closeTime,
    super.latitude,
    super.longitude,
    super.rating,
    required super.indoor,
    super.imageUrl,
    super.sourceUrl,
    super.googlePlaceId,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: _requiredString(json['id']),
      name: _requiredString(json['name']),
      address: _nullableString(json['address']),
      categories: CategoryMapper.parseDatasetCategories(json['categories']),
      description: _nullableString(json['description']),
      priceMin: _toInt(json['price_min']),
      priceMax: _toInt(json['price_max']),
      visitDurationMinutes: _toInt(json['visit_duration_minutes']),
      openTime: _nullableString(json['open_time']),
      closeTime: _nullableString(json['close_time']),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
      rating: _toNullableDouble(json['rating']),
      indoor: _toBool(json['indoor']),
      imageUrl: _nullableString(json['image_url']),
      sourceUrl: _nullableString(json['source_url']),
      googlePlaceId: _nullableString(json['google_place_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'categories': categories,
      'description': description,
      'price_min': priceMin,
      'price_max': priceMax,
      'visit_duration_minutes': visitDurationMinutes,
      'open_time': openTime,
      'close_time': closeTime,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'indoor': indoor,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'google_place_id': googlePlaceId,
    };
  }

  static String _requiredString(Object? value) =>
      value?.toString().trim() ?? '';

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _toBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }
}
