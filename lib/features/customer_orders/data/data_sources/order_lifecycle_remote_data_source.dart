import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';

class OrderLifecycleRemoteDataSource {
  const OrderLifecycleRemoteDataSource(this.api);
  final ApiClient api;

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
