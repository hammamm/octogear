import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/api/reference_list_loader.dart';

void main() {
  test(
    'loads every reference page with the API maximum and active locale',
    () async {
      final requests = <RequestOptions>[];
      final api = client((request) {
        requests.add(request);
        final page = request.queryParameters['page'] as int;
        return envelope(page, last: 2, values: [page]);
      });
      final values = await loadReferenceList(
        api,
        'reference/companies',
        decode: decode,
      );
      expect(values, [1, 2]);
      expect(requests.map((r) => r.queryParameters), [
        {'page': 1, 'per_page': 50},
        {'page': 2, 'per_page': 50},
      ]);
      expect(
        requests.every((r) => r.headers['Accept-Language'] == 'ar'),
        isTrue,
      );
    },
  );

  test(
    'a failed later page never returns a misleading partial selector',
    () async {
      final api = client((request) {
        if (request.queryParameters['page'] == 2) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        }
        return envelope(1, last: 2, values: [1]);
      });
      await expectLater(
        loadReferenceList(api, 'reference/cities', decode: decode),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test(
    'rejects missing metadata, repeated pages and empty intermediate pages',
    () async {
      for (final response in [
        {
          'success': true,
          'data': [1],
        },
        envelope(2, last: 2, values: [1]),
        envelope(1, last: 2, values: []),
      ]) {
        await expectLater(
          loadReferenceList(
            client((_) => response),
            'reference/companies/1/names',
            decode: decode,
          ),
          throwsA(isA<ApiFailure>()),
        );
      }
    },
  );

  test(
    'fixed reference lists do not require pagination or send page parameters',
    () async {
      final api = client((request) {
        expect(request.queryParameters, isEmpty);
        return {
          'success': true,
          'data': [1, 2],
        };
      });
      expect(
        await loadReferenceList(
          api,
          'reference/colors',
          decode: decode,
          paginated: false,
        ),
        [1, 2],
      );
    },
  );
}

List<int> decode(Object? json) => (json as List).cast<int>();

Map<String, Object?> envelope(
  int page, {
  required int last,
  required List<int> values,
}) => {
  'success': true,
  'data': values,
  'meta': {
    'current_page': page,
    'last_page': last,
    'per_page': 50,
    'total': 51,
  },
};

ApiClient client(Map<String, Object?> Function(RequestOptions) respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
  final api = ApiClient(
    dio: dio,
    accessTokenResolver: () => null,
    localeResolver: () => 'ar',
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        try {
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: respond(request),
            ),
          );
        } on DioException catch (error) {
          handler.reject(error);
        }
      },
    ),
  );
  return api;
}
