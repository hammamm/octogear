import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/customer_orders_repository.dart';
import '../data_sources/customer_orders_remote_data_source.dart';

class CustomerOrdersRepositoryImpl implements CustomerOrdersRepository {
  const CustomerOrdersRepositoryImpl(this.remote);
  final CustomerOrdersRemoteDataSource remote;
  @override
  Future<CustomerOrdersPage> list({
    required CustomerOrderFilter filter,
    required int page,
  }) => remote.list(filter, page);
  @override
  Future<CustomerOrder> get(int id) async => (await remote.get(id)).toEntity();
}
