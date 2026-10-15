import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_orders/data/data_sources/provider_offers_remote_data_source.dart';
import 'package:octogear/features/provider_orders/data/models/provider_offer_dto.dart';
import 'package:octogear/features/provider_orders/domain/entities/provider_offer.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_offers_providers.dart';
import '../provider_stores/provider_stores_fixtures.dart';
import 'provider_offers_fixtures.dart';

void main() {
  test('money parsing is exact and supports Arabic digits', () {
    expect(providerOfferPrice('123.45'), 12345);
    expect(providerOfferPrice('١٢٣٫٤٥'), 12345);
    expect(providerOfferPrice('۱۲۳.۴۵'), 12345);
    expect(providerOfferPrice('0.01'), 1);
    for (final value in [
      '0',
      '-1',
      '1.001',
      '1e3',
      '1,000',
      '21474836.48',
      '',
    ]) {
      expect(providerOfferPrice(value), isNull);
    }
  });
  test(
    'offer decoder rejects wrong media and fails closed for unknown status',
    () {
      expect(ProviderOfferDto.fromJson(offerJson()).value.canEdit, isTrue);
      expect(
        ProviderOfferDto.fromJson({
          ...offerJson(),
          'status': 'future',
        }).value.canEdit,
        isFalse,
      );
      expect(
        () => ProviderOfferDto.fromJson({
          ...offerJson(),
          'images': [
            {'url': '/api/media/offers/12/images/1'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => ProviderOfferDto.fromJson({...offerJson(), 'order_id': null}),
        throwsFormatException,
      );
    },
  );
  test(
    'multipart create/edit preserve money, auth and explicit photo clearing',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      addTearDown(dio.close);
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test-token',
        localeResolver: () => 'en',
      );
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': offerJson()},
              ),
            );
          },
        ),
      );
      final remote = ProviderOffersRemoteDataSource(api);
      await remote.save(
        ProviderOfferCommand(
          orderId: 1,
          storeId: 1,
          price: 12345,
          notes: 'Available',
        ),
      );
      expect(requests.last.path, 'provider/orders/1/offer');
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      expect(Map.fromEntries((requests.last.data as FormData).fields), {
        'store_id': '1',
        'price': '12345',
        'notes': 'Available',
      });
      await remote.save(
        ProviderOfferCommand(
          orderId: 1,
          offerId: 11,
          storeId: 1,
          price: 12345,
          notes: 'Available',
          photos: [],
        ),
      );
      expect(Map.fromEntries((requests.last.data as FormData).fields), {
        '_method': 'PUT',
        'price': '12345',
        'notes': 'Available',
        'clear_images': '1',
      });
      await expectLater(
        remote.save(
          ProviderOfferCommand(orderId: 2, storeId: 1, price: 12345, notes: ''),
        ),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
  Future<ProviderContainer> setup(FakeOffers repo) async {
    final container = ProviderContainer(
      overrides: [
        providerOffersRepositoryProvider.overrideWithValue(repo),
        sessionControllerProvider.overrideWith(StoreSession.new),
        appLocaleProvider.overrideWith(StoreLocale.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    return container;
  }

  const key = (orderId: 1, offerId: null as int?);
  ProviderOfferCommand command() => ProviderOfferCommand(
    orderId: 1,
    storeId: 1,
    price: 12345,
    notes: 'Available',
  );
  test(
    'double taps are blocked and an ambiguous create is reconciled without resubmission',
    () async {
      final pending = Completer<ProviderOffer>();
      final repo = FakeOffers()..onSave = (_) => pending.future;
      final container = await setup(repo);
      final provider = providerOfferActionsProvider(key);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final action = container.read(provider.notifier);
      final first = action.save(command());
      await action.save(command());
      expect(repo.saves, hasLength(1));
      pending.completeError(const ApiFailure(type: ApiFailureType.timeout));
      await first;
      expect(container.read(provider).uncertain, isTrue);
      await action.save(command());
      expect(repo.saves, hasLength(1));
      repo.items = [testOffer()];
      expect((await action.check())?.id, 11);
      expect(repo.saves, hasLength(1));
    },
  );
  test(
    'validation rejection retains editable state and sign-out suppresses late success',
    () async {
      final repo = FakeOffers()
        ..onSave = (_) async =>
            throw const ApiFailure(type: ApiFailureType.validation);
      final container = await setup(repo);
      final provider = providerOfferActionsProvider(key);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.notifier).save(command());
      expect(container.read(provider).uncertain, isFalse);
      final pending = Completer<ProviderOffer>();
      repo.onSave = (_) => pending.future;
      final result = container.read(provider.notifier).save(command());
      (container.read(sessionControllerProvider.notifier) as StoreSession)
          .replace(const SignedOutSession());
      container.read(provider);
      pending.complete(testOffer());
      expect(await result, isNull);
      expect(container.read(provider).busy, isFalse);
    },
  );
  test('offer list ignores a late next page after refresh', () async {
    final pending = Completer<ProviderOffersPage>();
    final repo = FakeOffers()
      ..onList = (page, _) async => page == 1
          ? ProviderOffersPage([testOffer()], 1, 2, 2)
          : pending.future;
    final container = await setup(repo);
    final sub = container.listen(providerOffersProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(providerOffersProvider.future);
    final more = container.read(providerOffersProvider.notifier).loadMore();
    container.invalidate(providerOffersProvider);
    await container.read(providerOffersProvider.future);
    pending.complete(ProviderOffersPage([testOffer(id: 12)], 2, 2, 2));
    await more;
    expect(
      container.read(providerOffersProvider).requireValue.page.items,
      hasLength(1),
    );
  });
  test(
    'ambiguous edit opens current server state without replay or a permanently locked action',
    () async {
      final repo = FakeOffers()
        ..items = [testOffer()]
        ..onSave = (_) async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      final container = await setup(repo);
      final provider = providerOfferActionsProvider((orderId: 1, offerId: 11));
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final action = container.read(provider.notifier);
      await action.save(
        ProviderOfferCommand(
          orderId: 1,
          offerId: 11,
          storeId: 1,
          price: 20000,
          notes: 'Changed',
        ),
      );
      expect(container.read(provider).uncertain, isTrue);
      // The original write may not have completed: show the observed server value.
      expect((await action.check())?.price, 12345);
      expect(container.read(provider).uncertain, isFalse);
      expect(repo.saves, hasLength(1));
    },
  );
}
