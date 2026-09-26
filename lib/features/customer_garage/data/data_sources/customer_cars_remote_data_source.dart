import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/customer_car_dto.dart';

/// Network-only access to the authenticated customer's saved cars.
abstract interface class CustomerCarsRemoteDataSource {
  Future<List<CustomerCarDto>> fetchCustomerCars();
}

class CustomerCarsRemoteDataSourceImpl implements CustomerCarsRemoteDataSource {
  const CustomerCarsRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<CustomerCarDto>> fetchCustomerCars() async {
    final response = await _apiClient.get<List<CustomerCarDto>>(
      'customer/customer-cars',
      requiresAuthentication: true,
      decode: customerCarListFromJson,
    );
    final cars = response.data;
    if (cars == null) throw const ApiFailure.unexpected();
    return cars;
  }
}
