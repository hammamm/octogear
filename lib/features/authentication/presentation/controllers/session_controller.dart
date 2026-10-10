import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/session_outcome.dart';
import 'session_providers.dart';

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionOutcome>(
      SessionController.new,
    );

class SessionController extends AsyncNotifier<SessionOutcome> {
  @override
  Future<SessionOutcome> build() {
    return ref.read(restoreSessionUseCaseProvider).call();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(restoreSessionUseCaseProvider).call(),
    );
  }

  /// Update profile presentation without a session-loading redirect. Only the
  /// session that started the save may receive its response, even after relogin.
  bool applyProfileUpdate({
    required AuthenticatedSession expected,
    required AppUser user,
  }) {
    if (!identical(state.asData?.value, expected) ||
        user.id != expected.user.id ||
        user.mobile != expected.user.mobile ||
        user.role != expected.user.role) {
      return false;
    }
    state = AsyncData(AuthenticatedSession(user));
    return true;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(signOutUseCaseProvider).call();
    } finally {
      state = const AsyncData(SignedOutSession());
    }
  }

  /// Recheck approval without disrupting the current customer screen on an
  /// offline response. Only the session that initiated the read is updated.
  Future<void> refreshProfile({bool roleChangesOnly = false}) async {
    final expected = state.asData?.value;
    if (expected is! AuthenticatedSession) return;
    final SessionOutcome refreshed;
    try {
      refreshed = await ref.read(restoreSessionUseCaseProvider).call();
    } catch (_) {
      // A transient storage/read failure must not discard the active session.
      return;
    }
    if (!ref.mounted || !identical(state.asData?.value, expected)) return;
    if (refreshed is AuthenticatedSession &&
        refreshed.user.id == expected.user.id &&
        refreshed.user.mobile == expected.user.mobile) {
      if (roleChangesOnly && refreshed.user.role == expected.user.role) return;
      state = AsyncData(refreshed);
    } else if (refreshed is SignedOutSession) {
      state = const AsyncData(SignedOutSession());
    }
  }
}
