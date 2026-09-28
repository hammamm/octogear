import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/storefront/data/models/storefront_store_car_dto.dart';

void main() {
  test('maps a store inventory car with controlled media metadata', () {
    final car = StorefrontStoreCarDto.fromJson(
      _carJson(),
      storeId: 14,
    ).toEntity();

    expect(car.id, 31);
    expect(car.carName.name, 'Camry');
    expect(car.componentsCount, 7);
    expect(car.pictures.single.url, '/api/media/stores/14/cars/31/pictures/6');
  });

  test('rejects an inventory image that belongs to another store', () {
    final json = _carJson()
      ..['pictures'] = [
        {
          'id': 6,
          'url': '/api/media/stores/99/cars/31/pictures/6',
          'mime_type': 'image/jpeg',
          'size_bytes': 125000,
          'sort_order': 0,
        },
      ];

    expect(
      () => StorefrontStoreCarDto.fromJson(json, storeId: 14),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, Object?> _carJson() {
  return {
    'id': 31,
    'manufacturing_year': 2020,
    'car_name': {'id': 7, 'name': 'Camry'},
    'color': {'id': 2, 'name': 'White'},
    'fuel_type': {'id': 1, 'name': 'Petrol'},
    'components_count': 7,
    'pictures': [
      {
        'id': 6,
        'url': '/api/media/stores/14/cars/31/pictures/6',
        'mime_type': 'image/jpeg',
        'size_bytes': 125000,
        'sort_order': 0,
      },
    ],
  };
}
