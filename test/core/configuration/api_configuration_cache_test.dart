import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'validated URL persists across storage instances and session clearing',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = AppStorage(secureStorage: _SecureStorage());
      await first.initialize();
      await first.saveApiBaseUrl('development', 'https://dev.test/api');
      await first.saveApiBaseUrl('production', 'https://prod.test/api');
      await first.clearSession();

      final nextLaunch = AppStorage(secureStorage: _SecureStorage());
      await nextLaunch.initialize();
      expect(nextLaunch.readApiBaseUrl('development'), 'https://dev.test/api');
      expect(nextLaunch.readApiBaseUrl('production'), 'https://prod.test/api');
      expect(nextLaunch.readApiBaseUrl('staging'), isNull);
    },
  );
}

class _SecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}
