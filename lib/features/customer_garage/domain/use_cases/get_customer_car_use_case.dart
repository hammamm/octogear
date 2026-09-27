import '../entities/customer_car.dart';
import '../repositories/customer_garage_repository.dart';

class GetCustomerCarUseCase {
  const GetCustomerCarUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<CustomerCar> call(int carId) => _repository.getCustomerCar(carId);
}
