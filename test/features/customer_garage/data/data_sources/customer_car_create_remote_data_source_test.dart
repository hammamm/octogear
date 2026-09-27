import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/customer_garage/data/data_sources/customer_cars_remote_data_source.dart';
import 'package:octogear/features/customer_garage/data/models/create_customer_car_request_dto.dart';
import 'package:octogear/features/customer_garage/domain/entities/create_customer_car_command.dart';

void main() {
  test(
    'posts a protected multipart customer-car request with the idempotency key',
    () async {
      late RequestOptions request;
      final source = CustomerCarsRemoteDataSourceImpl(
        apiClient: _clientThatReturns(
          _carEnvelope(),
          onRequest: (value) => request = value,
        ),
      );
      final created = await source.createCustomerCar(
        CreateCustomerCarRequestDto.fromCommand(_command()),
      );

      expect(request.method, 'POST');
      expect(request.uri.path, '/api/customer/customer-cars');
      expect(_header(request, 'Authorization'), 'Bearer secure-token');
      expect(_header(request, 'Accept-Language'), 'en');
      expect(_header(request, 'Idempotency-Key'), 'request-uuid');
      expect(request.contentType, Headers.multipartFormDataContentType);

      final formData = request.data! as FormData;
      expect(
        {for (final field in formData.fields) field.key: field.value},
        {
          'car_name_id': '4',
          'manufacturing_year': '2022',
          'vehicle_plat_number': 'ABC 1234',
          'color_id': '2',
          'fuel_type': '1',
        },
      );
      expect(formData.files.map((entry) => entry.key), ['pictures[]']);
      expect(
        created.pictures.single.url,
        '/api/customer/customer-cars/9/pictures/17',
      );
    },
  );
}

CreateCustomerCarCommand _command() {
  return CreateCustomerCarCommand(
    carNameId: 4,
    manufacturingYear: 2022,
    licensePlateNumber: 'ABC 1234',
    colorId: 2,
    fuelTypeId: 1,
    idempotencyKey: 'request-uuid',
    pictures: [
      CustomerCarPhotoUpload(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        mimeType: 'image/jpeg',
      ),
    ],
  );
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
            statusCode: 201,
          ),
        );
      },
    ),
  );
  return client;
}

Map<String, Object?> _carEnvelope() {
  return {
    'success': true,
    'message': 'Car created',
    'data': {
      'id': 9,
      'manufacturing_year': 2022,
      'vehicle_plat_number': 'ABC 1234',
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
    },
  };
}

Object? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
