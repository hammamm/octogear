import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_orders/data/data_sources/provider_general_requests_remote_data_source.dart';
import 'package:octogear/features/provider_orders/data/models/provider_general_request_dto.dart';
import 'package:octogear/features/provider_orders/data/repositories/provider_general_requests_repository_impl.dart';
import 'package:octogear/features/provider_orders/domain/entities/provider_general_request.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_general_requests_providers.dart';
import '../provider_stores/provider_stores_fixtures.dart';
import 'provider_general_requests_fixtures.dart';

void main() {
  test(
    'transport omits city for all cities and sends selected city, page, token and locale',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      addTearDown(dio.close);
      final repository = ProviderGeneralRequestsRepositoryImpl(
        ProviderGeneralRequestsRemoteDataSource(
          ApiClient(
            dio: dio,
            accessTokenResolver: () => 'test-token',
            localeResolver: () => 'ar',
          ),
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final page = options.queryParameters['page'] as int? ?? 1;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    generalRequestJson(
                      cityId: options.queryParameters['city_id'] as int? ?? 1,
                    ),
                  ],
                  'meta': {
                    'current_page': page,
                    'last_page': 2,
                    'per_page': 15,
                    'total': 16,
                  },
                },
              ),
            );
          },
        ),
      );
      await repository.list();
      final selected = await repository.list(cityId: 2, page: 2);
      expect(requests.first.queryParameters, {'page': 1});
      expect(requests.last.queryParameters, {'page': 2, 'city_id': 2});
      expect(requests.last.uri.path, '/api/provider/orders/general');
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      expect(requests.last.headers['Accept-Language'], 'ar');
      expect(selected.items.single.cityId, 2);
      expect(selected.page, 2);
    },
  );

  test('transport rejects mismatched city, page and detail IDs', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
    addTearDown(dio.close);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': options.path.endsWith('/general')
                  ? [generalRequestJson()]
                  : generalRequestJson(),
              'meta': {
                'current_page': 1,
                'last_page': 2,
                'per_page': 15,
                'total': 16,
              },
            },
          ),
        ),
      ),
    );
    final remote = ProviderGeneralRequestsRemoteDataSource(ApiClient(dio: dio));
    await expectLater(remote.list(cityId: 2), throwsA(isA<ApiFailure>()));
    await expectLater(remote.list(page: 2), throwsA(isA<ApiFailure>()));
    await expectLater(remote.get(2), throwsA(isA<ApiFailure>()));
  });

  test('DTO validates request identity, date and private image ownership', () {
    final json = generalRequestJson();
    expect(
      ProviderGeneralRequestDto.fromJson(json).toEntity().carName,
      'Camry',
    );
    for (final bad in [
      {...json, 'order_type': 'specific'},
      {...json, 'id': 0},
      {...json, 'created_at': 'wrong'},
      {
        ...json,
        'city': {'id': -1},
      },
      {
        ...json,
        'images': [
          {'url': 'https://elsewhere.test/image'},
        ],
      },
      {
        ...json,
        'images': [
          {'url': '/api/media/orders/2/images/1'},
        ],
      },
    ]) {
      expect(
        () => ProviderGeneralRequestDto.fromJson(bad),
        throwsFormatException,
      );
    }
    expect(
      ProviderGeneralRequestDto.fromJson({
        ...json,
        'images': [
          {'url': '/api/media/orders/1/images/1'},
        ],
      }).toEntity().imagePaths,
      ['/api/media/orders/1/images/1'],
    );
    expect(
      ProviderGeneralRequestDto.fromJson({
        ...json,
        'city': null,
        'vehicle_details': null,
      }).toEntity().cityId,
      isNull,
    );
  });

  Future<ProviderContainer> setup(
    FakeGeneralRequests repo,
    MemoryOrderFilterStorage storage,
  ) async {
    final container = ProviderContainer(
      overrides: [
        providerGeneralRequestsRepositoryProvider.overrideWithValue(repo),
        providerOrderFilterStorageProvider.overrideWithValue(storage),
        sessionControllerProvider.overrideWith(StoreSession.new),
        appLocaleProvider.overrideWith(StoreLocale.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    final subscription = container.listen(
      providerGeneralRequestsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(providerGeneralRequestsProvider.future);
    return container;
  }

  test(
    'pagination is deduplicated and an old city page cannot replace a new selection',
    () async {
      final oldPage = Completer<ProviderGeneralRequestsPage>();
      final repo = FakeGeneralRequests()
        ..onList = (city, page) async {
          if (page == 2) return oldPage.future;
          return requestPage(
            [generalRequest(cityId: city ?? 1)],
            lastPage: city == null ? 2 : 1,
            total: city == null ? 2 : 1,
          );
        };
      final storage = MemoryOrderFilterStorage();
      final container = await setup(repo, storage);
      final more = container
          .read(providerGeneralRequestsProvider.notifier)
          .loadMore();
      await container.read(providerGeneralRequestsProvider.notifier).loadMore();
      expect(repo.calls.where((call) => call.$2 == 2), hasLength(1));
      await container.read(providerOrderCityProvider.notifier).select(2);
      expect(
        (await container.read(
          providerGeneralRequestsProvider.future,
        )).page.items.single.cityId,
        2,
      );
      oldPage.complete(
        requestPage([generalRequest(id: 2)], page: 2, lastPage: 2),
      );
      await more;
      expect(
        container
            .read(providerGeneralRequestsProvider)
            .requireValue
            .page
            .items
            .single
            .cityId,
        2,
      );
      expect(storage.values[owner.id], 2);
      await container.read(providerOrderCityProvider.notifier).select(null);
      await container.read(providerGeneralRequestsProvider.future);
      expect(repo.calls.last, (null, 1));
    },
  );

  test(
    'load-more failure preserves data and retries the same page explicitly',
    () async {
      var fails = true;
      final repo = FakeGeneralRequests()
        ..onList = (city, page) async {
          if (page == 2 && fails) {
            throw const ApiFailure(type: ApiFailureType.noConnection);
          }
          return requestPage(
            [generalRequest(), if (page == 2) generalRequest(id: 2)],
            page: page,
            lastPage: 2,
            total: 2,
          );
        };
      final container = await setup(repo, MemoryOrderFilterStorage());
      await container.read(providerGeneralRequestsProvider.notifier).loadMore();
      expect(
        container.read(providerGeneralRequestsProvider).requireValue.page.items,
        hasLength(1),
      );
      expect(
        container
            .read(providerGeneralRequestsProvider)
            .requireValue
            .nextPageError,
        isA<ApiFailure>(),
      );
      fails = false;
      await container.read(providerGeneralRequestsProvider.notifier).loadMore();
      expect(
        container
            .read(providerGeneralRequestsProvider)
            .requireValue
            .page
            .items
            .map((e) => e.id),
        [1, 2],
      );
      expect(repo.calls, [(null, 1), (null, 2), (null, 2)]);
    },
  );

  test(
    'saved filters are account-scoped and locale reload starts at page one',
    () async {
      final repo = FakeGeneralRequests();
      final storage = MemoryOrderFilterStorage()..values[owner.id] = 2;
      final container = await setup(repo, storage);
      expect(repo.calls.single, (2, 1));
      await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
      await container.read(providerGeneralRequestsProvider.future);
      expect(repo.calls.last, (2, 1));
      (container.read(sessionControllerProvider.notifier) as StoreSession)
          .replace(
            const AuthenticatedSession(
              AppUser(
                id: 99,
                fullName: 'Other provider',
                mobile: '+966500000099',
                role: AppUserRole.provider,
              ),
            ),
          );
      await container.read(providerGeneralRequestsProvider.future);
      expect(repo.calls.last, (null, 1));
      expect(container.read(providerOrderCityProvider), isNull);
    },
  );

  test('sign-out hides data and ignores a late page response', () async {
    final pending = Completer<ProviderGeneralRequestsPage>();
    final repo = FakeGeneralRequests()
      ..onList = (city, page) async => page == 2
          ? pending.future
          : requestPage([generalRequest()], lastPage: 2, total: 2);
    final container = await setup(repo, MemoryOrderFilterStorage());
    final more = container
        .read(providerGeneralRequestsProvider.notifier)
        .loadMore();
    (container.read(sessionControllerProvider.notifier) as StoreSession)
        .replace(const SignedOutSession());
    await expectLater(
      container.read(providerGeneralRequestsProvider.future),
      throwsA(isA<ApiFailure>()),
    );
    pending.complete(
      requestPage([generalRequest(id: 2)], page: 2, lastPage: 2),
    );
    await more;
    expect(container.read(providerGeneralRequestsProvider).hasError, isTrue);
  });
}
