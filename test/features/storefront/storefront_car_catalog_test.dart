import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/storefront/data/data_sources/storefront_car_catalog_remote_data_source.dart';
import 'package:octogear/features/storefront/data/models/storefront_car_catalog_dto.dart';
import 'package:octogear/features/storefront/data/repositories/storefront_car_catalog_repository_impl.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_car_catalog.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_car_catalog_providers.dart';

import 'support/car_catalog_fixtures.dart';

void main() {
  test('decodes car context, report, money and optional component fields', () {
    final car = StorefrontCarDetailsDto.fromJson(
      catalogCarJson(),
      catalogKey,
    ).toEntity();
    expect(car.sections.single.condition, StorefrontSectionCondition.damaged);
    expect(car.company!.name, 'Toyota');
    final part = StorefrontCarComponentDto.fromJson(
      catalogPartJson(),
    ).toEntity();
    expect(part.priceMinor / part.priceScale, 520.25);
    expect(part.inStock, isFalse);
    expect(part.warrantyMonths, isNull);
    expect(part.description, isNull);
  });

  test('rejects wrong nested IDs, untrusted media and invalid money', () {
    expect(
      () => StorefrontCarDetailsDto.fromJson(catalogCarJson(), (
        storeId: 14,
        carId: 8,
      )),
      throwsFormatException,
    );
    final json = catalogCarJson()
      ..['pictures'] = [
        {
          'id': 1,
          'url': 'https://foreign.test/picture',
          'mime_type': 'image/png',
          'size_bytes': 12,
          'sort_order': 0,
        },
      ];
    expect(
      () => StorefrontCarDetailsDto.fromJson(json, catalogKey),
      throwsFormatException,
    );
    for (final change in [
      {'price': -1},
      {'price': 12.5},
      {'currency': 'USD'},
      {'price_scale': 1},
      {'stock_quantity': -1},
    ]) {
      expect(
        () => StorefrontCarComponentDto.fromJson({
          ...catalogPartJson(),
          ...change,
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'unknown condition stays unknown and blank optional text is omitted',
    () {
      final json = catalogCarJson()
        ..['sections'] = [
          {'section_id': 1, 'name': 'Engine', 'condition': 'uninspected'},
        ];
      expect(
        StorefrontCarDetailsDto.fromJson(
          json,
          catalogKey,
        ).toEntity().sections.single.condition,
        StorefrontSectionCondition.unknown,
      );
      expect(
        StorefrontCarComponentDto.fromJson({
          ...catalogPartJson(),
          'part_number': '  ',
        }).toEntity().partNumber,
        isNull,
      );
    },
  );

  test(
    'uses authenticated localized nested endpoints and requested pagination',
    () async {
      final requests = <RequestOptions>[];
      final remote = _remote((options) {
        requests.add(options);
        return options.path.endsWith('/components')
            ? {
                'success': true,
                'data': [catalogPartJson()],
                'meta': {
                  'current_page': 2,
                  'last_page': 2,
                  'per_page': 15,
                  'total': 16,
                },
              }
            : {'success': true, 'data': catalogCarJson()};
      });
      final repository = StorefrontCarCatalogRepositoryImpl(remote);
      await repository.getCarDetails(catalogKey);
      final page = await repository.getComponents(catalogKey, page: 2);
      expect(requests[0].uri.path, '/api/stores/14/cars/7');
      expect(requests[1].uri.path, '/api/stores/14/cars/7/components');
      expect(requests[1].queryParameters, {'page': 2});
      expect(requests[1].headers['Authorization'], 'Bearer test-token');
      expect(requests[1].headers['Accept-Language'], 'ar');
      expect(page.currentPage, 2);
      expect(page.components.single.priceMinor, 52025);
    },
  );

  test(
    'missing pagination and unexpected schema become safe failures',
    () async {
      final repository = StorefrontCarCatalogRepositoryImpl(
        _remote((_) => {'success': true, 'data': []}),
      );
      await expectLater(
        repository.getComponents(catalogKey, page: 1),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        repository.getCarDetails(catalogKey),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test(
    'pagination prevents duplicates, retains first page on failure and retries explicitly',
    () async {
      final repository = FakeCarCatalogRepository();
      final second = Completer<StorefrontComponentsPage>();
      repository.components = (_, page) async =>
          page == 1 ? catalogPage(1) : second.future;
      final container = _container(repository);
      await container.read(storefrontCarComponentsProvider(catalogKey).future);
      final controller = container.read(
        storefrontCarComponentsProvider(catalogKey).notifier,
      );
      final pending = controller.loadNextPage();
      await controller.loadNextPage();
      expect(repository.calls.length, 2);
      second.completeError(const ApiFailure(type: ApiFailureType.noConnection));
      await pending;
      expect(
        container
            .read(storefrontCarComponentsProvider(catalogKey))
            .requireValue
            .page
            .components
            .single
            .id,
        1,
      );
      expect(
        container
            .read(storefrontCarComponentsProvider(catalogKey))
            .requireValue
            .nextPageError,
        isA<ApiFailure>(),
      );
      repository.components = (_, page) async => catalogPage(
        page,
        last: true,
        parts: [catalogPart(1), catalogPart(2)],
      );
      await controller.loadNextPage();
      await controller.loadNextPage();
      final state = container
          .read(storefrontCarComponentsProvider(catalogKey))
          .requireValue;
      expect(state.page.components.map((part) => part.id), [1, 2]);
      expect(state.nextPageError, isNull);
      expect(repository.calls.length, 3);
    },
  );

  test('locale reload discards an in-flight older page', () async {
    final repository = FakeCarCatalogRepository();
    final pendingPage = Completer<StorefrontComponentsPage>();
    repository.components = (_, page) async =>
        page == 1 ? catalogPage(1) : pendingPage.future;
    final container = _container(repository);
    await container.read(storefrontCarComponentsProvider(catalogKey).future);
    final pending = container
        .read(storefrontCarComponentsProvider(catalogKey).notifier)
        .loadNextPage();
    repository.components = (_, page) async =>
        catalogPage(1, last: true, parts: [catalogPart(9)]);
    await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
    await container.read(storefrontCarComponentsProvider(catalogKey).future);
    pendingPage.complete(catalogPage(2, last: true));
    await pending;
    expect(
      container
          .read(storefrontCarComponentsProvider(catalogKey))
          .requireValue
          .page
          .components
          .single
          .id,
      9,
    );
  });

  test('disposal safely ignores pending page completion', () async {
    final repository = FakeCarCatalogRepository();
    final pendingPage = Completer<StorefrontComponentsPage>();
    repository.components = (_, page) async =>
        page == 1 ? catalogPage(1) : pendingPage.future;
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(_Locale.new),
        storefrontCarCatalogRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(storefrontCarComponentsProvider(catalogKey), (_, _) {});
    await container.read(storefrontCarComponentsProvider(catalogKey).future);
    final pending = container
        .read(storefrontCarComponentsProvider(catalogKey).notifier)
        .loadNextPage();
    container.dispose();
    pendingPage.complete(catalogPage(2, last: true));
    await pending;
  });

  test(
    'initial failure has no automatic retry and manual refresh recovers',
    () async {
      final repository = FakeCarCatalogRepository()
        ..components = (_, _) async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      final container = _container(repository);
      await expectLater(
        container.read(storefrontCarComponentsProvider(catalogKey).future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.calls.length, 1);
      repository.components = (_, _) async =>
          catalogPage(1, last: true, parts: []);
      final state = await container.refresh(
        storefrontCarComponentsProvider(catalogKey).future,
      );
      expect(state.page.components, isEmpty);
    },
  );
}

ProviderContainer _container(FakeCarCatalogRepository repository) {
  final container = ProviderContainer(
    overrides: [
      appLocaleProvider.overrideWith(_Locale.new),
      storefrontCarCatalogRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  container.listen(storefrontCarComponentsProvider(catalogKey), (_, _) {});
  return container;
}

class _Locale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
  @override
  Future<void> select(AppLocale locale) async {
    state = locale;
  }
}

StorefrontCarCatalogRemoteDataSource _remote(
  Map<String, Object?> Function(RequestOptions) response,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
  final client = ApiClient(
    dio: dio,
    accessTokenResolver: () => 'test-token',
    localeResolver: () => 'ar',
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Object?>(
          data: response(options),
          requestOptions: options,
          statusCode: 200,
        ),
      ),
    ),
  );
  return StorefrontCarCatalogRemoteDataSource(client);
}
