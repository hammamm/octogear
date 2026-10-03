import 'package:octogear/features/general_requests/domain/entities/general_request.dart';
import 'package:octogear/features/general_requests/domain/repositories/general_request_repository.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car.dart';
import 'package:octogear/features/customer_garage/domain/entities/customer_car_form_references.dart';
import 'package:octogear/features/customer_garage/domain/repositories/customer_garage_repository.dart';

class FakeGeneralRequestRepository implements GeneralRequestRepository {
  final commands = <GeneralRequestCommand>[];
  Future<int> Function(GeneralRequestCommand)? onSubmit;
  Future<RequestComponentsPage> Function(String, int)? onSearch;
  @override
  Future<int> submit(GeneralRequestCommand command) async {
    commands.add(command);
    return onSubmit == null ? 42 : await onSubmit!(command);
  }

  @override
  Future<RequestComponentsPage> components({
    required String search,
    required int page,
  }) async => onSearch == null
      ? const RequestComponentsPage(
          items: [RequestComponent(id: 5, name: 'Headlight')],
          page: 1,
          lastPage: 1,
        )
      : await onSearch!(search, page);
}

class RequestGarageRepository implements CustomerGarageRepository {
  bool failCars = false;
  List<CustomerCar> cars = [requestCar];
  @override
  Future<List<CustomerCar>> getCustomerCars() async {
    if (failCars) throw Exception('offline');
    return cars;
  }

  @override
  Future<CustomerCarFormReferences> getCustomerCarFormReferences() async =>
      const CustomerCarFormReferences(
        companies: [CustomerCarReference(id: 1, name: 'Toyota')],
        colors: [CustomerCarReference(id: 3, name: 'White')],
        fuelTypes: [CustomerCarReference(id: 4, name: 'Petrol')],
      );
  @override
  Future<List<CustomerCarReference>> getCarNames(int companyId) async => const [
    CustomerCarReference(id: 2, name: 'Camry'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final requestCar = CustomerCar(
  id: 7,
  manufacturingYear: 2020,
  company: const CustomerCarReference(id: 1, name: 'Toyota'),
  carName: const CustomerCarReference(id: 2, name: 'Camry'),
  color: const CustomerCarReference(id: 3, name: 'White'),
  fuelType: const CustomerCarReference(id: 4, name: 'Petrol'),
  pictures: const [],
  createdAt: DateTime(2026),
);
