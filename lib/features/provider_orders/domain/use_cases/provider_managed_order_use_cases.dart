import '../entities/provider_managed_order.dart';
import '../repositories/provider_managed_orders_repository.dart';

class GetProviderManagedOrders {
  const GetProviderManagedOrders(this.repository);
  final ProviderManagedOrdersRepository repository;
  Future<ProviderManagedOrdersPage> call(
    ProviderOrderQuery query, {
    int page = 1,
  }) {
    final statuses = query.kind == ProviderOrderKind.paid
        ? ['paid', 'completed']
        : [
            'pending',
            'awaiting_payment',
            'paid',
            'completed',
            'rejected',
            'cancelled',
          ];
    if (page < 1 ||
        (query.status != null && !statuses.contains(query.status))) {
      throw ArgumentError('Invalid provider order query.');
    }
    return repository.list(query, page: page);
  }
}

class GetProviderManagedOrder {
  const GetProviderManagedOrder(this.repository);
  final ProviderManagedOrdersRepository repository;
  Future<ProviderManagedOrder> call(ProviderOrderKey key) {
    if (key.id < 1) throw ArgumentError('Invalid order ID.');
    return repository.get(key);
  }
}

class RespondToProviderDirectOrder {
  const RespondToProviderDirectOrder(this.repository);
  final ProviderManagedOrdersRepository repository;
  Future<ProviderManagedOrder> call(
    ProviderManagedOrder order, {
    required bool accept,
  }) {
    if (order.type != 'specific' ||
        order.status != 'pending' ||
        (accept ? !order.canAccept : !order.canReject) ||
        (accept &&
            ((order.requestedUnitPrice ?? 0) < 1 ||
                (order.quantity ?? 0) < 1))) {
      throw StateError('This order cannot be changed.');
    }
    return repository.respond(order, accept: accept);
  }
}
