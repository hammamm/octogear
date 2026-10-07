import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_orders/data/data_sources/customer_orders_remote_data_source.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/data/repositories/customer_orders_repository_impl.dart';
import 'package:octogear/features/customer_orders/domain/entities/customer_order.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'order_fixtures.dart';

void main() {
  test(
    'general requests parse snapshots and retained offer photos without quantity',
    () {
      for (final status in ['awaiting_payment', 'paid', 'completed']) {
        final json = orderJson(general: true)
          ..['status'] = status
          ..['component_name'] = 'All mirrors'
          ..['accepted_offer_id'] = 7
          ..['offered_price'] = 30000
          ..['offers_count'] = 2
          ..['images'] = [
            {'id': 1, 'url': '/api/media/orders/1/images/1'},
            {'id': 2, 'url': '/api/media/orders/1/images/2'},
          ]
          ..['offers'] = [
            {
              'id': 7,
              'price': 30000,
              'status': 'accepted',
              'notes': 'Complete set',
              'images': [
                {'id': 3, 'url': '/api/media/offers/7/images/3'},
                {'id': 4, 'url': '/api/media/offers/7/images/4'},
              ],
            },
            {'id': 8, 'price': 35000, 'status': 'not_selected', 'images': []},
          ];
        expect(json.containsKey('quantity'), isFalse);
        final order = CustomerOrderDto.fromJson(json).value;
        expect(order.quantity, isNull);
        expect(order.displayTotal, 30000);
        expect(order.partName, 'All mirrors');
        expect(order.acceptedOfferId, 7);
        expect(order.manufacturingYear, 2020);
        expect(order.transmissionType, 'automatic');
        expect(order.colorName, 'White');
        expect(order.fuelTypeName, 'Petrol');
        expect(order.imagePaths, hasLength(2));
        expect(order.offers.first.imagePaths, hasLength(2));
        expect(order.offers.last.status, CustomerOfferStatus.notSelected);
        expect(order.status, isNot(CustomerOrderStatus.unknown));
        final offers = json['offers'] as List;
        (offers.first as Map)['images'] = [
          {'id': 3, 'url': '/api/media/offers/8/images/3'},
        ];
        expect(() => CustomerOrderDto.fromJson(json), throwsFormatException);
      }
    },
  );
  test(
    'specific prices use the saved price, then actual payment; general without selection has no total',
    () {
      expect(fixtureOrder().displayTotal, 30000);
      expect(fixtureOrder(general: true).displayTotal, isNull);
      final json = orderJson()..['paid_amount'] = 24000;
      expect(CustomerOrderDto.fromJson(json).value.displayTotal, 24000);
      json['paid_amount'] = null;
      json['requested_unit_price'] = null;
      expect(CustomerOrderDto.fromJson(json).value.displayTotal, 50000);
      final general = orderJson(general: true)
        ..['offered_price'] = 12345
        ..['accepted_store'] = {'id': 14, 'name': 'Selected store'};
      expect(CustomerOrderDto.fromJson(general).value.displayTotal, 12345);
    },
  );
  test(
    'removed references and unknown statuses stay readable; unsafe photos and amounts fail safely',
    () {
      final json = orderJson()
        ..['store_car_component'] = null
        ..['status'] = 'future_status';
      final order = CustomerOrderDto.fromJson(json).value;
      expect(order.store, isNull);
      expect(order.status, CustomerOrderStatus.unknown);
      expect(order.displayTotal, 30000);
      for (final change in [
        {
          'images': [
            {'id': 1, 'url': 'https://untrusted.test/image'},
          ],
        },
        {
          'images': [
            {'id': 1, 'url': '/api/media/orders/2/images/1'},
          ],
        },
        {'price_scale': 1},
        {'currency': 'USD'},
        {'paid_amount': -1},
        {'quantity': 0},
      ]) {
        expect(
          () => CustomerOrderDto.fromJson({...orderJson(), ...change}),
          throwsFormatException,
        );
      }
      expect(
        CustomerOrderDto.fromJson({
          ...orderJson(),
          'images': [
            {'id': 1, 'url': '/api/media/orders/1/images/1'},
          ],
        }).value.imagePaths.single,
        '/api/media/orders/1/images/1',
      );
    },
  );
  test(
    'uses authenticated localized paginated endpoints and server type filtering',
    () async {
      final requests = <RequestOptions>[];
      final remote = _remote((options) {
        requests.add(options);
        return options.path.endsWith('/2')
            ? {'success': true, 'data': orderJson(id: 2, general: true)}
            : {
                'success': true,
                'data': [orderJson(id: 2, general: true)],
                'meta': {
                  'current_page': 2,
                  'last_page': 2,
                  'per_page': 15,
                  'total': 16,
                },
              };
      });
      final repository = CustomerOrdersRepositoryImpl(remote);
      expect(
        (await repository.list(
          filter: CustomerOrderFilter.general,
          page: 2,
        )).orders.single.isGeneral,
        isTrue,
      );
      await repository.get(2);
      expect(requests.first.uri.path, '/api/customer/orders');
      expect(requests.first.queryParameters, {
        'order_type': 'general',
        'page': 2,
      });
      expect(requests.last.uri.path, '/api/customer/orders/2');
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      expect(requests.last.headers['Accept-Language'], 'ar');
    },
  );
  test(
    'wrong detail ID or unfiltered/missing pagination responses are rejected',
    () async {
      final wrongId = _remote(
        (_) => {'success': true, 'data': orderJson(id: 3)},
      );
      await expectLater(wrongId.get(2), throwsA(isA<ApiFailure>()));
      final missingPage = _remote((_) => {'success': true, 'data': []});
      await expectLater(
        missingPage.list(CustomerOrderFilter.all, 1),
        throwsA(isA<ApiFailure>()),
      );
      final wrongType = _remote(
        (_) => {
          'success': true,
          'data': [orderJson()],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 15,
            'total': 1,
          },
        },
      );
      await expectLater(
        wrongType.list(CustomerOrderFilter.general, 1),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
  test(
    'pagination preserves results on failure, ignores double loads and deduplicates next page',
    () async {
      final next = Completer<CustomerOrdersPage>();
      final repo = FakeOrdersRepository()
        ..onList = (_, page) async => page == 1
            ? ordersPage([fixtureOrder()], last: 2, total: 3)
            : next.future;
      final container = _container(repo);
      await container.read(
        customerOrdersProvider(CustomerOrderFilter.all).future,
      );
      final notifier = container.read(
        customerOrdersProvider(CustomerOrderFilter.all).notifier,
      );
      final pending = notifier.loadMore();
      await notifier.loadMore();
      expect(repo.calls.length, 2);
      next.completeError(const ApiFailure(type: ApiFailureType.noConnection));
      await pending;
      expect(
        container
            .read(customerOrdersProvider(CustomerOrderFilter.all))
            .requireValue
            .page
            .orders
            .length,
        1,
      );
      expect(
        container
            .read(customerOrdersProvider(CustomerOrderFilter.all))
            .requireValue
            .nextPageError,
        isNotNull,
      );
      repo.onList = (_, page) async => ordersPage(
        [fixtureOrder(), fixtureOrder(id: 2, general: true)],
        page: page,
        last: 2,
        total: 2,
      );
      await notifier.loadMore();
      expect(
        container
            .read(customerOrdersProvider(CustomerOrderFilter.all))
            .requireValue
            .page
            .orders
            .map((o) => o.id),
        [1, 2],
      );
    },
  );
  test('locale refresh discards stale pagination completion', () async {
    final next = Completer<CustomerOrdersPage>();
    final repo = FakeOrdersRepository()
      ..onList = (_, page) async =>
          page == 1 ? ordersPage([fixtureOrder()], last: 2) : next.future;
    final container = _container(repo);
    await container.read(
      customerOrdersProvider(CustomerOrderFilter.all).future,
    );
    final pending = container
        .read(customerOrdersProvider(CustomerOrderFilter.all).notifier)
        .loadMore();
    repo.onList = (_, _) async => ordersPage([fixtureOrder(id: 9)]);
    await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
    await container.read(
      customerOrdersProvider(CustomerOrderFilter.all).future,
    );
    next.complete(ordersPage([fixtureOrder(id: 2)], page: 2, last: 2));
    await pending;
    expect(
      container
          .read(customerOrdersProvider(CustomerOrderFilter.all))
          .requireValue
          .page
          .orders
          .single
          .id,
      9,
    );
  });
}

ProviderContainer _container(FakeOrdersRepository repo) {
  final container = ProviderContainer(
    overrides: [
      customerOrdersRepositoryProvider.overrideWithValue(repo),
      appLocaleProvider.overrideWith(_Locale.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(customerOrdersProvider(CustomerOrderFilter.all), (_, _) {});
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

CustomerOrdersRemoteDataSource _remote(
  Map<String, Object?> Function(RequestOptions) response,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
  final api = ApiClient(
    dio: dio,
    accessTokenResolver: () => 'test-token',
    localeResolver: () => 'ar',
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return CustomerOrdersRemoteDataSource(api);
}
