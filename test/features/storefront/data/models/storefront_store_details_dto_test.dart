import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/storefront/data/models/storefront_store_details_dto.dart';

void main() {
  test('maps only customer-safe store detail data', () {
    final store = StorefrontStoreDetailsDto.fromJson(_detailJson()).toEntity();

    expect(store.id, 14);
    expect(store.displayName, 'Al Faris');
    expect(store.city?.name, 'Aden');
    expect(store.companies.single.name, 'Toyota');
    expect(store.soldQuantity, 27);
    expect(store.pictures.single.url, '/api/media/stores/14/pictures/8');
  });

  test('rejects an untrusted store gallery URL', () {
    final json = _detailJson()
      ..['pictures'] = [
        {
          'id': 8,
          'url': 'https://untrusted.example/store.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': 348291,
          'sort_order': 0,
        },
      ];

    expect(
      () => StorefrontStoreDetailsDto.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, Object?> _detailJson() {
  return {
    'id': 14,
    'name': 'Al Faris Auto Parts',
    'nick_name': 'Al Faris',
    'city': {'id': 2, 'name': 'Aden'},
    'companies': [
      {'id': 9, 'name': 'Toyota'},
    ],
    'average_rating': 4.5,
    'sold_quantity': 27,
    'pictures': [
      {
        'id': 8,
        'url': '/api/media/stores/14/pictures/8',
        'mime_type': 'image/jpeg',
        'size_bytes': 348291,
        'sort_order': 0,
      },
    ],
    'mobile': '500000000',
    'employee_name': 'Never mapped',
  };
}
