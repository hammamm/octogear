import '../repositories/customer_garage_repository.dart';

class DeleteCustomerCarUseCase {
  const DeleteCustomerCarUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<void> call(int carId) => _repository.deleteCustomerCar(carId);
}
