import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/data_sources/order_lifecycle_remote_data_source.dart';
import '../../data/repositories/api_order_lifecycle_repository.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/order_lifecycle_repository.dart';
import '../../domain/use_cases/submit_order_lifecycle_use_case.dart';
import '../../domain/use_cases/verify_order_lifecycle_use_case.dart';
import 'customer_orders_providers.dart';

final orderLifecycleRemoteDataSourceProvider = Provider(
  (ref) => OrderLifecycleRemoteDataSource(ref.watch(apiClientProvider)),
);

final orderLifecycleRepositoryProvider = Provider<OrderLifecycleRepository>(
  (ref) => ApiOrderLifecycleRepository(
    ref.watch(orderLifecycleRemoteDataSourceProvider),
  ),
);

final submitOrderLifecycleProvider = Provider(
  (ref) =>
      SubmitOrderLifecycleUseCase(ref.watch(orderLifecycleRepositoryProvider)),
);

final verifyOrderLifecycleProvider = Provider(
  (ref) =>
      VerifyOrderLifecycleUseCase(ref.watch(customerOrdersRepositoryProvider)),
);

class OrderLifecycleState {
  const OrderLifecycleState({
    this.busy = false,
    this.needsRefresh = false,
    this.error,
    this.result,
  });
  final bool busy, needsRefresh;
  final ApiFailure? error;
  final OrderLifecycleAction? result;
}

final orderLifecycleProvider = NotifierProvider.autoDispose
    .family<OrderLifecycleController, OrderLifecycleState, int>(
      OrderLifecycleController.new,
    );

class OrderLifecycleController extends Notifier<OrderLifecycleState> {
  OrderLifecycleController(this.orderId);
  final int orderId;
  @override
  OrderLifecycleState build() => const OrderLifecycleState();

  Future<bool> submit(
    CustomerOrder displayed,
    OrderLifecycleAction action,
  ) async {
    if (state.busy ||
        state.needsRefresh ||
        state.result != null ||
        displayed.id != orderId) {
      return false;
    }
    final link = ref.keepAlive();
    state = const OrderLifecycleState(busy: true);
    try {
      await ref.read(verifyOrderLifecycleProvider)(displayed, action);
      if (!ref.mounted) return false;
      await ref.read(submitOrderLifecycleProvider).call(orderId, action);
      if (!ref.mounted) return false;
      state = OrderLifecycleState(result: action);
      _invalidate();
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      // Read the authoritative status before any explicit retry, including a
      // timeout after the server may already have committed the transition.
      state = OrderLifecycleState(
        needsRefresh: true,
        error: error is ApiFailure ? error : const ApiFailure.unexpected(),
      );
      return false;
    } finally {
      link.close();
    }
  }

  Future<void> refresh() async {
    if (state.busy) return;
    final link = ref.keepAlive();
    state = const OrderLifecycleState(busy: true);
    try {
      ref.invalidate(customerOrderProvider(orderId));
      await ref.read(customerOrderProvider(orderId).future);
      if (!ref.mounted) return;
      ref.invalidate(customerOrdersProvider);
      state = const OrderLifecycleState();
    } catch (error) {
      if (ref.mounted) {
        state = OrderLifecycleState(
          needsRefresh: true,
          error: error is ApiFailure ? error : const ApiFailure.unexpected(),
        );
      }
    } finally {
      link.close();
    }
  }

  void _invalidate() {
    ref.invalidate(customerOrderProvider(orderId));
    ref.invalidate(customerOrdersProvider);
  }
}
