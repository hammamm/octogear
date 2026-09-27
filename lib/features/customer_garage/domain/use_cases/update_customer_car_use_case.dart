import '../entities/customer_car.dart';
import '../entities/update_customer_car_command.dart';
import '../repositories/customer_garage_repository.dart';

class UpdateCustomerCarUseCase {
  const UpdateCustomerCarUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<CustomerCar> call(int carId, UpdateCustomerCarCommand command) {
    return _repository.updateCustomerCar(carId, command);
  }
}
