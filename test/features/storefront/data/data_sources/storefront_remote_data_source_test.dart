import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/storefront/data/data_sources/storefront_remote_data_source.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_filters.dart';

void main() {
  test(
    'gets one localized, authenticated store page with only supported filters',
    () async {
      late RequestOptions request;
      final dataSource = StorefrontRemoteDataSourceImpl(
        apiClient: _clientThatReturns(
          _storesEnvelope(),
          onRequest: (value) => request = value,
        ),
      );

      final result = await dataSource.fetchStores(
        const StorefrontFilters(query: '  Al Faris  ', cityId: 2, companyId: 9),
        page: 3,
      );

      expect(request.method, 'GET');
      expect(request.uri.path, '/api/stores');
      expect(request.uri.queryParameters, {
        'page': '3',
        'query': 'Al Faris',
        'city_id': '2',
        'company_id': '9',
      });
      expect(_header(request, 'Authorization'), 'Bearer secure-token');
      expect(_header(request, 'Accept-Language'), 'en');
      expect(result.currentPage, 3);
      expect(result.lastPage, 4);
      expect(result.stores.single.nickname, 'Al Faris');
    },
  );

  test('gets localized public city and manufacturer filter options', () async {
    final paths = <String>[];
    final dataSource = StorefrontRemoteDataSourceImpl(
      apiClient: _clientThatReturns(const {
        'success': true,
        'message': 'References loaded',
        'data': [
          {'id': 2, 'name': 'Aden'},
        ],
      }, onRequest: (request) => paths.add(request.uri.path)),
    );

    final cities = await dataSource.fetchCities();
    final companies = await dataSource.fetchCompanies();

    expect(paths, ['/api/reference/cities', '/api/reference/companies']);
    expect(cities.single.name, 'Aden');
    expect(companies.single.id, 2);
  });

  test('gets one authenticated, localized store detail', () async {
    late RequestOptions request;
    final dataSource = StorefrontRemoteDataSourceImpl(
      apiClient: _clientThatReturns(
        _storeDetailEnvelope(),
        onRequest: (value) => request = value,
      ),
    );

    final store = await dataSource.fetchStoreDetails(14);

    expect(request.method, 'GET');
    expect(request.uri.path, '/api/stores/14');
    expect(_header(request, 'Authorization'), 'Bearer secure-token');
    expect(_header(request, 'Accept-Language'), 'en');
    expect(store.companies.single.name, 'Toyota');
    expect(store.pictures.single.url, '/api/media/stores/14/pictures/8');
  });

  test('gets one authenticated page of a store inventory', () async {
    late RequestOptions request;
    final dataSource = StorefrontRemoteDataSourceImpl(
      apiClient: _clientThatReturns(
        _storeCarsEnvelope(),
        onRequest: (value) => request = value,
      ),
    );

    final page = await dataSource.fetchStoreCars(14, page: 2);

    expect(request.method, 'GET');
    expect(request.uri.path, '/api/stores/14/cars');
    expect(request.uri.queryParameters, {'page': '2'});
    expect(_header(request, 'Authorization'), 'Bearer secure-token');
    expect(_header(request, 'Accept-Language'), 'en');
    expect(page.cars.single.carName.name, 'Camry');
    expect(page.cars.single.componentsCount, 7);
  });
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

Map<String, Object?> _storesEnvelope() {
  return {
    'success': true,
    'message': 'Stores loaded',
    'data': [
      {
        'id': 14,
        'name': 'Al Faris Auto Parts',
        'nick_name': 'Al Faris',
        'city': {'id': 2, 'name': 'Aden'},
        'average_rating': 4.5,
        'pictures': [
          {'id': 8, 'url': '/api/media/stores/14/pictures/8'},
        ],
      },
    ],
    'meta': {'current_page': 3, 'last_page': 4, 'per_page': 15, 'total': 48},
  };
}

Map<String, Object?> _storeDetailEnvelope() {
  return {
    'success': true,
    'message': 'Store loaded',
    'data': {
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
    },
  };
}

Map<String, Object?> _storeCarsEnvelope() {
  return {
    'success': true,
    'message': 'Cars loaded',
    'data': [
      {
        'id': 31,
        'manufacturing_year': 2020,
        'car_name': {'id': 7, 'name': 'Camry'},
        'color': {'id': 2, 'name': 'White'},
        'fuel_type': {'id': 1, 'name': 'Petrol'},
        'components_count': 7,
        'pictures': [
          {
            'id': 6,
            'url': '/api/media/stores/14/cars/31/pictures/6',
            'mime_type': 'image/jpeg',
            'size_bytes': 125000,
            'sort_order': 0,
          },
        ],
      },
    ],
    'meta': {'current_page': 2, 'last_page': 3, 'per_page': 15, 'total': 31},
  };
}

Object? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
