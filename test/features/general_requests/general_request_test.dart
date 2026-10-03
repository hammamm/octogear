import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/general_requests/data/data_sources/general_request_remote_data_source.dart';
import 'package:octogear/features/general_requests/data/models/general_request_dto.dart';
import 'package:octogear/features/general_requests/domain/entities/general_request.dart';
import 'package:octogear/features/general_requests/domain/use_cases/send_general_request.dart';
import 'package:octogear/features/general_requests/presentation/controllers/general_request_providers.dart';
import 'package:octogear/features/part_requests/domain/entities/part_request.dart';
import 'general_request_fixtures.dart';

GeneralRequestCommand command({
  RequestVehicle vehicle = const SavedRequestVehicle(7),
  int? componentId = 5,
  String? name,
  List<PartRequestPhoto> photos = const [],
}) => GeneralRequestCommand(
  vehicle: vehicle,
  componentId: componentId,
  componentName: name,
  description: ' Check connector ',
  photos: photos,
  idempotencyKey: '3f222d58-b411-4391-98a5-63e7a91bd392',
);

void main() {
  test(
    'saved vehicle/catalog and inline vehicle/custom part have exclusive multipart contracts',
    () async {
      final saved = GeneralRequestDto(command()).toFormData();
      expect(Map.fromEntries(saved.fields), {
        'order_type': 'general',
        'customer_car_id': '7',
        'component_id': '5',
        'description': 'Check connector',
      });
      final bytes = Uint8List.fromList([1, 2, 3]);
      final photos = [PartRequestPhoto(bytes: bytes, mimeType: 'image/png')];
      final dto = GeneralRequestDto(
        command(
          vehicle: const NewRequestVehicle(
            carNameId: 2,
            year: 2020,
            transmission: 'unknown',
            colorId: 3,
            fuelTypeId: 4,
            saveToGarage: true,
          ),
          componentId: null,
          name: ' Headlight ',
          photos: photos,
        ),
      );
      bytes[0] = 9;
      photos.clear();
      final form = dto.toFormData();
      expect(Map.fromEntries(form.fields), {
        'order_type': 'general',
        'vehicle[car_name_id]': '2',
        'vehicle[manufacturing_year]': '2020',
        'vehicle[transmission_type]': 'unknown',
        'vehicle[color_id]': '3',
        'vehicle[fuel_type]': '4',
        'save_to_my_cars': '1',
        'component_name': 'Headlight',
        'description': 'Check connector',
      });
      for (final data in [form, dto.toFormData()]) {
        expect(data.files.single.key, 'images[]');
        expect(
          await data.files.single.value
              .finalize()
              .expand((bytes) => bytes)
              .toList(),
          [1, 2, 3],
        );
      }
    },
  );
  test(
    'localized paginated component search and authenticated idempotent submission',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final requests = <RequestOptions>[];
      final remote = GeneralRequestRemoteDataSource(
        ApiClient(
          dio: dio,
          accessTokenResolver: () => 'test-token',
          localeResolver: () => 'ar',
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': options.method == 'GET'
                      ? [
                          {'id': 5, 'name': 'مصباح'},
                        ]
                      : {'id': 42, 'order_type': 'general'},
                  if (options.method == 'GET')
                    'meta': {
                      'current_page': 2,
                      'last_page': 3,
                      'per_page': 20,
                      'total': 50,
                    },
                },
              ),
            );
          },
        ),
      );
      expect(
        (await remote.components(search: 'مصباح', page: 2)).items.single.name,
        'مصباح',
      );
      expect(requests.first.uri.path, '/api/reference/components');
      expect(requests.first.queryParameters, {
        'page': 2,
        'per_page': 20,
        'search': 'مصباح',
      });
      expect(await remote.submit(command()), 42);
      expect(requests.last.uri.path, '/api/customer/orders');
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      expect(requests.last.headers['Accept-Language'], 'ar');
      expect(
        requests.last.headers['Idempotency-Key'],
        command().idempotencyKey,
      );
    },
  );
  test(
    'malformed receipts are never confirmed and invalid drafts never reach repository',
    () {
      for (final data in [
        null,
        {},
        {'id': 0, 'order_type': 'general'},
        {'id': 42, 'order_type': 'specific'},
      ]) {
        expect(() => generalRequestReceipt(data), throwsFormatException);
      }
      final repository = FakeGeneralRequestRepository();
      final send = SendGeneralRequest(repository);
      for (final invalid in [
        command(componentId: null),
        command(name: 'part'),
        command(vehicle: const SavedRequestVehicle(0)),
        command(componentId: null, name: '  '),
        command(
          vehicle: const NewRequestVehicle(
            carNameId: 1,
            year: 1969,
            transmission: 'unknown',
            colorId: 2,
            fuelTypeId: 3,
          ),
        ),
      ]) {
        expect(() => send(invalid), throwsArgumentError);
      }
      expect(repository.commands, isEmpty);
    },
  );
  test(
    'double submit blocked, uncertain result keeps exact snapshot and retries only explicitly',
    () async {
      final repository = FakeGeneralRequestRepository();
      final pending = Completer<int>();
      repository.onSubmit = (_) => pending.future;
      final container = ProviderContainer(
        overrides: [
          generalRequestRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = generalRequestControllerProvider('draft');
      container.listen(provider, (_, _) {});
      final controller = container.read(provider.notifier);
      final first = command();
      final sending = controller.submit(first);
      await controller.submit(first);
      expect(repository.commands, hasLength(1));
      pending.completeError(const ApiFailure(type: ApiFailureType.timeout));
      await sending;
      expect(container.read(provider).locked, isTrue);
      expect(repository.commands, hasLength(1));
      repository.onSubmit = null;
      await controller.submit(command(componentId: 99));
      expect(identical(repository.commands.last, first), isTrue);
      expect(container.read(provider).orderId, 42);
      await controller.submit(first);
      expect(repository.commands, hasLength(2));
    },
  );
  test(
    'validation rejection unlocks edits; conflict cannot be resubmitted',
    () async {
      final repository = FakeGeneralRequestRepository()
        ..onSubmit = (_) async => throw const ApiFailure(
          type: ApiFailureType.validation,
          statusCode: 422,
          fieldErrors: {
            'component_name': ['Invalid part'],
          },
        );
      final container = ProviderContainer(
        overrides: [
          generalRequestRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = generalRequestControllerProvider('draft');
      container.listen(provider, (_, _) {});
      final controller = container.read(provider.notifier);
      await controller.submit(command());
      expect(container.read(provider).locked, isFalse);
      expect(
        container.read(provider).error!.fieldErrors,
        contains('component_name'),
      );
      controller.clearError();
      repository.onSubmit = (_) async => throw const ApiFailure(
        type: ApiFailureType.unexpected,
        statusCode: 409,
      );
      await controller.submit(command());
      expect(container.read(provider).locked, isTrue);
      await controller.submit(command());
      expect(repository.commands, hasLength(2));
    },
  );
}
