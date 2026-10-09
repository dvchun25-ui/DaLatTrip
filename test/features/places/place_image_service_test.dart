import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/features/places/services/place_image_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PlaceImageService();

  test('absolute remote image URL is kept unchanged', () {
    final result = service.getImageUrl(
      _place(imageUrl: 'https://cdn.example/custom.jpg'),
    );

    expect(result, 'https://cdn.example/custom.jpg');
  });

  test('local asset path is kept unchanged', () {
    expect(
      service.getImageUrl(
        _place(imageUrl: 'assets/images/places/ho_tuyen_lam.webp'),
      ),
      'assets/images/places/ho_tuyen_lam.webp',
    );
  });

  test('backend media path is resolved against API host', () {
    final result = service.getImageUrl(
      _place(imageUrl: '/media/places/ho_tuyen_lam.webp'),
    );

    expect(result, 'http://10.0.2.2:8000/media/places/ho_tuyen_lam.webp');
  });

  test('missing image returns null for the placeholder', () {
    expect(service.getImageUrl(_place()), isNull);
  });
}

Place _place({String? imageUrl, String? googlePlaceId}) {
  return Place(
    id: 'place',
    name: 'Địa điểm',
    categories: const ['nature'],
    priceMin: 0,
    priceMax: 0,
    visitDurationMinutes: 60,
    indoor: false,
    imageUrl: imageUrl,
    googlePlaceId: googlePlaceId,
  );
}
