import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/customer_order.dart';
import '../models/customer_order_dto.dart';

class CustomerOrdersRemoteDataSource {
  const CustomerOrdersRemoteDataSource(this.api);
  final ApiClient api;
  Future<CustomerOrdersPageDto> list(
    CustomerOrderFilter filter,
    int page,
  ) async {
    final response = await api.get<List<CustomerOrderDto>>(
      'customer/orders',
      requiresAuthentication: true,
      queryParameters: {
        'page': page,
        if (filter != CustomerOrderFilter.all) 'order_type': filter.name,
      },
      decode: (json) {
        if (json is! List) throw const FormatException('Expected orders.');
        return json.map(CustomerOrderDto.fromJson).toList();
      },
    );
    final meta = response.pagination;
    final orders = response.data;
    if (orders == null ||
        meta == null ||
        meta.currentPage != page ||
        (filter != CustomerOrderFilter.all &&
            orders.any((order) => order.value.type.name != filter.name))) {
      throw const ApiFailure.unexpected();
    }
    return CustomerOrdersPageDto(
      orders: List.unmodifiable(orders),
      currentPage: meta.currentPage,
      lastPage: meta.lastPage,
      total: meta.total,
    );
  }

  Future<CustomerOrderDto> get(int id) async {
    final response = await api.get<CustomerOrderDto>(
      'customer/orders/$id',
      requiresAuthentication: true,
      decode: CustomerOrderDto.fromJson,
    );
    if (response.data == null || response.data!.value.id != id) {
      throw const ApiFailure.unexpected();
    }
    return response.data!;
  }
}
