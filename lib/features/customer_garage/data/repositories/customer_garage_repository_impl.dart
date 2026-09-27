import '../../../../core/api/api_failure.dart';
import '../../domain/entities/customer_car_form_references.dart';
import '../../domain/entities/create_customer_car_command.dart';
import '../../domain/entities/customer_car.dart';
import '../../domain/entities/update_customer_car_command.dart';
import '../../domain/repositories/customer_garage_repository.dart';
import '../data_sources/customer_cars_remote_data_source.dart';
import '../models/create_customer_car_request_dto.dart';
import '../models/customer_car_dto.dart';
import '../models/update_customer_car_request_dto.dart';

class CustomerGarageRepositoryImpl implements CustomerGarageRepository {
  const CustomerGarageRepositoryImpl({
    required CustomerCarsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CustomerCarsRemoteDataSource _remoteDataSource;

  @override
  Future<List<CustomerCar>> getCustomerCars() async {
    try {
      final cars = await _remoteDataSource.fetchCustomerCars();
      return cars.map((car) => car.toEntity()).toList(growable: false);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<CustomerCar> getCustomerCar(int carId) async {
    try {
      final car = await _remoteDataSource.fetchCustomerCar(carId);
      return car.toEntity();
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<CustomerCarFormReferences> getCustomerCarFormReferences() async {
    try {
      final responses = await Future.wait<List<CustomerCarReferenceDto>>([
        _remoteDataSource.fetchCompanies(),
        _remoteDataSource.fetchColors(),
        _remoteDataSource.fetchFuelTypes(),
      ]);

      return CustomerCarFormReferences(
        companies: _toReferences(responses[0]),
        colors: _toReferences(responses[1]),
        fuelTypes: _toReferences(responses[2]),
      );
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<List<CustomerCarReference>> getCarNames(int companyId) async {
    try {
      final names = await _remoteDataSource.fetchCarNames(companyId);
      return _toReferences(names);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<CustomerCar> createCustomerCar(
    CreateCustomerCarCommand command,
  ) async {
    try {
      final car = await _remoteDataSource.createCustomerCar(
        CreateCustomerCarRequestDto.fromCommand(command),
      );
      return car.toEntity();
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<CustomerCar> updateCustomerCar(
    int carId,
    UpdateCustomerCarCommand command,
  ) async {
    try {
      final car = await _remoteDataSource.updateCustomerCar(
        carId,
        UpdateCustomerCarRequestDto.fromCommand(command),
      );
      return car.toEntity();
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<void> deleteCustomerCar(int carId) async {
    try {
      await _remoteDataSource.deleteCustomerCar(carId);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  List<CustomerCarReference> _toReferences(
    List<CustomerCarReferenceDto> values,
  ) {
    return values.map((value) => value.toEntity()).toList(growable: false);
  }
}
