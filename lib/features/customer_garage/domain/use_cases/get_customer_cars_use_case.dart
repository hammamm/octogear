import '../entities/customer_car.dart';
import '../repositories/customer_garage_repository.dart';

class GetCustomerCarsUseCase {
  const GetCustomerCarsUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<List<CustomerCar>> call() => _repository.getCustomerCars();
}
