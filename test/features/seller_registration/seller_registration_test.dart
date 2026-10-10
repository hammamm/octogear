import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/api/api_providers.dart';
import 'package:octogear/core/configuration/app_configuration.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/seller_registration/data/models/seller_application_dto.dart';
import 'package:octogear/features/seller_registration/data/data_sources/seller_registration_remote_data_source.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_application.dart';
import 'package:octogear/features/seller_registration/domain/use_cases/submit_seller_application.dart';
import 'package:octogear/features/seller_registration/presentation/controllers/seller_registration_controller.dart';
import 'seller_fixtures.dart';

void main() {
  final provider = sellerRegistrationControllerProvider(1);
  Future<ProviderContainer> setup(
    FakeSellerRepository repo, {
    AppEnvironment environment = AppEnvironment.staging,
  }) async {
    final c = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(SellerSession.new),
        sellerRegistrationRepositoryProvider.overrideWithValue(repo),
        appConfigurationProvider.overrideWithValue(
          AppConfiguration(
            environment: environment,
            apiBaseUrl: 'https://example.test/api',
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(provider, (_, _) {});
    await c.read(sessionControllerProvider.future);
    await c.read(provider.notifier).load();
    return c;
  }

  for (final environment in AppEnvironment.values) {
    test(
      'OTP is visible only in permitted environments: $environment',
      () async {
        final repo = FakeSellerRepository();
        final c = await setup(repo, environment: environment);
        final flow = c.read(provider.notifier);
        expect(await flow.sendCode('0500000002'), true);
        expect(
          c.read(provider).testCode,
          environment == AppEnvironment.production ? null : '0042',
        );
        expect(await flow.sendCode('0500000002'), false);
        expect(repo.sends, 1);
        expect(await flow.verify('0042'), true);
        expect(c.read(provider).testCode, isNull);
        expect(await flow.submit(sellerDraft()), true);
        expect(
          c.read(provider).application!.status,
          SellerApplicationStatus.pending,
        );
        expect(
          (c.read(sessionControllerProvider).value as AuthenticatedSession)
              .user
              .role,
          sellerUser.role,
        );
      },
    );
  }

  test(
    'same account phone is rejected without sending; unverified submission blocked',
    () async {
      final repo = FakeSellerRepository();
      final c = await setup(repo);
      final flow = c.read(provider.notifier);
      expect(await flow.sendCode(sellerUser.mobile), false);
      expect(await flow.submit(sellerDraft()), false);
      expect(repo.sends, 0);
      expect(repo.submits, 0);
    },
  );

  test(
    'duplicate submit and uncertain retries are blocked until status is read',
    () async {
      final repo = FakeSellerRepository();
      final c = await setup(repo);
      final flow = c.read(provider.notifier);
      await flow.sendCode('0500000002');
      await flow.verify('0042');
      final gate = Completer<SellerApplication>();
      repo.onSubmit = () => gate.future;
      final pending = flow.submit(sellerDraft());
      expect(await flow.submit(sellerDraft()), false);
      gate.completeError(const ApiFailure(type: ApiFailureType.timeout));
      expect(await pending, false);
      expect(c.read(provider).uncertain, true);
      expect(await flow.submit(sellerDraft()), false);
      repo.current = sellerApplication();
      await flow.load();
      expect(c.read(provider).uncertain, false);
      expect(c.read(provider).application!.id, 7);
      expect(repo.submits, 1);
    },
  );

  test(
    'rejected application can be corrected without repeating phone verification',
    () async {
      final repo = FakeSellerRepository()
        ..current = sellerApplication(
          status: SellerApplicationStatus.rejected,
          reason: 'Correct the name',
        );
      final c = await setup(repo);
      expect(
        await c.read(provider.notifier).submit(sellerDraft(document: false)),
        true,
      );
      expect(repo.corrections, 1);
      expect(repo.sends, 0);
      expect(
        c.read(provider).application!.status,
        SellerApplicationStatus.pending,
      );
    },
  );

  test(
    'approval triggers authoritative profile refresh; late responses cannot enter another session',
    () async {
      final repo = FakeSellerRepository()
        ..current = sellerApplication(status: SellerApplicationStatus.accepted);
      final c = await setup(repo);
      expect(
        (c.read(sessionControllerProvider.notifier) as SellerSession).refreshes,
        1,
      );
      repo.current = null;
      await c.read(provider.notifier).load();
      final gate = Completer<String?>();
      repo.onSend = () => gate.future;
      final operation = c.read(provider.notifier).sendCode('0500000002');
      (c.read(sessionControllerProvider.notifier) as SellerSession).replace(
        const SignedOutSession(),
      );
      gate.complete('9999');
      expect(await operation, false);
      expect(c.read(provider).testCode, isNull);
    },
  );

  test(
    'load errors block starting an application; malformed responses never count as saved',
    () async {
      final repo = FakeSellerRepository()
        ..onLoad = () async =>
            throw const ApiFailure(type: ApiFailureType.noConnection);
      final c = await setup(repo);
      expect(c.read(provider).loadFailed, true);
      for (final value in [
        null,
        {'id': 1},
        {
          'id': 7,
          'city': {'id': 1, 'name': 'Riyadh'},
          'request_status': 'unknown',
        },
      ]) {
        expect(() => sellerApplicationFromJson(value), throwsFormatException);
      }
      await expectLater(
        SubmitSellerApplication(repo)(
          sellerDraft(document: false),
          token: 'token',
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(repo.submits, 0);
    },
  );

  test(
    'multipart routes send authenticated, localized data with a fresh document',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'session',
        localeResolver: () => 'ar',
      );
      final payload = {
        'id': 7,
        'name': 'Octo Parts',
        'nick_name': 'Octo',
        'employee_name': 'Store Owner',
        'mobile': '+966500000002',
        'url_location': 'https://maps.example.test/store',
        'commercial_registration_number': '1234567890',
        'request_status': 'pending',
        'city': {'id': 1, 'name': 'Riyadh'},
        'commercial_registration_picture':
            '/api/media/store-requests/7/registration',
      };
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': request.path == 'provider/store-requests'
                      ? {'store_request': payload, 'type': 'customer'}
                      : payload,
                },
              ),
            );
          },
        ),
      );
      final remote = SellerRegistrationRemoteDataSource(api);
      await remote.submit(sellerDraft(companies: [1, 2]), token: 'once');
      await remote.submit(sellerDraft(document: false), requestId: 7);
      expect(requests.map((r) => r.path), [
        'provider/store-requests',
        'customer/seller-application/7/resubmit',
      ]);
      for (final r in requests) {
        expect(r.headers['Authorization'], 'Bearer session');
        expect(r.headers['Accept-Language'], 'ar');
      }
      final first = requests[0].data as FormData,
          second = requests[1].data as FormData;
      expect(Map.fromEntries(first.fields)['temp_token'], 'once');
      expect(
        first.fields
            .where((field) => field.key == 'company_ids[]')
            .map((field) => field.value),
        ['1', '2'],
      );
      expect(Map.fromEntries(second.fields)['company_ids'], '');
      expect(first.files.single.key, 'commercial_registration_picture');
      expect(Map.fromEntries(second.fields).containsKey('temp_token'), false);
      expect(Map.fromEntries(second.fields).containsKey('mobile'), false);
      expect(second.files, isEmpty);
    },
  );
}
