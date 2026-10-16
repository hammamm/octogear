import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_stores/data/data_sources/provider_store_management_remote_data_source.dart';
import 'package:octogear/features/provider_stores/data/models/provider_store_details_dto.dart';
import 'package:octogear/features/provider_stores/data/models/provider_store_write_dto.dart';
import 'package:octogear/features/provider_stores/domain/entities/provider_store_management.dart';
import 'package:octogear/features/provider_stores/domain/use_cases/manage_provider_stores.dart';
import 'package:octogear/features/provider_stores/presentation/controllers/provider_store_management_providers.dart';
import 'provider_stores_fixtures.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_application.dart';
import 'store_management_fixtures.dart';

Map<String, Object?> storeJson() => {
  'id': 1,
  'edit_version': managedStore.editVersion,
  'name': 'Al Faris Parts',
  'nick_name': 'Al Faris',
  'employee_name': 'Manager',
  'mobile': '+966511111111',
  'city': {'id': 1, 'name': 'Riyadh'},
  'status': 'active',
  'url_location': 'https://maps.example.test/store',
  'commercial_registration_number': '1234567890',
  'can_manage': true,
  'companies': [
    {'id': 1, 'name': 'Toyota'},
  ],
  'commercial_registration_picture': '/api/media/stores/1/registration',
  'pictures': [
    {'id': 7, 'url': '/api/media/stores/1/pictures/7'},
  ],
};

