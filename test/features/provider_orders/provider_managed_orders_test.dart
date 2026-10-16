import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_orders/data/data_sources/provider_managed_orders_remote_data_source.dart';
import 'package:octogear/features/provider_orders/data/models/provider_managed_order_dto.dart';
import 'package:octogear/features/provider_orders/domain/entities/provider_managed_order.dart';
import 'package:octogear/features/provider_orders/presentation/controllers/provider_managed_orders_providers.dart';
import '../provider_stores/provider_stores_fixtures.dart';
import 'provider_managed_orders_fixtures.dart';

void main() {
  Future<ProviderContainer> setup(FakeManagedOrders repository) async {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(StoreSession.new),
        appLocaleProvider.overrideWith(StoreLocale.new),
        providerManagedOrdersRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    return container;
  }

  test(
    'order decoding fails closed for unknown statuses and rejects unsafe media and money',
    () {
      expect(
        ProviderManagedOrderDto.fromJson(managedOrderJson()).value.canAccept,
        isTrue,
      );
      final unknown = ProviderManagedOrderDto.fromJson(
        managedOrderJson(status: 'future'),
      ).value;
      expect(unknown.canAccept, isFalse);
      expect(unknown.canReject, isFalse);
      for (final changes in [
        {'total_amount': null},
        {'currency': 'USD'},
        {'total_amount': 1},
        {'commission': 100, 'net_amount': 2},
        {
          'images': [
            {'url': 'https://bad.example/photo'},
          ],
        },
        {
          'images': [
            {'url': '/api/media/orders/99/images/1'},
          ],
        },
      ]) {
        expect(
          () => ProviderManagedOrderDto.fromJson({
            ...managedOrderJson(),
            ...changes,
          }),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'remote source preserves auth, filters, expected amount and rejects mismatched receipts',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      addTearDown(dio.close);
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test-token',
        localeResolver: () => 'en',
      );
      final requests = <RequestOptions>[];
      var wrongReceipt = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final list = options.path.endsWith('/specific');
            final data = managedOrderJson(
              status: options.path.endsWith('/accept')
                  ? 'awaiting_payment'
                  : 'pending',
              id: wrongReceipt ? 99 : 31,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': '',
                  'data': list ? [data] : data,
                  if (list)
                    'meta': {
                      'current_page': 1,
                      'last_page': 1,
                      'per_page': 15,
                      'total': 1,
                    },
                },
              ),
            );
          },
        ),
      );
      final remote = ProviderManagedOrdersRemoteDataSource(api);
      await remote.list((kind: ProviderOrderKind.direct, status: 'pending'));
      expect(requests.last.queryParameters, {'page': 1, 'status': 'pending'});
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      await remote.respond(testManagedOrder(), accept: true);
      expect(requests.last.data, {
        'expected_unit_price': 12345,
        'expected_quantity': 2,
      });
      wrongReceipt = true;
      await expectLater(
        remote.respond(testManagedOrder(), accept: true),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        remote.get((kind: ProviderOrderKind.direct, id: 31)),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
  test(
    'double taps are blocked; a timeout is checked without resending',
    () async {
      final repository = FakeManagedOrders()..items = [testManagedOrder()];
      final pending = Completer<ProviderManagedOrder>();
      repository.onRespond = (_, _) => pending.future;
      final container = await setup(repository);
      final provider = providerDirectOrderActionsProvider(31);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final action = container.read(provider.notifier);
      final first = action.respond(repository.items.single, accept: true);
      await action.respond(repository.items.single, accept: true);
      expect(repository.responses.length, 1);
      pending.completeError(const ApiFailure(type: ApiFailureType.timeout));
      await first;
      expect(container.read(provider).uncertain, isTrue);
      repository.items = [testManagedOrder(status: 'awaiting_payment')];
      final checked = await action.check();
      expect(checked?.status, 'awaiting_payment');
      expect(repository.responses.length, 1);
      expect(container.read(provider).uncertain, isFalse);
    },
  );
  test(
    'sign-out discards an in-flight response and clears action state',
    () async {
      final repository = FakeManagedOrders();
      final pending = Completer<ProviderManagedOrder>();
      repository.onRespond = (_, _) => pending.future;
      final container = await setup(repository);
      final provider = providerDirectOrderActionsProvider(31);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final result = container
          .read(provider.notifier)
          .respond(testManagedOrder(), accept: true);
      (container.read(sessionControllerProvider.notifier) as StoreSession)
          .replace(const SignedOutSession());
      pending.complete(testManagedOrder(status: 'awaiting_payment'));
      expect(await result, isNull);
      expect(container.read(provider).busy, isFalse);
    },
  );
  test(
    'pagination deduplicates and ignores stale pages after refresh',
    () async {
      final repository = FakeManagedOrders();
      final latePage = Completer<ProviderManagedOrdersPage>();
      var refreshed = false;
      repository.onList = (_, page) async => page == 2
          ? latePage.future
          : ProviderManagedOrdersPage(
              [testManagedOrder(id: refreshed ? 50 : 31)],
              1,
              2,
              2,
            );
      final container = await setup(repository);
      final provider = providerManagedOrdersProvider((
        kind: ProviderOrderKind.direct,
        status: 'pending',
      ));
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);
      final loading = container.read(provider.notifier).loadMore();
      refreshed = true;
      container.invalidate(provider);
      await container.read(provider.future);
      latePage.complete(
        ProviderManagedOrdersPage([testManagedOrder(id: 32)], 2, 2, 2),
      );
      await loading;
      expect(
        container.read(provider).requireValue.page.items.map((o) => o.id),
        [50],
      );
    },
  );
  test(
    'rejected validation stays editable and paid orders cannot be mutated',
    () async {
      final repository = FakeManagedOrders()
        ..onRespond = (_, _) async =>
            throw const ApiFailure(type: ApiFailureType.badRequest);
      final container = await setup(repository);
      final provider = providerDirectOrderActionsProvider(31);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container
          .read(provider.notifier)
          .respond(testManagedOrder(), accept: true);
      expect(container.read(provider).uncertain, isFalse);
      expect(container.read(provider).error, isA<ApiFailure>());
      expect(
        () => container
            .read(respondToProviderDirectOrderProvider)
            .call(testManagedOrder(status: 'paid'), accept: false),
        throwsStateError,
      );
    },
  );
}
