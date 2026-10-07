import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_orders/data/data_sources/order_management_remote_data_source.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/data/repositories/api_order_management_repository.dart';
import 'package:octogear/features/customer_orders/domain/entities/order_changes.dart';
import 'package:octogear/features/customer_orders/domain/repositories/order_management_repository.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/order_management_controller.dart';

import 'order_fixtures.dart';

final managementToken = 'a' * 64;
Map<String, Object?> managementJson({
  bool general = true,
  bool editable = true,
}) => orderJson(id: 17, general: general)
  ..['can_edit'] = editable
  ..['can_delete'] = true
  ..['edit_token'] = managementToken
  ..['part_name'] = 'Front headlight';

class FakeOrderManagement implements OrderManagementRepository {
  int updates = 0, deletes = 0;
  OrderChanges? changes;
  Future<void> Function()? onWrite;
  @override
  Future<void> update(int orderId, String token, OrderChanges changes) async {
    updates++;
    this.changes = changes;
    await onWrite?.call();
  }

  @override
  Future<void> delete(int orderId, String token) async {
    deletes++;
    await onWrite?.call();
  }
}

void main() {
  test(
    'authenticated PATCH and DELETE carry revision and verify receipts',
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
                  'data': {
                    'id': invalid ? 99 : 17,
                    'edit_token': managementToken,
                    'deleted': true,
                  },
                },
              ),
            );
          },
        ),
      );
      final repo = ApiOrderManagementRepository(
        OrderManagementRemoteDataSource(api),
      );
      await repo.update(
        17,
        managementToken,
        const OrderChanges(description: 'Left side'),
      );
      await repo.delete(17, managementToken);
      expect(calls.map((call) => call.method), ['PATCH', 'DELETE']);
      expect(calls.first.data, {
        'description': 'Left side',
        'edit_token': managementToken,
      });
      expect(calls.last.data, {'edit_token': managementToken});
      expect(
        calls.every(
          (call) =>
              call.path == 'customer/orders/17' &&
              call.headers['Authorization'] == 'Bearer test-token' &&
              call.headers['Accept-Language'] == 'ar',
        ),
        true,
      );
      invalid = true;
      await expectLater(
        repo.delete(17, managementToken),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        repo.update(17, managementToken, const OrderChanges()),
        throwsA(isA<ApiFailure>()),
      );
    },
  );

  test('older API responses do not enable unsupported management actions', () {
    final order = CustomerOrderDto.fromJson(orderJson()).value;
    expect(order.canEdit, false);
    expect(order.canDelete, false);
  });

  test('duplicate taps send one mutation', () async {
    final gate = Completer<void>();
    final repo = FakeOrderManagement()..onWrite = () => gate.future;
    final container = ProviderContainer(
      overrides: [orderManagementRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(orderManagementProvider(17), (_, _) {});
    final controller = container.read(orderManagementProvider(17).notifier);
    final order = CustomerOrderDto.fromJson(managementJson()).value;
    final first = controller.submit(order);
    expect(await controller.submit(order), false);
    expect(repo.deletes, 1);
    gate.complete();
    expect(await first, true);
    expect(container.read(orderManagementProvider(17)).deleted, true);
  });

  test(
    'uncertain deletion requires explicit read and reconciles a 404',
    () async {
      final repo = FakeOrderManagement()
        ..onWrite = () async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      final orders = FakeOrdersRepository()
        ..onGet = (_) async => throw const ApiFailure(
          type: ApiFailureType.notFound,
          statusCode: 404,
        );
      final container = ProviderContainer(
        overrides: [
          orderManagementRepositoryProvider.overrideWithValue(repo),
          customerOrdersRepositoryProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      container.listen(orderManagementProvider(17), (_, _) {});
      final controller = container.read(orderManagementProvider(17).notifier);
      final order = CustomerOrderDto.fromJson(managementJson()).value;
      expect(await controller.submit(order), false);
      expect(container.read(orderManagementProvider(17)).needsRefresh, true);
      expect(await controller.submit(order), false);
      expect(repo.deletes, 1);
      await controller.refresh();
      expect(container.read(orderManagementProvider(17)).deleted, true);
    },
  );

  test(
    'validation retains editable draft; conflict blocks another save',
    () async {
      final repo = FakeOrderManagement()
        ..onWrite = () async => throw const ApiFailure(
          type: ApiFailureType.validation,
          statusCode: 422,
        );
      final container = ProviderContainer(
        overrides: [orderManagementRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(orderManagementProvider(17), (_, _) {});
      final controller = container.read(orderManagementProvider(17).notifier);
      final order = CustomerOrderDto.fromJson(managementJson()).value;
      expect(
        await controller.submit(
          order,
          changes: const OrderChanges(description: 'Changed'),
        ),
        false,
      );
      expect(container.read(orderManagementProvider(17)).needsRefresh, false);
      repo.onWrite = () async => throw const ApiFailure(
        type: ApiFailureType.badRequest,
        statusCode: 409,
      );
      expect(
        await controller.submit(
          order,
          changes: const OrderChanges(description: 'Changed'),
        ),
        false,
      );
      expect(container.read(orderManagementProvider(17)).needsRefresh, true);
      expect(
        await controller.submit(
          order,
          changes: const OrderChanges(description: 'Changed'),
        ),
        false,
      );
      expect(repo.updates, 2);
    },
  );
}
