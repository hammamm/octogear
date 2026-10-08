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
}
