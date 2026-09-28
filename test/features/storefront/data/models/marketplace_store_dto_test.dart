import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/storefront/data/models/marketplace_store_dto.dart';

void main() {
  group('MarketplaceStoreDto', () {
    test('maps only customer-safe listing data', () {
      final store = MarketplaceStoreDto.fromJson(_storeJson()).toEntity();

      expect(store.id, 14);
      expect(store.displayName, 'Al Faris Parts');
      expect(store.city?.name, 'Aden');
      expect(store.averageRating, 4.5);
      expect(store.primaryPictureUrl, '/api/media/stores/14/pictures/8');
    });

    test(
      'rejects an external image URL before it can receive a bearer header',
      () {
        final json = _storeJson()
          ..['pictures'] = [
            {'id': 8, 'url': 'https://untrusted.example/store.jpg'},
          ];

        expect(
          () => MarketplaceStoreDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('rejects a media URL for another store', () {
      final json = _storeJson()
        ..['pictures'] = [
          {'id': 8, 'url': '/api/media/stores/99/pictures/8'},
        ];

      expect(
        () => MarketplaceStoreDto.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, Object?> _storeJson() {
  return {
    'id': 14,
    'name': 'Al Faris Auto Parts',
    'nick_name': 'Al Faris Parts',
    'city': {'id': 2, 'name': 'Aden'},
    'average_rating': 4.5,
    'pictures': [
      {'id': 8, 'url': '/api/media/stores/14/pictures/8'},
    ],
  };
}
