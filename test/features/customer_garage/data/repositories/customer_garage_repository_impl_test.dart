import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_garage/data/data_sources/customer_cars_remote_data_source.dart';
import 'package:octogear/features/customer_garage/data/models/create_customer_car_request_dto.dart';
import 'package:octogear/features/customer_garage/data/models/customer_car_dto.dart';
import 'package:octogear/features/customer_garage/data/models/update_customer_car_request_dto.dart';
import 'package:octogear/features/customer_garage/data/repositories/customer_garage_repository_impl.dart';

void main() {
  group('CustomerGarageRepositoryImpl', () {
    test('maps the transmission DTO field into the domain entity', () async {
      final repository = CustomerGarageRepositoryImpl(
        remoteDataSource: _FakeCustomerCarsRemoteDataSource(cars: [_carDto()]),
      );

      final car = (await repository.getCustomerCars()).single;

      expect(car.transmissionType, 'automatic');
      expect(car.company.name, 'Toyota');
      expect(car.carName.name, 'Camry');
      expect(car.color.name, 'White');
      expect(car.fuelType.name, 'Petrol');
      expect(car.pictures.single.mimeType, 'image/jpeg');
    });

    test(
      'maps a malformed transport result to a safe unexpected failure',
      () async {
        final repository = const CustomerGarageRepositoryImpl(
          remoteDataSource: _FakeCustomerCarsRemoteDataSource(
            failure: FormatException('Malformed response'),
          ),
        );

        await expectLater(
          repository.getCustomerCars(),
          throwsA(
            isA<ApiFailure>().having(
              (failure) => failure.type,
              'type',
              ApiFailureType.unexpected,
            ),
          ),
        );
      },
    );
  });
}

CustomerCarDto _carDto() {
  return CustomerCarDto.fromJson({
    'id': 9,
    'manufacturing_year': 2022,
    'transmission_type': 'automatic',
    'company': {'id': 1, 'name': 'Toyota'},
    'car_name': {'id': 4, 'name': 'Camry'},
    'color': {'id': 2, 'name': 'White'},
    'fuel_type': {'id': 1, 'name': 'Petrol'},
    'pictures': [
      {
        'id': 17,
        'url': '/api/customer/customer-cars/9/pictures/17',
        'mime_type': 'image/jpeg',
        'size_bytes': 348291,
        'sort_order': 0,
      },
    ],
    'created_at': '2026-09-26T10:15:00Z',
  });
}

class _FakeCustomerCarsRemoteDataSource
    implements CustomerCarsRemoteDataSource {
  const _FakeCustomerCarsRemoteDataSource({this.cars, this.failure});

  final List<CustomerCarDto>? cars;
  final Object? failure;

  @override
  Future<List<CustomerCarDto>> fetchCustomerCars() async {
    if (failure != null) throw failure!;
    return cars!;
  }

  @override
  Future<CustomerCarDto> fetchCustomerCar(int carId) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchCarNames(int companyId) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchColors() {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchCompanies() {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerCarReferenceDto>> fetchFuelTypes() {
    throw UnimplementedError();
  }

  @override
  Future<CustomerCarDto> createCustomerCar(
    CreateCustomerCarRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerCarDto> updateCustomerCar(
    int carId,
    UpdateCustomerCarRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCustomerCar(int carId) {
    throw UnimplementedError();
  }
}
