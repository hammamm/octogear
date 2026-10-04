import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'api_configuration_loader.dart';
import 'app_configuration.dart';

class FirebaseApiConfigurationSource implements ApiConfigurationSource {
  FirebaseApiConfigurationSource(this.remoteConfig);

  final FirebaseRemoteConfig remoteConfig;

  @override
  Future<void> fetch(AppEnvironment environment) async {
    await remoteConfig.ensureInitialized();
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ),
    );
    // No embedded URL default: a fresh install requires a published parameter.
    // False also means values are already active, not that fetching failed.
    await remoteConfig.fetchAndActivate();
  }

  @override
  String get apiBaseUrl =>
      remoteConfig.getString(AppConfiguration.apiBaseUrlKey);
}
