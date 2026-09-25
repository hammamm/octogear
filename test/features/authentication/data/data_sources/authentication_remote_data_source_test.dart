import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/authentication/data/data_sources/authentication_remote_data_source.dart';

void main() {
  group('AuthenticationRemoteDataSourceImpl.register', () {
    test(
      'sends the optional device token with a new-user registration',
      () async {
        late RequestOptions request;
        final dataSource = AuthenticationRemoteDataSourceImpl(
          apiClient: _clientThatReturns({
            'success': true,
            'message': 'Registered',
            'data': {'token': 'abc'},
          }, onRequest: (value) => request = value),
        );

        final result = await dataSource.register(
          temporaryRegistrationToken: 'temporary-token',
          fullName: 'Amina',
          cityId: 3,
          deviceToken: 'fcm-device-token',
        );

        expect(result.value, 'abc');
        expect(request.uri.path, '/api/auth/register');
        expect(request.data, {
          'temp_token': 'temporary-token',
          'full_name': 'Amina',
          'city_id': 3,
          'device_token': 'fcm-device-token',
        });
      },
    );

    test('omits device_token when Firebase has no token', () async {
      late RequestOptions request;
      final dataSource = AuthenticationRemoteDataSourceImpl(
        apiClient: _clientThatReturns({
          'success': true,
          'message': 'Registered',
          'data': {'token': 'abc'},
        }, onRequest: (value) => request = value),
      );

      await dataSource.register(
        temporaryRegistrationToken: 'temporary-token',
        fullName: 'Amina',
        cityId: 3,
        deviceToken: null,
      );

      expect(request.data, {
        'temp_token': 'temporary-token',
        'full_name': 'Amina',
        'city_id': 3,
      });
    });
  });
}

ApiClient _clientThatReturns(
  Map<String, Object?> response, {
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
  final client = ApiClient(
    dio: dio,
    accessTokenResolver: () => null,
    localeResolver: () => 'en',
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response<Object?>(
            data: response,
            requestOptions: options,
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return client;
}
