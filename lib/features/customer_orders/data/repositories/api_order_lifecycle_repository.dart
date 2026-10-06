import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/repositories/order_lifecycle_repository.dart';

class ApiOrderLifecycleRepository implements OrderLifecycleRepository {
  const ApiOrderLifecycleRepository(this.api);
  final ApiClient api;

  @override
  Future<void> submit(int orderId, OrderLifecycleAction action) async {
    final result = await api.post<bool>(
      'customer/orders/$orderId/${action.name}',
      requiresAuthentication: true,
      decode: (data) =>
          data is Map &&
          data['id'] == orderId &&
          data['status'] ==
              (action == OrderLifecycleAction.cancel
                  ? 'cancelled'
                  : 'completed'),
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }
}
