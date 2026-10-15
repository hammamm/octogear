import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'city preferences survive restart, stay account scoped and can be cleared',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final storage = AppStorage();
      await storage.initialize();
      expect(storage.readProviderOrderCity(1), isNull);
      await storage.saveProviderOrderCity(1, 2);
      await storage.saveProviderOrderCity(3, 4);
      final restarted = AppStorage();
      await restarted.initialize();
      expect(restarted.readProviderOrderCity(1), 2);
      expect(restarted.readProviderOrderCity(3), 4);
      await restarted.saveProviderOrderCity(1, null);
      expect(restarted.readProviderOrderCity(1), isNull);
      expect(restarted.readProviderOrderCity(3), 4);
      await expectLater(
        restarted.saveProviderOrderCity(1, 0),
        throwsArgumentError,
      );
    },
  );
}
