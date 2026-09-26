import '../entities/customer_car_form_references.dart';
import '../repositories/customer_garage_repository.dart';

class GetCustomerCarFormReferencesUseCase {
  const GetCustomerCarFormReferencesUseCase(this._repository);

  final CustomerGarageRepository _repository;

  Future<CustomerCarFormReferences> call() {
    return _repository.getCustomerCarFormReferences();
  }
}
