import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_envelope.dart';

void main() {
  group('ApiEnvelope', () {
    test('decodes Laravel pagination metadata with typed values', () {
      final envelope = ApiEnvelope<String>.fromJson({
        'success': true,
        'message': 'ok',
        'data': 'value',
        'meta': {
          'current_page': 2,
          'last_page': 3,
          'per_page': 15,
          'total': 31,
        },
      }, (data) => data! as String);

      expect(envelope.data, 'value');
      expect(envelope.pagination?.currentPage, 2);
      expect(envelope.pagination?.lastPage, 3);
      expect(envelope.pagination?.perPage, 15);
      expect(envelope.pagination?.total, 31);
    });

    test('rejects malformed pagination metadata', () {
      expect(
        () => ApiEnvelope<void>.fromJson({
          'success': true,
          'message': 'ok',
          'data': null,
          'meta': {
            'current_page': 2,
            'last_page': 1,
            'per_page': 15,
            'total': 15,
          },
        }, (_) {}),
        throwsA(isA<ApiContractException>()),
      );
    });
  });
}
