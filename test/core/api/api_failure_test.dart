import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';

void main() {
  DioException responseFailure({
    required int statusCode,
    required Object data,
  }) {
    final requestOptions = RequestOptions(path: '/customer/customer-cars');
    return DioException(
      requestOptions: requestOptions,
      response: Response<Object>(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test('never retains a technical server failure message for presentation', () {
    final failure = ApiFailure.fromDio(
      responseFailure(
        statusCode: 500,
        data: {'message': 'SQLSTATE[42S22]: internal database detail'},
      ),
    );

    expect(failure.type, ApiFailureType.server);
    expect(failure.serverMessage, isNull);
  });

  test('keeps an expected validation message and its field errors', () {
    final failure = ApiFailure.fromDio(
      responseFailure(
        statusCode: 422,
        data: {
          'message': 'Please correct the highlighted fields.',
          'errors': {
            'vehicle_plat_number': ['The plate number is required.'],
          },
        },
      ),
    );

    expect(failure.type, ApiFailureType.validation);
    expect(failure.serverMessage, 'Please correct the highlighted fields.');
    expect(failure.fieldErrors['vehicle_plat_number'], [
      'The plate number is required.',
    ]);
  });
}
