import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';

void main() {
  final client = ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'https://api.octogear.test/api/')),
  );

  test(
    'resolves documented API-relative private media on the configured host',
    () {
      expect(
        client.resolveAuthenticatedApiUri(
          '/api/customer/customer-cars/9/pictures/17',
        ),
        Uri.parse(
          'https://api.octogear.test/api/customer/customer-cars/9/pictures/17',
        ),
      );
    },
  );

  test('does not allow a bearer header to be sent to another origin', () {
    expect(
      client.resolveAuthenticatedApiUri('https://untrusted.example/image.jpg'),
      isNull,
    );
    expect(
      client.resolveAuthenticatedApiUri('//untrusted.example/image.jpg'),
      isNull,
    );
  });
}
