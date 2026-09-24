import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_storage.dart';

/// Bootstrapped in `main` after secure storage is warmed. Tests override it
/// with an in-memory implementation.
final appStorageProvider = Provider<AppStorage>((ref) {
  throw StateError(
    'AppStorage must be initialized during application bootstrap.',
  );
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return ref.watch(appStorageProvider);
});

final profileCacheStorageProvider = Provider<ProfileCacheStorage>((ref) {
  return ref.watch(appStorageProvider);
});