void main() {
  test('management DTO rejects foreign media URLs and non-owner responses', () {
    expect(ProviderStoreDetailsDto.fromJson(storeJson()).pictures.single.id, 7);
    for (final invalid in [
      {...storeJson(), 'can_manage': false},
      {
        ...storeJson(),
        'commercial_registration_picture': 'https://foreign.test/registration',
      },
      {
        ...storeJson(),
        'pictures': [
          {'id': 7, 'url': '/api/media/stores/99/pictures/7'},
        ],
      },
      {...storeJson(), 'city': null},
    ]) {
      expect(
        () => ProviderStoreDetailsDto.fromJson(invalid),
        throwsFormatException,
      );
    }
  });
  test(
    'change submission sends reason, version, retained IDs and brands without mobile',
    () async {
      late RequestOptions sent;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(dio: dio, accessTokenResolver: () => 'test-token');
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            sent = request;
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    ...storeJson(),
                    'id': 11,
                    'request_status': 'pending',
                    'store_id': 1,
                    'change_reason': 'We changed our trading name.',
                    'pictures': [],
                    'commercial_registration_picture': null,
                  },
                },
              ),
            );
          },
        ),
      );
      final draft = storeDraft();
      await ProviderStoreManagementRemoteDataSource(api).requestStoreChange(
        1,
        ProviderStoreWriteDto(
          ProviderStoreDraft(
            details: draft.details,
            mobile: draft.mobile,
            changeReason: draft.changeReason,
            baseVersion: draft.baseVersion,
            retainedPictureIds: [7],
            pictures: [imageDocument],
          ),
        ),
        requestKey,
      );
      expect(sent.path, 'provider/stores/1/change-requests');
      expect(sent.method, 'POST');
      expect(sent.headers['Authorization'], 'Bearer test-token');
      final data = sent.data as FormData;
      expect(
        data.fields.any((e) => e.key == '_method' || e.key == 'mobile'),
        isFalse,
      );
      expect(
        data.fields.any(
          (e) => e.key == 'retained_picture_ids[]' && e.value == '7',
        ),
        isTrue,
      );
      expect(
        data.fields.any((e) => e.key == 'company_ids[]' && e.value == '1'),
        isTrue,
      );
      expect(
        data.fields.any(
          (e) => e.key == 'change_reason' && e.value == draft.changeReason,
        ),
        isTrue,
      );
      expect(
        data.fields.any(
          (e) => e.key == 'base_version' && e.value == managedStore.editVersion,
        ),
        isTrue,
      );
      expect(
        data.fields.any(
          (e) => e.key == 'idempotency_key' && e.value == requestKey,
        ),
        isTrue,
      );
      expect(data.files.single.key, 'pictures[]');
      expect(data.files.single.value.contentType.toString(), 'image/png');
    },
  );
  test(
    'invalid IDs, drafts, account number and non-rejected resubmission never write',
    () async {
      final repo = FakeStoreManagement();
      final useCase = ManageProviderStores(repo);
      await expectLater(useCase.store(0), throwsA(isA<ApiFailure>()));
      await expectLater(
        useCase.requestChange(1, storeDraft(name: ''), requestKey),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        useCase.submit(storeDraft(), requestKey, owner.mobile),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        useCase.submit(
          storeDraft(mobile: owner.mobile, document: true),
          requestKey,
          owner.mobile,
        ),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        useCase.resubmit(pendingApplication(storeDraft()), storeDraft()),
        throwsA(isA<ApiFailure>()),
      );
      expect(repo.writes, 0);
    },
  );
  Future<ProviderContainer> setup(FakeStoreManagement repo) async {
    final c = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(StoreSession.new),
        providerStoreManagementRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    await c.read(sessionControllerProvider.future);
    c.listen(providerStoreWriteProvider('form'), (_, _) {});
    return c;
  }

  test('missing change reason or version never submits a change', () async {
    final repo = FakeStoreManagement();
    final draft = storeDraft();
    for (final invalid in [
      ProviderStoreDraft(
        details: draft.details,
        mobile: draft.mobile,
        baseVersion: draft.baseVersion,
      ),
      ProviderStoreDraft(
        details: draft.details,
        mobile: draft.mobile,
        changeReason: draft.changeReason,
      ),
    ]) {
      await expectLater(
        ManageProviderStores(repo).requestChange(1, invalid, requestKey),
        throwsA(isA<ApiFailure>()),
      );
    }
    expect(repo.writes, 0);
  });

  test(
    'uncertain store change is reconciled by submission key, not store or phone alone',
    () async {
      final repo = FakeStoreManagement()
        ..onUpdate = () async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      final c = await setup(repo);
      final controller = c.read(providerStoreWriteProvider('form').notifier);
      await controller.save(storeDraft(), storeId: 1, requestKey: requestKey);
      repo.applications = [
        pendingApplication(
          storeDraft(),
          storeId: 1,
          submissionKey: 'different-request',
        ),
      ];
      expect(
        await controller.reconcile(
          storeId: 1,
          mobile: storeDraft().mobile,
          requestKey: requestKey,
        ),
        isNull,
      );
      expect(repo.writes, 1);
      await controller.save(storeDraft(), storeId: 1, requestKey: requestKey);
      repo.applications = [pendingApplication(storeDraft(), storeId: 1)];
      expect(
        await controller.reconcile(
          storeId: 1,
          mobile: storeDraft().mobile,
          requestKey: requestKey,
        ),
        11,
      );
      expect(repo.writes, 2);
    },
  );

  test('a confirmed conflict is not treated as a connection timeout', () async {
    final repo = FakeStoreManagement()
      ..onUpdate = () async => throw const ApiFailure(
        type: ApiFailureType.unexpected,
        statusCode: 409,
      );
    final c = await setup(repo);
    await c
        .read(providerStoreWriteProvider('form').notifier)
        .save(storeDraft(), storeId: 1, requestKey: requestKey);
    expect(c.read(providerStoreWriteProvider('form')).uncertain, isFalse);
    expect(c.read(providerStoreWriteProvider('form')).error?.statusCode, 409);
  });

  test('duplicate taps issue one update', () async {
    final pending = Completer<SellerApplication>();
    final repo = FakeStoreManagement()..onUpdate = () => pending.future;
    final c = await setup(repo);
    final controller = c.read(providerStoreWriteProvider('form').notifier);
    final save = controller.save(
      storeDraft(),
      storeId: 1,
      requestKey: requestKey,
    );
    expect(
      await controller.save(storeDraft(), storeId: 1, requestKey: requestKey),
      isNull,
    );
    expect(repo.writes, 1);
    pending.complete(pendingApplication(storeDraft(), storeId: 1));
    expect(await save, 11);
  });
  test(
    'uncertain writes are blocked until an explicit read reconciles status',
    () async {
      final repo = FakeStoreManagement()
        ..onSubmit = () async =>
            throw const ApiFailure(type: ApiFailureType.timeout);
      final c = await setup(repo);
      final controller = c.read(providerStoreWriteProvider('form').notifier);
      await controller.save(storeDraft(document: true), requestKey: requestKey);
      expect(c.read(providerStoreWriteProvider('form')).uncertain, true);
      await controller.save(storeDraft(document: true), requestKey: requestKey);
      expect(repo.writes, 1);
      repo.applications = [pendingApplication(storeDraft())];
      expect(
        await controller.reconcile(
          mobile: '+966522222222',
          requestKey: requestKey,
        ),
        11,
      );
      expect(repo.reads, 1);
      expect(repo.writes, 1);
      expect(c.read(providerStoreWriteProvider('form')).uncertain, false);
    },
  );
  test(
    'late save cannot update UI after logout and same-account login',
    () async {
      final pending = Completer<SellerApplication>();
      final repo = FakeStoreManagement()..onUpdate = () => pending.future;
      final c = await setup(repo);
      final controller = c.read(providerStoreWriteProvider('form').notifier);
      final save = controller.save(
        storeDraft(),
        storeId: 1,
        requestKey: requestKey,
      );
      final session =
          c.read(sessionControllerProvider.notifier) as StoreSession;
      session.replace(const SignedOutSession());
      // A fresh login has a different session identity, even for the same user.
      // ignore: prefer_const_constructors
      session.replace(AuthenticatedSession(owner));
      pending.complete(pendingApplication(storeDraft(), storeId: 1));
      expect(await save, isNull);
    },
  );
}
