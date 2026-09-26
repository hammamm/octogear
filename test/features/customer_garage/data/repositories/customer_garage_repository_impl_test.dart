import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_garage/data/data_sources/customer_cars_remote_data_source.dart';
import 'package:octogear/features/customer_garage/data/models/customer_car_dto.dart';
import 'package:octogear/features/customer_garage/data/repositories/customer_garage_repository_impl.dart';

void main() {
  group('CustomerGarageRepositoryImpl', () {
    test(
      'maps the legacy plate DTO field into the correct domain entity',
      () async {
        final repository = CustomerGarageRepositoryImpl(
          remoteDataSource: _FakeCustomerCarsRemoteDataSource(
            cars: [_carDto()],
          ),
        );

        final car = (await repository.getCustomerCars()).single;

        expect(car.licensePlateNumber, 'ABC 1234');
        expect(car.carName.name, 'Camry');
        expect(car.color.name, 'White');
        expect(car.fuelType.name, 'Petrol');
        expect(car.picturePaths, ['cars/9.jpg']);
      },
    );

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
    'vehicle_plat_number': 'ABC 1234',
    'car_name': {'id': 4, 'name': 'Camry'},
    'color': {'id': 2, 'name': 'White'},
    'fuel_type': {'id': 1, 'name': 'Petrol'},
    'pictures': ['cars/9.jpg'],
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
}
