import '../entities/customer_car.dart';
import '../repositories/customer_garage_repository.dart';

class GetCustomerCarNamesUseCase {
  const GetCustomerCarNamesUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<List<CustomerCarReference>> call(int companyId) {
    return _repository.getCarNames(companyId);
  }
}
