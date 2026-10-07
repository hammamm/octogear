import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/part_requests/data/data_sources/part_request_remote_data_source.dart';
import 'package:octogear/features/part_requests/data/models/part_request_dto.dart';
import 'package:octogear/features/part_requests/data/repositories/part_request_repository_impl.dart';
import 'package:octogear/features/part_requests/domain/entities/part_request.dart';
import 'package:octogear/features/part_requests/domain/repositories/part_request_repository.dart';
import 'package:octogear/features/part_requests/presentation/controllers/part_request_providers.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_car_catalog.dart';
import '../storefront/support/car_catalog_fixtures.dart';

const requestKey = (storeId: 14, carId: 7, componentId: 1);
const command = PartRequestCommand(
  componentId: 1,
  quantity: 2,
  notes: '  Check connector  ',
  idempotencyKey: '3f222d58-b411-4391-98a5-63e7a91bd392',
);

class FakeRequestRepository implements PartRequestRepository {
  Future<PartRequestReceipt> Function(PartRequestCommand)? onSubmit;
  Future<StorefrontCarComponent> Function(PartRequestKey)? onGet;
  final commands = <PartRequestCommand>[];
  @override
  Future<StorefrontCarComponent> getComponent(PartRequestKey key) async =>
      onGet == null ? catalogPart(1) : await onGet!(key);
  @override
  Future<PartRequestReceipt> submit(PartRequestCommand command) async {
    commands.add(command);
    return onSubmit == null
        ? PartRequestReceipt(id: 42, quantity: command.quantity)
        : await onSubmit!(command);
  }
}

void main() {
  test(
    'multipart contract sends inventory ID, optional note/photo and fresh retry streams',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final photo = PartRequestPhoto(bytes: bytes, mimeType: 'image/png');
      bytes[0] = 9;
      final dto = PartRequestDto(
        PartRequestCommand(
          componentId: 19,
          quantity: 2,
          notes: command.notes,
          idempotencyKey: command.idempotencyKey,
          photo: photo,
        ),
      );
      final data = dto.toFormData();
      expect(Map.fromEntries(data.fields), {
        'order_type': 'specific',
        'store_car_component_id': '19',
        'quantity': '2',
        'notes': 'Check connector',
      });
      expect(data.files.single.key, 'images[]');
      expect(data.files.single.value.filename, 'part-photo.png');
      expect(data.files.single.value.contentType.toString(), 'image/png');
      expect(
        await data.files.single.value
            .finalize()
            .expand((bytes) => bytes)
            .toList(),
        [1, 2, 3],
      );
      expect(
        await dto
            .toFormData()
            .files
            .single
            .value
            .finalize()
            .expand((bytes) => bytes)
            .toList(),
        [1, 2, 3],
      );
      final empty = const PartRequestDto(
        PartRequestCommand(
          componentId: 1,
          quantity: 1,
          notes: '  ',
          idempotencyKey: 'key',
        ),
      ).toFormData();
      expect(Map.fromEntries(empty.fields).containsKey('notes'), isFalse);
      expect(empty.files, isEmpty);
    },
  );

  test(
    'reads the correct nested part and posts authenticated localized specific request',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final remote = PartRequestRemoteDataSource(
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
                statusCode: options.method == 'GET' ? 200 : 201,
                data: {
                  'success': true,
                  'data': options.method == 'GET'
                      ? catalogPartJson()
                      : {'id': 42, 'quantity': 2, 'order_type': 'specific'},
                },
              ),
            );
          },
        ),
      );
      expect((await remote.getComponent(requestKey)).toEntity().id, 1);
      expect((await PartRequestRepositoryImpl(remote).submit(command)).id, 42);
      expect(requests[0].uri.path, '/api/stores/14/cars/7/components/1');
      expect(requests[1].uri.path, '/api/customer/orders');
      expect(requests[1].headers['Authorization'], 'Bearer test-token');
      expect(requests[1].headers['Accept-Language'], 'ar');
      expect(requests[1].headers['Idempotency-Key'], command.idempotencyKey);
      expect(requests[1].data, isA<FormData>());
    },
  );

  test(
    'a malformed success response is not treated as a confirmed request',
    () {
      for (final data in [
        null,
        {},
        {'id': 0, 'quantity': 2, 'order_type': 'specific'},
        {'id': 1, 'quantity': 2, 'order_type': 'general'},
      ]) {
        expect(() => partRequestReceiptFromJson(data), throwsFormatException);
      }
    },
  );

  test(
    'blocks double submit and repeats exact command/key after uncertain failure',
    () async {
      final repository = FakeRequestRepository();
      final pending = Completer<PartRequestReceipt>();
      repository.onSubmit = (_) => pending.future;
      final container = _container(repository);
      final notifier = container.read(
        partRequestControllerProvider(requestKey).notifier,
      );
      final send = notifier.submit(command);
      await notifier.submit(command);
      expect(repository.commands, hasLength(1));
      pending.completeError(const ApiFailure(type: ApiFailureType.timeout));
      await send;
      expect(
        container.read(partRequestControllerProvider(requestKey)).locked,
        isTrue,
      );
      expect(repository.commands, hasLength(1)); // No automatic writes.
      repository.onSubmit = null;
      await notifier.submit(
        const PartRequestCommand(
          componentId: 1,
          quantity: 1,
          notes: 'changed',
          idempotencyKey: 'another-key',
        ),
      );
      expect(identical(repository.commands[0], repository.commands[1]), isTrue);
      expect(
        container.read(partRequestControllerProvider(requestKey)).receipt!.id,
        42,
      );
      await notifier.submit(command);
      expect(repository.commands, hasLength(2));
    },
  );

  test(
    '422 unlocks editing and keeps field errors, 409 never starts another request',
    () async {
      final repository = FakeRequestRepository()
        ..onSubmit = (_) async => throw const ApiFailure(
          type: ApiFailureType.validation,
          statusCode: 422,
          fieldErrors: {
            'quantity': ['Only one left'],
          },
        );
      final container = _container(repository);
      final notifier = container.read(
        partRequestControllerProvider(requestKey).notifier,
      );
      await notifier.submit(command);
      expect(
        container.read(partRequestControllerProvider(requestKey)).locked,
        isFalse,
      );
      expect(
        container
            .read(partRequestControllerProvider(requestKey))
            .error!
            .fieldErrors['quantity'],
        ['Only one left'],
      );
      notifier.clearError();
      expect(
        container.read(partRequestControllerProvider(requestKey)).error,
        isNull,
      );
      repository.onSubmit = (_) async => throw const ApiFailure(
        type: ApiFailureType.unexpected,
        statusCode: 409,
      );
      await notifier.submit(command);
      expect(
        container.read(partRequestControllerProvider(requestKey)).retryCommand,
        same(command),
      );
    },
  );

  test('disposing while sending ignores completion safely', () async {
    final pending = Completer<PartRequestReceipt>();
    final repository = FakeRequestRepository()
      ..onSubmit = (_) => pending.future;
    final container = ProviderContainer(
      overrides: [partRequestRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(partRequestControllerProvider(requestKey), (_, _) {});
    final send = container
        .read(partRequestControllerProvider(requestKey).notifier)
        .submit(command);
    container.dispose();
    pending.complete(const PartRequestReceipt(id: 42, quantity: 2));
    await send;
  });
}

ProviderContainer _container(FakeRequestRepository repository) {
  final container = ProviderContainer(
    overrides: [partRequestRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.listen(partRequestControllerProvider(requestKey), (_, _) {});
  return container;
}
