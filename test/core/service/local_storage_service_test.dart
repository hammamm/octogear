import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahala/core/service/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // token/setToken go through flutter_secure_storage, which has no
  // synchronous, method-channel-free test API the way shared_preferences
  // does (SharedPreferences.setMockInitialValues) - not covered here for
  // the same reason DeviceChecker.os's Android branch wasn't: it's a thin
  // passthrough over a platform channel, better verified on a real device.
  // A mock handler is still needed below so LocalStorageService.initialize
  // (which reads the token to warm its cache) doesn't throw
  // MissingPluginException with no real plugin registered in tests.
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          return call.method == 'read' ? null : true;
        });
    storage = LocalStorageService();
    await storage.initialize();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test('string fields default to null and round-trip a value', () {
    expect(storage.firebaseToken, isNull);
    storage.firebaseToken = 'fcm-token';
    expect(storage.firebaseToken, 'fcm-token');
  });

  test('setting a string field to null removes it', () {
    storage.userId = '123';
    expect(storage.userId, '123');
    storage.userId = null;
    expect(storage.userId, isNull);
  });

  test('every plain string field is independently addressable', () {
    storage
      ..firebaseToken = 'a'
      ..trackingIdentifier = 'b'
      ..source = 'c'
      ..userId = 'd'
      ..mobile = 'e'
      ..email = 'f'
      ..name = 'g'
      ..currentLanguage = 'h'
      ..baseUrl = 'i';

    expect(storage.firebaseToken, 'a');
    expect(storage.trackingIdentifier, 'b');
    expect(storage.source, 'c');
    expect(storage.userId, 'd');
    expect(storage.mobile, 'e');
    expect(storage.email, 'f');
    expect(storage.name, 'g');
    expect(storage.currentLanguage, 'h');
    expect(storage.baseUrl, 'i');
  });

  test('isLoggedIn defaults to false and round-trips', () {
    expect(storage.isLoggedIn, isFalse);
    storage.isLoggedIn = true;
    expect(storage.isLoggedIn, isTrue);
    storage.isLoggedIn = false;
    expect(storage.isLoggedIn, isFalse);
  });

  test('values persisted in a previous session are loaded on initialize', () async {
    SharedPreferences.setMockInitialValues({
      'userId': 'existing-user',
      'isLoggedIn': true,
    });
    final restored = LocalStorageService();
    await restored.initialize();

    expect(restored.userId, 'existing-user');
    expect(restored.isLoggedIn, isTrue);
  });
}
