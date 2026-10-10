import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/domain/use_cases/restore_session_use_case.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_providers.dart';
import 'seller_fixtures.dart';
import 'package:octogear/features/authentication/presentation/widgets/session_refresh_scope.dart';

class _Restore implements RestoreSessionUseCase {
  Future<SessionOutcome> Function() response = () async =>
      const AuthenticatedSession(sellerUser);
  @override
  Future<SessionOutcome> call() => response();
}

const _approved = AppUser(
  id: 1,
  fullName: 'Store Owner',
  mobile: '+966500000001',
  role: AppUserRole.provider,
);

void main() {
  testWidgets('reopening from background refreshes the approved role', (
    tester,
  ) async {
    final restore = _Restore();
    final container = ProviderContainer(
      overrides: [restoreSessionUseCaseProvider.overrideWithValue(restore)],
    );
    addTearDown(container.dispose);
    final original = await container.read(sessionControllerProvider.future);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    void reopen() {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SessionRefreshScope(child: SizedBox()),
      ),
    );
    reopen();
    await tester.pumpAndSettle();
    // Returning from the photo picker keeps the session identity and draft.
    expect(container.read(sessionControllerProvider).value, same(original));
    restore.response = () async => const AuthenticatedSession(_approved);
    reopen();
    await tester.pumpAndSettle();
    expect(
      (container.read(sessionControllerProvider).value as AuthenticatedSession)
          .user
          .role,
      AppUserRole.provider,
    );
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'authoritative profile refresh applies approval and survives offline reads',
    () async {
      final restore = _Restore();
      final container = ProviderContainer(
        overrides: [restoreSessionUseCaseProvider.overrideWithValue(restore)],
      );
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);
      final controller = container.read(sessionControllerProvider.notifier);
      restore.response = () async => const UnavailableSession(
        ApiFailure(type: ApiFailureType.noConnection),
      );
      await controller.refreshProfile();
      expect(
        (container.read(sessionControllerProvider).value
                as AuthenticatedSession)
            .user
            .role,
        AppUserRole.customer,
      );
      restore.response = () async => const AuthenticatedSession(_approved);
      await controller.refreshProfile();
      expect(
        (container.read(sessionControllerProvider).value
                as AuthenticatedSession)
            .user
            .role,
        AppUserRole.provider,
      );
    },
  );

  test('approval response cannot replace a newer session', () async {
    final restore = _Restore();
    final container = ProviderContainer(
      overrides: [restoreSessionUseCaseProvider.overrideWithValue(restore)],
    );
    addTearDown(container.dispose);
    final original =
        await container.read(sessionControllerProvider.future)
            as AuthenticatedSession;
    final controller = container.read(sessionControllerProvider.notifier);
    final gate = Completer<SessionOutcome>();
    restore.response = () => gate.future;
    final pending = controller.refreshProfile();
    expect(
      controller.applyProfileUpdate(expected: original, user: sellerUser),
      true,
    );
    gate.complete(const AuthenticatedSession(_approved));
    await pending;
    expect(
      (container.read(sessionControllerProvider).value as AuthenticatedSession)
          .user
          .role,
      AppUserRole.customer,
    );
  });
}
