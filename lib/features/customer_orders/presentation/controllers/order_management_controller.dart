import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/order_management_remote_data_source.dart';
import '../../data/repositories/api_order_management_repository.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/order_changes.dart';
import '../../domain/repositories/order_management_repository.dart';
import '../../domain/use_cases/delete_customer_order_use_case.dart';
import '../../domain/use_cases/update_customer_order_use_case.dart';
import 'customer_orders_providers.dart';

final orderManagementRemoteDataSourceProvider = Provider(
  (ref) => OrderManagementRemoteDataSource(ref.watch(apiClientProvider)),
);

final orderManagementRepositoryProvider = Provider<OrderManagementRepository>(
  (ref) => ApiOrderManagementRepository(
    ref.watch(orderManagementRemoteDataSourceProvider),
  ),
);

final updateCustomerOrderProvider = Provider(
  (ref) =>
      UpdateCustomerOrderUseCase(ref.watch(orderManagementRepositoryProvider)),
);

final deleteCustomerOrderProvider = Provider(
  (ref) =>
      DeleteCustomerOrderUseCase(ref.watch(orderManagementRepositoryProvider)),
);

class OrderManagementState {
  const OrderManagementState({
    this.busy = false,
    this.needsRefresh = false,
    this.error,
    this.deleted = false,
  });
  final bool busy, needsRefresh, deleted;
  final ApiFailure? error;
}

final orderManagementProvider = NotifierProvider.autoDispose
    .family<OrderManagementController, OrderManagementState, int>(
      OrderManagementController.new,
    );

class OrderManagementController extends Notifier<OrderManagementState> {
  OrderManagementController(this.orderId);
  final int orderId;
  @override
  OrderManagementState build() => const OrderManagementState();

  Future<bool> submit(CustomerOrder order, {OrderChanges? changes}) async {
    if (state.busy || state.needsRefresh || state.deleted) return false;
    if (order.id != orderId ||
        order.editToken == null ||
        (changes == null ? !order.canDelete : !order.canEdit)) {
      return false;
    }
    final keepAlive = ref.keepAlive();
    state = const OrderManagementState(busy: true);
    try {
      // The server checks the revision and eligibility while holding the order lock.
      if (changes == null) {
        await ref.read(deleteCustomerOrderProvider)(orderId, order.editToken!);
      } else {
        await ref.read(updateCustomerOrderProvider)(
          orderId,
          order.editToken!,
          changes,
        );
      }
      if (!ref.mounted) return false;
      state = OrderManagementState(deleted: changes == null);
      _invalidate();
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final failure = error is ApiFailure
          ? error
          : const ApiFailure.unexpected();
      state = OrderManagementState(
        error: failure,
        needsRefresh: failure.statusCode != 422,
      );
      return false;
    } finally {
      keepAlive.close();
    }
  }

  /// Reconcile an uncertain write before another explicit submission. Never replay it.
  Future<void> refresh() async {
    if (state.busy) return;
    final keepAlive = ref.keepAlive();
    state = const OrderManagementState(busy: true);
    try {
      await ref.read(getCustomerOrderProvider).call(orderId);
      if (!ref.mounted) return;
      state = const OrderManagementState();
      _invalidate();
    } catch (error) {
      if (!ref.mounted) return;
      if (error is ApiFailure && error.type == ApiFailureType.notFound) {
        state = const OrderManagementState(deleted: true);
        _invalidate();
      } else {
        state = OrderManagementState(
          needsRefresh: true,
          error: error is ApiFailure ? error : const ApiFailure.unexpected(),
        );
      }
    } finally {
      keepAlive.close();
    }
  }

  void _invalidate() {
    ref.invalidate(customerOrderProvider(orderId));
    ref.invalidate(customerOrdersProvider);
  }
}
