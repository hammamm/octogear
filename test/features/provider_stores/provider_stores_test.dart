import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_stores/data/models/provider_store_dto.dart';
import 'package:octogear/features/provider_stores/data/data_sources/provider_stores_remote_data_source.dart';
import 'package:octogear/features/provider_stores/data/repositories/provider_stores_repository_impl.dart';
import 'package:octogear/features/provider_stores/domain/entities/provider_store.dart';
import 'package:octogear/features/provider_stores/presentation/controllers/provider_stores_providers.dart';
import 'provider_stores_fixtures.dart';

void main() {
  test(
    'owned store request uses shared authentication and localization',
    () async {
      late RequestOptions request;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test-token',
        localeResolver: () => 'ar',
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [_json()],
                },
              ),
            );
          },
        ),
      );
      addTearDown(dio.close);
      final stores = await ProviderStoresRepositoryImpl(
        ProviderStoresRemoteDataSourceImpl(api),
      ).fetchStores();
      expect(request.uri.path, '/api/provider/stores');
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.headers['Accept-Language'], 'ar');
      expect(stores.single.brands, ['Toyota']);
      expect(stores.single.mobile, '+966511111111');
    },
  );

  test('missing optional values and unknown status have honest fallbacks', () {
    final parsed = ProviderStoreDto.fromJson({
      'id': 1,
      'name': 'Store',
      'status': 'paused',
    });
    expect(parsed.status, ProviderStoreStatus.unknown);
    expect(parsed.city, isNull);
    expect(parsed.mobile, isNull);
    expect(parsed.brands, isEmpty);
    expect(
      ProviderStoreDto.fromJson({..._json(), 'status': 'inactive'}).status,
      ProviderStoreStatus.inactive,
    );
    expect(
      () => ProviderStoreDto.fromJson({..._json(), 'id': 0}),
      throwsFormatException,
    );
    expect(
      () => ProviderStoreDto.fromJson({..._json(), 'companies': 'Toyota'}),
      throwsFormatException,
    );
  });

  test(
    'locale changes reload once and sign out discards a pending response',
    () async {
      final repository = FakeStores();
      final container = ProviderContainer(
        overrides: [
          providerStoresRepositoryProvider.overrideWithValue(repository),
          sessionControllerProvider.overrideWith(StoreSession.new),
          appLocaleProvider.overrideWith(StoreLocale.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);
      final subscription = container.listen(providerStoresProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(await container.read(providerStoresProvider.future), [store]);
      expect(repository.calls, 1);
      final pending = Completer<List<ProviderStore>>();
      repository.response = () => pending.future;
      await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
      await container.pump();
      expect(repository.calls, 2);
      (container.read(sessionControllerProvider.notifier) as StoreSession)
          .replace(const SignedOutSession());
      expect(await container.read(providerStoresProvider.future), isEmpty);
      pending.complete([store]);
      await container.pump();
      expect(container.read(providerStoresProvider).requireValue, isEmpty);
      expect(repository.calls, 2);
    },
  );
}

Map<String, dynamic> _json() => {
  'id': 1,
  'name': 'Store',
  'status': 'active',
  'mobile': '+966511111111',
  'city': {'id': 1, 'name': 'Riyadh'},
  'url_location': 'https://maps.example.test/store',
  'companies': [
    {'id': 1, 'name': 'Toyota'},
  ],
};
