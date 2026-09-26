import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_garage/data/data_sources/customer_cars_remote_data_source.dart';

void main() {
  group('CustomerCarsRemoteDataSourceImpl', () {
    test(
      'gets typed saved cars from the protected customer endpoint with current headers',
      () async {
        late RequestOptions request;
        final dataSource = CustomerCarsRemoteDataSourceImpl(
          apiClient: _clientThatReturns(
            _carsEnvelope(),
            onRequest: (value) => request = value,
          ),
        );

        final cars = await dataSource.fetchCustomerCars();
        final car = cars.single;

        expect(request.uri.path, '/api/customer/customer-cars');
        expect(_header(request, 'Authorization'), 'Bearer secure-token');
        expect(_header(request, 'Accept-Language'), 'en');
        expect(car.id, 9);
        expect(car.manufacturingYear, 2022);
        expect(car.licensePlateNumber, 'ABC 1234');
        expect(car.carName.name, 'Camry');
        expect(car.color.name, 'White');
        expect(car.fuelType.name, 'Petrol');
        expect(car.picturePaths, ['cars/9.jpg']);
      },
    );

    test(
      'turns malformed saved-car transport data into a safe failure',
      () async {
        final dataSource = CustomerCarsRemoteDataSourceImpl(
          apiClient: _clientThatReturns({
            'success': true,
            'message': 'Cars loaded',
            'data': [
              {
                'id': 9,
                'manufacturing_year': 2022,
                // The legacy server field is required; malformed data must not
                // leak a FormatException beyond the API boundary.
                'vehicle_plat_number': '',
              },
            ],
          }),
        );

        await expectLater(
          dataSource.fetchCustomerCars(),
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

ApiClient _clientThatReturns(
  Map<String, Object?> response, {
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
  final client = ApiClient(
    dio: dio,
    accessTokenResolver: () => 'secure-token',
    localeResolver: () => 'en',
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response<Object?>(
            data: response,
            requestOptions: options,
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return client;
}

Map<String, Object?> _carsEnvelope() {
  return {
    'success': true,
    'message': 'Cars loaded',
    'data': [_carJson()],
  };
}

Map<String, Object?> _carJson() {
  return {
    'id': 9,
    'manufacturing_year': 2022,
    'vehicle_plat_number': 'ABC 1234',
    'car_name': {'id': 4, 'name': 'Camry'},
    'color': {'id': 2, 'name': 'White'},
    'fuel_type': {'id': 1, 'name': 'Petrol'},
    'pictures': ['cars/9.jpg'],
    'created_at': '2026-09-26T10:15:00Z',
  };
}

Object? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
