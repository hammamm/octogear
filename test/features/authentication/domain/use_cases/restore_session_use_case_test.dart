import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/storage/app_storage.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/domain/repositories/session_repository.dart';
import 'package:octogear/features/authentication/domain/use_cases/restore_session_use_case.dart';

void main() {
  group('RestoreSessionUseCase', () {
    test('opens authentication without a stored token', () async {
      final storage = _FakeSessionStorage();
      final repository = _FakeSessionRepository(user: _customer);

      final result = await _useCase(storage, repository).call();

      expect(result, isA<SignedOutSession>());
      expect(repository.getProfileCalls, 0);
      expect(storage.clearSessionCalls, 0);
    });

    test(
      'returns an authenticated customer after a valid profile response',
      () async {
        final storage = _FakeSessionStorage(accessToken: 'valid-token');
        final repository = _FakeSessionRepository(user: _customer);

        final result = await _useCase(storage, repository).call();

        expect(result, isA<AuthenticatedSession>());
        expect(
          (result as AuthenticatedSession).user.role,
          AppUserRole.customer,
        );
        expect(repository.getProfileCalls, 1);
        expect(storage.clearSessionCalls, 0);
      },
    );

    test(
      'returns an authenticated provider after a valid profile response',
      () async {
        final storage = _FakeSessionStorage(accessToken: 'valid-token');
        final repository = _FakeSessionRepository(user: _provider);

        final result = await _useCase(storage, repository).call();

        expect(result, isA<AuthenticatedSession>());
        expect(
          (result as AuthenticatedSession).user.role,
          AppUserRole.provider,
        );
        expect(storage.clearSessionCalls, 0);
      },
    );

    test(
      'clears the stored session only when the profile request returns 401',
      () async {
        final storage = _FakeSessionStorage(accessToken: 'expired-token');
        final repository = _FakeSessionRepository(
          failure: const ApiFailure(type: ApiFailureType.unauthorized),
        );

        final result = await _useCase(storage, repository).call();

        expect(result, isA<SignedOutSession>());
        expect(storage.clearSessionCalls, 1);
        expect(storage.cachedAccessToken, isNull);
      },
    );

    test('keeps the token for retryable and permission failures', () async {
      const failures = [
        ApiFailure(type: ApiFailureType.timeout),
        ApiFailure(type: ApiFailureType.noConnection),
        ApiFailure(type: ApiFailureType.server),
        ApiFailure(type: ApiFailureType.forbidden),
      ];

      for (final failure in failures) {
        final storage = _FakeSessionStorage(accessToken: 'keep-this-token');
        final repository = _FakeSessionRepository(failure: failure);

        final result = await _useCase(storage, repository).call();

        expect(result, isA<UnavailableSession>());
        expect((result as UnavailableSession).failure, same(failure));
        expect(storage.clearSessionCalls, 0);
        expect(storage.cachedAccessToken, 'keep-this-token');
      }
    });
  });
}

RestoreSessionUseCase _useCase(
  SessionStorage storage,
  SessionRepository repository,
) {
  return RestoreSessionUseCase(
    sessionStorage: storage,
    sessionRepository: repository,
  );
}

const _customer = AppUser(
  id: 1,
  fullName: 'Customer One',
  mobile: '500000001',
  role: AppUserRole.customer,
);

const _provider = AppUser(
  id: 2,
  fullName: 'Provider One',
  mobile: '500000002',
  role: AppUserRole.provider,
);

class _FakeSessionStorage implements SessionStorage {
  _FakeSessionStorage({String? accessToken}) : _accessToken = accessToken;

  String? _accessToken;
  int clearSessionCalls = 0;

  @override
  String? get cachedAccessToken => _accessToken;

  @override
  Future<void> clearSession() async {
    clearSessionCalls++;
    _accessToken = null;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }
}

class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository({this.user, this.failure});

  final AppUser? user;
  final Object? failure;
  int getProfileCalls = 0;

  @override
  Future<AppUser> getProfile() async {
    getProfileCalls++;
    if (failure != null) throw failure!;
    return user!;
  }
}
