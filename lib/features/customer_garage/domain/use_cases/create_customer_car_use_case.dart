import '../entities/create_customer_car_command.dart';
import '../entities/customer_car.dart';
import '../repositories/customer_garage_repository.dart';

class CreateCustomerCarUseCase {
  const CreateCustomerCarUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<CustomerCar> call(CreateCustomerCarCommand command) {
    return _repository.createCustomerCar(command);
  }
}
