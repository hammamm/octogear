import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configuration/app_configuration.dart';
import '../localization/app_locale_controller.dart';
import '../storage/storage_providers.dart';
import 'api_client.dart';

/// Immutable deployment configuration. Tests override this provider instead
/// of changing a source constant.
final appConfigurationProvider = Provider<AppConfiguration>((ref) {
  return AppConfiguration.fromDartDefines();
});

/// The one HTTP client used by new OctoGear repositories.
///
/// The resolvers read the current in-memory session and locale at request
/// time, so a newly saved token or locale is applied without rebuilding every
/// repository.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    configuration: ref.watch(appConfigurationProvider),
    accessTokenResolver: () =>
        ref.read(sessionStorageProvider).cachedAccessToken,
    localeResolver: () => ref.read(appLocaleProvider).code,
  );
});
