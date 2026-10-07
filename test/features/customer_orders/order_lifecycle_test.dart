import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_orders/data/data_sources/order_lifecycle_remote_data_source.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/data/repositories/api_order_lifecycle_repository.dart';
import 'package:octogear/features/customer_orders/domain/entities/customer_order.dart';
import 'package:octogear/features/customer_orders/domain/repositories/order_lifecycle_repository.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/order_lifecycle_controller.dart';

import 'order_fixtures.dart';

Map<String, Object?> lifecycleJson({
  String status = 'awaiting_payment',
  bool payment = false,
}) => orderJson(id: 17, general: true)
  ..addAll({
    'status': status,
    'part_name': 'Front headlight',
    'accepted_offer_id': 42,
    'offered_price': 12550,
    'can_cancel': ['pending', 'awaiting_payment'].contains(status) && !payment,
    'can_confirm_received': status == 'paid',
    'accepted_store': {
      'id': 6,
      'name': 'Parts store',
      'employee_name': 'Ahmed',
      'url_location': 'https://maps.google.com/?q=Riyadh',
    },
    if (payment)
      'payment_summary': {
        'id': 8,
        'order_id': 17,
        'amount': 12550,
        'payment_status': 'paid',
        'payment_method': 'credit_card',
        'created_at': '2026-10-06T09:00:00Z',
      },
  });

class FakeOrderLifecycle implements OrderLifecycleRepository {
  final actions = <OrderLifecycleAction>[];
  Future<void> Function(OrderLifecycleAction)? onWrite;
  @override
  Future<void> submit(int orderId, OrderLifecycleAction action) async {
    actions.add(action);
    await onWrite?.call(action);
  }
}

class LifecycleEnglish extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

void main() {
  test(
    'lifecycle API authenticates and validates the exact order and status',
    () async {
      final calls = <RequestOptions>[];
      var invalid = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'token',
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
                  'data': {
                    'id': invalid ? 99 : 17,
                    'status': options.path.endsWith('/cancel')
                        ? 'cancelled'
                        : 'completed',
                  },
                },
              ),
            );
          },
        ),
      );
      final repo = ApiOrderLifecycleRepository(
        OrderLifecycleRemoteDataSource(api),
      );
      await repo.submit(17, OrderLifecycleAction.cancel);
      await repo.submit(17, OrderLifecycleAction.received);
      expect(calls.map((r) => r.path), [
        'customer/orders/17/cancel',
        'customer/orders/17/received',
      ]);
      expect(
        calls.every((r) => r.headers['Authorization'] == 'Bearer token'),
        isTrue,
      );
      invalid = true;
      await expectLater(
        repo.submit(17, OrderLifecycleAction.cancel),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test('permissions fail closed and payment history checks owning order', () {
    final json = lifecycleJson(status: 'completed', payment: true)
      ..['can_cancel'] = true
      ..['can_confirm_received'] = true;
    final order = CustomerOrderDto.fromJson(json).value;
    expect(order.canCancel, isFalse);
    expect(order.canConfirmReceived, isFalse);
    expect(order.payment!.amount, 12550);
    expect(order.acceptedStore!.employeeName, 'Ahmed');
    (json['payment_summary'] as Map)['order_id'] = 99;
    expect(() => CustomerOrderDto.fromJson(json), throwsFormatException);
    final oldApi = CustomerOrderDto.fromJson(orderJson()).value;
    expect(oldApi.canCancel, isFalse);
    expect(oldApi.canConfirmReceived, isFalse);
  });

  for (final action in OrderLifecycleAction.values) {
    test(
      '$action blocks duplicate taps, reconciles an uncertain successful write',
      () async {
        var json = lifecycleJson(
          status: action == OrderLifecycleAction.cancel
              ? 'awaiting_payment'
              : 'paid',
        );
        final displayed = CustomerOrderDto.fromJson(json).value;
        final orders = FakeOrdersRepository()
          ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
        final gate = Completer<void>();
        final actions = FakeOrderLifecycle()
          ..onWrite = (_) async {
            await gate.future;
            json = lifecycleJson(
              status: action == OrderLifecycleAction.cancel
                  ? 'cancelled'
                  : 'completed',
            );
            throw const ApiFailure(type: ApiFailureType.timeout);
          };
        final container = ProviderContainer(
          overrides: [
            customerOrdersRepositoryProvider.overrideWithValue(orders),
            orderLifecycleRepositoryProvider.overrideWithValue(actions),
            appLocaleProvider.overrideWith(LifecycleEnglish.new),
          ],
        );
        addTearDown(container.dispose);
        container.listen(orderLifecycleProvider(17), (_, _) {});
        final controller = container.read(orderLifecycleProvider(17).notifier);
        final first = controller.submit(displayed, action);
        await Future<void>.delayed(Duration.zero);
        expect(await controller.submit(displayed, action), isFalse);
        gate.complete();
        expect(await first, isFalse);
        expect(container.read(orderLifecycleProvider(17)).needsRefresh, isTrue);
        expect(await controller.submit(displayed, action), isFalse);
        await controller.refresh();
        expect(
          container.read(orderLifecycleProvider(17)).needsRefresh,
          isFalse,
        );
        final reconciled = await container.read(
          customerOrderProvider(17).future,
        );
        expect(
          reconciled.status,
          action == OrderLifecycleAction.cancel
              ? CustomerOrderStatus.cancelled
              : CustomerOrderStatus.completed,
        );
        expect(actions.actions, [action]);
      },
    );
  }

  test('a changed selected offer stops cancellation before a write', () async {
    final displayed = CustomerOrderDto.fromJson(lifecycleJson()).value;
    final orders = FakeOrdersRepository()
      ..onGet = (_) async => CustomerOrderDto.fromJson(
        lifecycleJson()..['accepted_offer_id'] = 999,
      ).value;
    final actions = FakeOrderLifecycle();
    final container = ProviderContainer(
      overrides: [
        customerOrdersRepositoryProvider.overrideWithValue(orders),
        orderLifecycleRepositoryProvider.overrideWithValue(actions),
      ],
    );
    addTearDown(container.dispose);
    container.listen(orderLifecycleProvider(17), (_, _) {});
    expect(
      await container
          .read(orderLifecycleProvider(17).notifier)
          .submit(displayed, OrderLifecycleAction.cancel),
      isFalse,
    );
    expect(actions.actions, isEmpty);
    expect(container.read(orderLifecycleProvider(17)).error!.statusCode, 409);
  });
}
