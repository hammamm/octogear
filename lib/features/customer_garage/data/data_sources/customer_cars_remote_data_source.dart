import '../../../../core/api/reference_list_loader.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/create_customer_car_request_dto.dart';
import '../models/customer_car_dto.dart';
import '../models/update_customer_car_request_dto.dart';

/// Network-only access to customer-garage APIs.
///
/// This layer owns endpoint paths and transport DTOs only. Authentication,
/// locale headers, multipart encoding, and error mapping remain centralized in
/// [ApiClient].
abstract interface class CustomerCarsRemoteDataSource {
  Future<List<CustomerCarDto>> fetchCustomerCars();

  Future<CustomerCarDto> fetchCustomerCar(int carId);

  Future<List<CustomerCarReferenceDto>> fetchCompanies();

  Future<List<CustomerCarReferenceDto>> fetchCarNames(int companyId);

  Future<List<CustomerCarReferenceDto>> fetchColors();

  Future<List<CustomerCarReferenceDto>> fetchFuelTypes();

  Future<CustomerCarDto> createCustomerCar(CreateCustomerCarRequestDto request);

  Future<CustomerCarDto> updateCustomerCar(
    int carId,
    UpdateCustomerCarRequestDto request,
  );

  Future<void> deleteCustomerCar(int carId);
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

  @override
  Future<CustomerCarDto> fetchCustomerCar(int carId) async {
    final response = await _apiClient.get<CustomerCarDto>(
      'customer/customer-cars/$carId',
      requiresAuthentication: true,
      decode: CustomerCarDto.fromJson,
    );
    final car = response.data;
    if (car == null) throw const ApiFailure.unexpected();
    return car;
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchCompanies() {
    return _fetchReferences('reference/companies');
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchCarNames(int companyId) {
    return _fetchReferences('reference/companies/$companyId/names');
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchColors() {
    return _fetchReferences('reference/colors', paginated: false);
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchFuelTypes() {
    return _fetchReferences('reference/fuel-types', paginated: false);
  }

  @override
  Future<CustomerCarDto> createCustomerCar(
    CreateCustomerCarRequestDto request,
  ) async {
    final response = await _apiClient.postMultipart<CustomerCarDto>(
      'customer/customer-cars',
      data: request.toFormData(),
      decode: CustomerCarDto.fromJson,
      requiresAuthentication: true,
      headers: {'Idempotency-Key': request.idempotencyKey},
    );
    final car = response.data;
    if (car == null) throw const ApiFailure.unexpected();
    return car;
  }

  @override
  Future<CustomerCarDto> updateCustomerCar(
    int carId,
    UpdateCustomerCarRequestDto request,
  ) async {
    final response = await _apiClient.patch<CustomerCarDto>(
      'customer/customer-cars/$carId',
      data: request.toJson(),
      decode: CustomerCarDto.fromJson,
      requiresAuthentication: true,
    );
    final car = response.data;
    if (car == null) throw const ApiFailure.unexpected();
    return car;
  }

  @override
  Future<void> deleteCustomerCar(int carId) async {
    await _apiClient.delete<void>(
      'customer/customer-cars/$carId',
      requiresAuthentication: true,
      decode: (_) {},
    );
  }

  Future<List<CustomerCarReferenceDto>> _fetchReferences(
    String path, {
    bool paginated = true,
  }) => loadReferenceList(
    _apiClient,
    path,
    decode: customerCarReferenceListFromJson,
    paginated: paginated,
  );
}
