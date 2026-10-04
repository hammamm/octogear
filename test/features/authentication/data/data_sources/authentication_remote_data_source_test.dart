import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/authentication/data/data_sources/authentication_remote_data_source.dart';

void main() {
  group('registration city pages', () {
    test(
      'returns the first page without downloading the remaining 91',
      () async {
        final requests = <RequestOptions>[];
        final source = AuthenticationRemoteDataSourceImpl(
          apiClient: _clientThatReturns({
            'success': true,
            'data': [
              {'id': 1, 'name': 'Aden'},
            ],
            'meta': {
              'current_page': 1,
              'last_page': 92,
              'per_page': 50,
              'total': 4581,
            },
          }, onRequest: requests.add),
        );
        final result = await source.fetchCities();
        expect(result.items.single.name, 'Aden');
        expect(result.lastPage, 92);
        expect(requests, hasLength(1));
        expect(requests.single.uri.path, '/api/reference/cities');
        expect(requests.single.queryParameters, {'page': 1, 'per_page': 50});
        expect(requests.single.headers['Accept-Language'], 'en');
        expect(requests.single.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('sends trimmed server search and the requested page', () async {
      late RequestOptions request;
      final source = AuthenticationRemoteDataSourceImpl(
        apiClient: _clientThatReturns({
          'success': true,
          'data': [
            {'id': 55, 'name': 'Aden'},
          ],
          'meta': {
            'current_page': 2,
            'last_page': 2,
            'per_page': 50,
            'total': 51,
          },
        }, onRequest: (value) => request = value),
      );
      final result = await source.fetchCities(search: '  Aden  ', page: 2);
      expect(request.queryParameters, {
        'page': 2,
        'per_page': 50,
        'search': 'Aden',
      });
      expect(result.page, 2);
    });

    test(
      'rejects missing or wrong pagination instead of silently truncating',
      () async {
        for (final meta in [
          null,
          {'current_page': 2, 'last_page': 2, 'per_page': 50, 'total': 51},
        ]) {
          final source = AuthenticationRemoteDataSourceImpl(
            apiClient: _clientThatReturns({
              'success': true,
              'data': [
                {'id': 1, 'name': 'Aden'},
              ],
              'meta': meta,
            }),
          );
          await expectLater(source.fetchCities(), throwsA(isA<ApiFailure>()));
        }
      },
    );

    test('an empty final page represents no search results', () async {
      final source = AuthenticationRemoteDataSourceImpl(
        apiClient: _clientThatReturns({
          'success': true,
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 50,
            'total': 0,
          },
        }),
      );
      expect((await source.fetchCities(search: 'unknown')).items, isEmpty);
    });
  });
  test(
    'send returns an optional testing code without losing leading zeroes',
    () async {
      for (final value in ['0042', null, 1234, '12345', 'oops']) {
        final source = AuthenticationRemoteDataSourceImpl(
          apiClient: _clientThatReturns({
            'success': true,
            'data': value == null ? null : {'test_otp': value},
          }),
        );
        expect(
          await source.sendOtp('500000001'),
          value == '0042' ? '0042' : null,
        );
      }
    },
  );
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
