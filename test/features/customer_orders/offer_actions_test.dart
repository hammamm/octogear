import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_orders/data/data_sources/offer_actions_remote_data_source.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/data/repositories/api_offer_actions_repository.dart';
import 'package:octogear/features/customer_orders/domain/entities/customer_order.dart';
import 'package:octogear/features/customer_orders/domain/repositories/offer_actions_repository.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/offer_action_controller.dart';

import 'order_fixtures.dart';

CustomerOrder actionOrder({
  String status = 'pending',
  String offerStatus = 'pending',
  int price = 12550,
}) => CustomerOrderDto.fromJson(
  orderJson(id: 17, general: true)
    ..['part_name'] = 'Front headlight'
    ..['status'] = status
    ..['accepted_offer_id'] = offerStatus == 'accepted' ? 42 : null
    ..['offers_count'] = 1
    ..['offers'] = [
      {
        'id': 42,
        'price': price,
        'status': offerStatus,
        'images': [],
        'store': {'id': 6, 'name': 'Parts store'},
        'notes': 'Original part, ready to collect',
      },
    ],
).value;

class FakeOfferActions implements OfferActionsRepository {
  int accepts = 0, rejects = 0;
  String? reason;
  Future<void> Function()? onWrite;
  @override
  Future<void> accept({required int orderId, required int offerId}) async {
    accepts++;
    if (onWrite != null) await onWrite!();
  }

  @override
  Future<void> reject({
    required int orderId,
    required int offerId,
    String? reason,
  }) async {
    rejects++;
    this.reason = reason;
    if (onWrite != null) await onWrite!();
  }
}

void main() {
  test(
    'actions use authenticated endpoints, optional reason and verified receipts',
    () async {
      final calls = <RequestOptions>[];
      var invalid = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test-token',
        localeResolver: () => 'ar',
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': invalid
                      ? {'id': 99, 'status': 'rejected'}
                      : options.path.endsWith('accept-offer')
                      ? {
                          'id': 17,
                          'accepted_offer_id': 42,
                          'status': 'awaiting_payment',
                        }
                      : {'id': 42, 'status': 'rejected'},
                },
              ),
            );
          },
        ),
      );
      final repo = ApiOfferActionsRepository(OfferActionsRemoteDataSource(api));
      await repo.accept(orderId: 17, offerId: 42);
      await repo.reject(orderId: 17, offerId: 42);
      await repo.reject(orderId: 17, offerId: 42, reason: '  Price  ');
      expect(calls.map((item) => item.method), everyElement('POST'));
      expect(calls.first.path, 'customer/orders/17/accept-offer');
      expect(calls.first.data, {'offer_id': 42});
      expect(calls[1].path, 'customer/orders/17/offers/42/reject');
      expect(calls[1].data, isEmpty);
      expect(calls[2].data, {'rejection_reason': 'Price'});
      expect(
        calls.every(
          (item) =>
              item.headers['Authorization'] == 'Bearer test-token' &&
              item.headers['Accept-Language'] == 'ar',
        ),
        isTrue,
      );
      invalid = true;
      await expectLater(
        repo.reject(orderId: 17, offerId: 42),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        repo.accept(orderId: 17, offerId: 42),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test(
    'duplicate taps send one write and success invalidates shared order data',
    () async {
      final pending = Completer<void>();
      final actions = FakeOfferActions()..onWrite = () => pending.future;
      final repo = FakeOrdersRepository()..onGet = (_) async => actionOrder();
      final container = ProviderContainer(
        overrides: [
          appLocaleProvider.overrideWith(_Locale.new),
          customerOrdersRepositoryProvider.overrideWithValue(repo),
          offerActionsRepositoryProvider.overrideWithValue(actions),
        ],
      );
      addTearDown(container.dispose);
      container.listen(offerActionProvider(17), (_, _) {});
      container.listen(customerOrderProvider(17), (_, _) {});
      await container.read(customerOrderProvider(17).future);
      final controller = container.read(offerActionProvider(17).notifier);
      final first = controller.submit(
        offer: actionOrder().offers.single,
        accept: true,
      );
      final second = await controller.submit(
        offer: actionOrder().offers.single,
        accept: true,
      );
      expect(second, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(actions.accepts, 1);
      repo.onGet = (_) async =>
          actionOrder(status: 'awaiting_payment', offerStatus: 'accepted');
      pending.complete();
      expect(await first, isTrue);
      expect(
        container.read(offerActionProvider(17)).result,
        OfferActionResult.accepted,
      );
      expect(
        (await container.read(
          customerOrderProvider(17).future,
        )).acceptedOfferId,
        42,
      );
    },
  );

  test('changed price or ineligible offer never writes', () async {
    for (final fresh in [
      actionOrder(price: 20000),
      actionOrder(offerStatus: 'rejected'),
      actionOrder(status: 'completed'),
    ]) {
      final actions = FakeOfferActions();
      final container = ProviderContainer(
        overrides: [
          appLocaleProvider.overrideWith(_Locale.new),
          customerOrdersRepositoryProvider.overrideWithValue(
            FakeOrdersRepository()..onGet = (_) async => fresh,
          ),
          offerActionsRepositoryProvider.overrideWithValue(actions),
        ],
      );
      container.listen(offerActionProvider(17), (_, _) {});
      expect(
        await container
            .read(offerActionProvider(17).notifier)
            .submit(offer: actionOrder().offers.single, accept: true),
        isFalse,
      );
      expect(actions.accepts, 0);
      expect(container.read(offerActionProvider(17)).needsRefresh, isTrue);
      container.dispose();
    }
  });

  test(
    'uncertain refusal locks further writes until explicit status refresh',
    () async {
      final actions = FakeOfferActions()
        ..onWrite = () async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      final repo = FakeOrdersRepository()..onGet = (_) async => actionOrder();
      final container = ProviderContainer(
        overrides: [
          appLocaleProvider.overrideWith(_Locale.new),
          customerOrdersRepositoryProvider.overrideWithValue(repo),
          offerActionsRepositoryProvider.overrideWithValue(actions),
        ],
      );
      addTearDown(container.dispose);
      container.listen(offerActionProvider(17), (_, _) {});
      final controller = container.read(offerActionProvider(17).notifier);
      await controller.submit(
        offer: actionOrder().offers.single,
        accept: false,
        reason: 'Not suitable',
      );
      expect(actions.reason, 'Not suitable');
      expect(container.read(offerActionProvider(17)).needsRefresh, isTrue);
      await controller.submit(offer: actionOrder().offers.single, accept: true);
      expect(actions.accepts, 0);
      expect(actions.rejects, 1);
      repo.onGet = (_) async => actionOrder(offerStatus: 'rejected');
      await controller.refresh();
      expect(container.read(offerActionProvider(17)).needsRefresh, isFalse);
      expect(
        await controller.submit(
          offer: actionOrder().offers.single,
          accept: false,
        ),
        isFalse,
      );
      expect(actions.rejects, 1);
    },
  );
}

class _Locale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}
