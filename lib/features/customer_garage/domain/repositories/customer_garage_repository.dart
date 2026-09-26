import '../entities/customer_car.dart';

abstract interface class CustomerGarageRepository {
  Future<List<CustomerCar>> getCustomerCars();
}
