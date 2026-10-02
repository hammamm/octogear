import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Release visibility only; API authorization remains the server's job.
/// Enable with --dart-define=OCTOGEAR_STORES_ENABLED=true to restore Stores.
final customerStoresEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('OCTOGEAR_STORES_ENABLED'),
);
