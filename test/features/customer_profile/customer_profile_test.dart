import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_profile/data/data_sources/customer_profile_remote_data_source.dart';
import 'package:octogear/features/customer_profile/data/repositories/customer_profile_repository_impl.dart';
import 'package:octogear/features/customer_profile/domain/entities/update_customer_profile_command.dart';
import 'package:octogear/features/customer_profile/domain/use_cases/update_customer_profile_use_case.dart';
import 'package:octogear/features/customer_profile/presentation/controllers/customer_profile_controller.dart';

import 'profile_fixtures.dart';

const command = UpdateCustomerProfileCommand(
  fullName: '  Updated Name  ',
  cityId: 2,
);

void main() {
  test(
    'PATCH sends only the trimmed name and city and maps the returned profile',
    () async {
      final requests = <RequestOptions>[];
      Object? data = {
        'id': 1,
        'full_name': 'Updated Name',
        'mobile': profileUser.mobile,
        'type': 'customer',
        'city': {'id': 2, 'name': 'Jeddah'},
      };
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test-token',
        localeResolver: () => 'ar',
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': data},
              ),
            );
          },
        ),
      );
      final update = UpdateCustomerProfileUseCase(
        CustomerProfileRepositoryImpl(CustomerProfileRemoteDataSourceImpl(api)),
      );
      final result = await update(profileUser, command);
      expect(result.fullName, 'Updated Name');
      expect(result.city!.name, 'Jeddah');
      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, 'customer/profile');
      expect(requests.single.data, {'full_name': 'Updated Name', 'city_id': 2});
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
      expect(requests.single.headers['Accept-Language'], 'ar');
      for (final invalid in [
        null,
        {'id': 1},
        {...data as Map, 'type': 'unknown'},
        {...data, 'mobile': 'wrong'},
      ]) {
        final previous = data;
        data = invalid;
        await expectLater(
          update(profileUser, command),
          throwsA(isA<ApiFailure>()),
        );
        data = previous;
      }
    },
  );

  test('invalid names and city IDs never reach the repository', () async {
    final repo = FakeProfileRepository();
    final update = UpdateCustomerProfileUseCase(repo);
    for (final invalid in [
      const UpdateCustomerProfileCommand(fullName: '   ', cityId: 1),
      UpdateCustomerProfileCommand(fullName: 'A' * 101, cityId: 1),
      const UpdateCustomerProfileCommand(fullName: 'Name', cityId: 0),
    ]) {
      await expectLater(
        update(profileUser, invalid),
        throwsA(isA<ApiFailure>()),
      );
    }
    expect(repo.commands, isEmpty);
  });

  Future<ProviderContainer> setup(FakeProfileRepository repo) async {
    final c = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(ProfileSession.new),
        customerProfileRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    await c.read(sessionControllerProvider.future);
    c.listen(customerProfileControllerProvider(1), (_, _) {});
    return c;
  }

  test(
    'concurrent taps send one update and refresh session without loading',
    () async {
      final pending = Completer<AppUser>();
      final repo = FakeProfileRepository()..onUpdate = (_) => pending.future;
      final c = await setup(repo);
      final sessions = <AsyncValue<SessionOutcome>>[];
      c.listen(sessionControllerProvider, (_, next) => sessions.add(next));
      final controller = c.read(customerProfileControllerProvider(1).notifier);
      final save = controller.save(command);
      expect(await controller.save(command), isNull);
      expect(repo.commands, hasLength(1));
      pending.complete(savedProfile(repo.commands.single));
      expect((await save)!.fullName, 'Updated Name');
      expect(
        (c.read(sessionControllerProvider).requireValue as AuthenticatedSession)
            .user
            .city!
            .id,
        2,
      );
      expect(sessions.any((value) => value.isLoading), false);
    },
  );

  test('failure preserves session and allows an explicit retry only', () async {
    final repo = FakeProfileRepository()
      ..onUpdate = (_) async =>
          throw const ApiFailure(type: ApiFailureType.timeout);
    final c = await setup(repo);
    final controller = c.read(customerProfileControllerProvider(1).notifier);
    expect(await controller.save(command), isNull);
    expect(repo.commands, hasLength(1));
    expect(
      c.read(customerProfileControllerProvider(1)).error!.type,
      ApiFailureType.timeout,
    );
    expect(
      (c.read(sessionControllerProvider).requireValue as AuthenticatedSession)
          .user
          .fullName,
      profileUser.fullName,
    );
    repo.onUpdate = null;
    expect(await controller.save(command), isNotNull);
    expect(repo.commands, hasLength(2));
  });

  for (final relogin in [false, true]) {
    test(
      'late save cannot restore or overwrite a replaced session (relogin=$relogin)',
      () async {
        final pending = Completer<AppUser>();
        final repo = FakeProfileRepository()..onUpdate = (_) => pending.future;
        final c = await setup(repo);
        final save = c
            .read(customerProfileControllerProvider(1).notifier)
            .save(command);
        final session =
            c.read(sessionControllerProvider.notifier) as ProfileSession;
        session.replace(const SignedOutSession());
        if (relogin) {
          // A new login must have a distinct session identity, even for the same user.
          // ignore: prefer_const_constructors
          session.replace(AuthenticatedSession(profileUser));
        }
        pending.complete(savedProfile(repo.commands.single));
        expect(await save, isNull);
        final current = c.read(sessionControllerProvider).requireValue;
        if (relogin) {
          expect(
            (current as AuthenticatedSession).user.fullName,
            profileUser.fullName,
          );
        } else {
          expect(current, isA<SignedOutSession>());
        }
      },
    );
  }
}
