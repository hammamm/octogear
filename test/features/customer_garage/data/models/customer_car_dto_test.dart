import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/customer_garage/data/models/customer_car_dto.dart';

void main() {
  group('CustomerCarDto', () {
    test(
      'accepts cars without plate data and nullable or known transmission',
      () {
        for (final value in [null, 'manual', 'automatic', 'unknown']) {
          final json = _carJson()..['transmission_type'] = value;
          expect(
            CustomerCarDto.fromJson(json).toEntity().transmissionType,
            value,
          );
        }
        expect(
          () => CustomerCarDto.fromJson(
            _carJson()..['transmission_type'] = 'invalid',
          ),
          throwsFormatException,
        );
      },
    );
    test('maps private picture metadata without exposing a storage path', () {
      final car = CustomerCarDto.fromJson(_carJson()).toEntity();
      final picture = car.pictures.single;

      expect(car.company.name, 'Toyota');
      expect(picture.id, 17);
      expect(picture.url, '/api/customer/customer-cars/9/pictures/17');
      expect(picture.mimeType, 'image/jpeg');
      expect(picture.sizeBytes, 348291);
      expect(picture.sortOrder, 0);
    });

    test('rejects the old raw picture-string response contract', () {
      final json = _carJson()..['pictures'] = ['storage/customer-cars/a.jpg'];

      expect(
        () => CustomerCarDto.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'rejects an external picture URL before it can receive a bearer header',
      () {
        final json = _carJson()
          ..['pictures'] = [
            {
              'id': 17,
              'url': 'https://untrusted.example/image.jpg',
              'mime_type': 'image/jpeg',
              'size_bytes': 348291,
              'sort_order': 0,
            },
          ];

        expect(
          () => CustomerCarDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}

Map<String, Object?> _carJson() {
  return {
    'id': 9,
    'manufacturing_year': 2022,
    'transmission_type': 'automatic',
    'company': {'id': 1, 'name': 'Toyota'},
    'car_name': {'id': 4, 'name': 'Camry'},
    'color': {'id': 2, 'name': 'White'},
    'fuel_type': {'id': 1, 'name': 'Petrol'},
    'pictures': [
      {
        'id': 17,
        'url': '/api/customer/customer-cars/9/pictures/17',
        'mime_type': 'image/jpeg',
        'size_bytes': 348291,
        'sort_order': 0,
      },
    ],
    'created_at': '2026-09-26T10:15:00Z',
  };
}
