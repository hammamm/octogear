import '../../../../core/api/api_failure.dart';
import '../../domain/entities/customer_car.dart';
import '../../domain/repositories/customer_garage_repository.dart';
import '../data_sources/customer_cars_remote_data_source.dart';

class CustomerGarageRepositoryImpl implements CustomerGarageRepository {
  const CustomerGarageRepositoryImpl({
    required CustomerCarsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CustomerCarsRemoteDataSource _remoteDataSource;

  @override
  Future<List<CustomerCar>> getCustomerCars() async {
    try {
      final cars = await _remoteDataSource.fetchCustomerCars();
      return cars.map((car) => car.toEntity()).toList(growable: false);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
