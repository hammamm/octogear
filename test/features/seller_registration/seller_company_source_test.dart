import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/seller_registration/data/data_sources/seller_company_source.dart';

void main() {
  for (final language in ['en', 'ar']) {
    test(
      '$language loads companies initially, across pages and after clearing search',
      () async {
        final requests = <RequestOptions>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
        final source = SellerCompanySource(
          ApiClient(dio: dio, localeResolver: () => language),
        );
        final name = language == 'ar' ? 'تويوتا' : 'Toyota';
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              requests.add(request);
              // Match Laravel's rejection of an explicitly empty search parameter.
              if (request.queryParameters.containsKey('search') &&
                  request.queryParameters['search'].toString().trim().isEmpty) {
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: request,
                      statusCode: 422,
                      data: {
                        'success': false,
                        'errors': {
                          'search': ['The search field must be a string.'],
                        },
                      },
                    ),
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {'id': 1, 'name': name},
                    ],
                    'meta': {
                      'current_page': request.queryParameters['page'],
                      'last_page': 2,
                      'per_page': 20,
                      'total': 21,
                    },
                  },
                ),
              );
            },
          ),
        );

        final first = await source.fetch('', 1);
        expect(first.items.single.name, name);
        expect(first.hasMore, true);
        expect((await source.fetch('', 2)).hasMore, false);
        expect((await source.fetch('  $name  ', 1)).items.single.id, 1);
        expect((await source.fetch('', 1)).items, hasLength(1));
        expect((await source.fetch('   ', 1)).items, hasLength(1));

        expect(requests.map((r) => r.queryParameters), [
          {'page': 1, 'per_page': 20},
          {'page': 2, 'per_page': 20},
          {'search': name, 'page': 1, 'per_page': 20},
          {'page': 1, 'per_page': 20},
          {'page': 1, 'per_page': 20},
        ]);
        for (final request in requests) {
          expect(request.method, 'GET');
          expect(request.path, 'reference/companies');
          expect(request.headers['Accept-Language'], language);
        }
      },
    );
  }
}
