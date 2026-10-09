class Place {
  final String id;
  final String name;
  final String? address;
  final List<String> categories;
  final String? description;

  final int priceMin;
  final int priceMax;
  final int visitDurationMinutes;

  final String? openTime;
  final String? closeTime;

  final double? latitude;
  final double? longitude;
  final double? rating;

  final bool indoor;

  final String? imageUrl;
  final String? sourceUrl;
  final String? googlePlaceId;

  const Place({
    required this.id,
    required this.name,
    this.address,
    required this.categories,
    this.description,
    required this.priceMin,
    required this.priceMax,
    required this.visitDurationMinutes,
    this.openTime,
    this.closeTime,
    this.latitude,
    this.longitude,
    this.rating,
    required this.indoor,
    this.imageUrl,
    this.sourceUrl,
    this.googlePlaceId,
  });
}
