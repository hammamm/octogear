import '../entities/customer_car.dart';
import '../entities/customer_car_form_references.dart';
import '../entities/create_customer_car_command.dart';

abstract interface class CustomerGarageRepository {
  Future<List<CustomerCar>> getCustomerCars();

  Future<CustomerCarFormReferences> getCustomerCarFormReferences();

  Future<List<CustomerCarReference>> getCarNames(int companyId);

  Future<CustomerCar> createCustomerCar(CreateCustomerCarCommand command);
}
