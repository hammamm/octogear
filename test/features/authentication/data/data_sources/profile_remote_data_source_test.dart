import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/authentication/data/data_sources/profile_remote_data_source.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';

void main() {
  test(
    'requests the protected shared profile endpoint with current headers',
    () async {
      late RequestOptions request;
      final dataSource = ProfileRemoteDataSourceImpl(
        apiClient: _clientThatReturns(
          _profileEnvelope(),
          onRequest: (value) => request = value,
        ),
      );

      final profile = await dataSource.fetchProfile();

      expect(profile.toEntity().role, AppUserRole.customer);
      expect(request.uri.path, '/api/profile');
      expect(_header(request, 'Authorization'), 'Bearer secure-token');
      expect(_header(request, 'Accept-Language'), 'en');
    },
  );
}

ApiClient _clientThatReturns(
  Map<String, Object?> response, {
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
  final client = ApiClient(
    dio: dio,
    accessTokenResolver: () => 'secure-token',
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

Map<String, Object?> _profileEnvelope() {
  return {
    'success': true,
    'message': 'Profile loaded',
    'data': {
      'id': 7,
      'full_name': 'Amina',
      'mobile': '500000007',
      'type': 'customer',
      'city': {'id': 3, 'name': 'Riyadh'},
    },
  };
}

Object? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
