import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../data/repositories/api_order_lifecycle_repository.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/order_lifecycle_repository.dart';
import 'customer_orders_providers.dart';

final orderLifecycleRepositoryProvider = Provider<OrderLifecycleRepository>(
  (ref) => ApiOrderLifecycleRepository(ref.watch(apiClientProvider)),
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
      final latest = await ref
          .read(customerOrdersRepositoryProvider)
          .get(orderId);
      if (!ref.mounted) return false;
      if (latest.status != displayed.status ||
          latest.acceptedOfferId != displayed.acceptedOfferId ||
          !(action == OrderLifecycleAction.cancel
              ? latest.canCancel
              : latest.canConfirmReceived)) {
        throw const ApiFailure(
          type: ApiFailureType.badRequest,
          statusCode: 409,
        );
      }
      await ref.read(orderLifecycleRepositoryProvider).submit(orderId, action);
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
