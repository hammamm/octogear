import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(signOutUseCaseProvider).call();
    } finally {
      state = const AsyncData(SignedOutSession());
    }
  }
}
