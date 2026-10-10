import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/customer_notifications/data/models/push_notification_dto.dart';
import 'package:octogear/features/customer_notifications/domain/entities/push_notification.dart';
import 'package:octogear/features/customer_notifications/domain/repositories/push_repository.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/push_delivery_controller.dart';

Map<String, dynamic> payload({String recipient = '1'}) => {
  'notification_id': '12345678-1234-1234-1234-123456789abc',
  'recipient_id': recipient,
  'type': 'new_offer',
  'order_id': '17',
  'offer_id': '42',
};

class FakePushRepository implements PushRepository {
  final foregroundEvents = StreamController<PushNotification>.broadcast();
  final openedEvents = StreamController<PushNotification>.broadcast();
  final tokens = StreamController<String>.broadcast();
  final registrations = <String>[];
  bool allowed = true, failRegistration = false;
  String deviceToken = 'token-one';
  int removals = 0, deletions = 0;
  Completer<String?>? pendingToken;
  Completer<PushNotification?>? initial;
  @override
  Stream<PushNotification> get foreground => foregroundEvents.stream;
  @override
  Stream<PushNotification> get opened => openedEvents.stream;
  @override
  Stream<String> get tokenChanges => tokens.stream;
  @override
  Future<PushNotification?> initialNotification() async => initial?.future;
  @override
  Future<bool> permission({required bool request}) async => allowed;
  @override
  Future<String?> token() async =>
      pendingToken == null ? deviceToken : pendingToken!.future;
  @override
  Future<void> register(String token, String locale) async {
    if (failRegistration) throw StateError('offline');
    registrations.add('$token|$locale');
  }

  @override
  Future<void> unregister() async {
    removals++;
  }

  @override
  Future<void> deleteToken() async {
    deletions++;
  }

  @override
  Future<void> openSettings() async {}
  Future<void> dispose() async {
    await foregroundEvents.close();
    await openedEvents.close();
    await tokens.close();
  }
}

void main() {
  late FakePushRepository repo;
  late PushDeliveryController controller;
  setUp(() {
    repo = FakePushRepository();
    controller = PushDeliveryController(repo)..initialize();
  });
  tearDown(() async {
    await controller.dispose();
    await repo.dispose();
  });
  void login({int id = 1, String locale = 'en'}) =>
      controller.bind(userId: id, sessionKey: 'session-$id', locale: locale);

  test('untrusted push payloads cannot supply arbitrary navigation', () {
    expect(parsePushNotification(payload())?.item.canOpen, true);
    for (final data in [
      {...payload(), 'type': 'unknown', 'url': 'https://example.com'},
      {...payload(), 'notification_id': 'invalid'},
      {...payload(), 'offer_id': '-1'},
      {...payload(), 'order_id': '../settings'},
      {...payload(), 'recipient_id': '0'},
      {...payload(), 'order_id': 17},
    ]) {
      expect(parsePushNotification(data), isNull);
    }
  });

  test(
    'login registers once; resume does not repeat an unchanged registration',
    () async {
      login();
      await controller.sync();
      await controller.sync();
      expect(repo.registrations, ['token-one|en']);
      controller.bind(userId: 1, sessionKey: 'session-1', locale: 'ar');
      await controller.sync();
      expect(repo.registrations.last, 'token-one|ar');
    },
  );

  test('token rotation updates the existing login registration', () async {
    login();
    await controller.sync();
    repo.deviceToken = 'token-two';
    repo.tokens.add('token-two');
    await Future<void>.delayed(Duration.zero);
    await controller.sync();
    expect(repo.registrations, ['token-one|en', 'token-two|en']);
  });

  test(
    'denied permission removes registration without registering a token',
    () async {
      repo.allowed = false;
      login();
      await controller.sync();
      expect(repo.registrations, isEmpty);
      expect(repo.removals, greaterThan(0));
      repo.allowed = true;
      await controller.sync();
      expect(repo.registrations, ['token-one|en']);
    },
  );

  test(
    'failed registration retries at the next explicit lifecycle event',
    () async {
      repo.failRegistration = true;
      login();
      await controller.sync();
      expect(repo.registrations, isEmpty);
      repo.failRegistration = false;
      await controller.sync();
      expect(repo.registrations, ['token-one|en']);
    },
  );

  test('late token cannot register against a different account', () async {
    final waiting = Completer<String?>();
    repo.pendingToken = waiting;
    login();
    await Future<void>.delayed(Duration.zero);
    login(id: 2);
    repo.pendingToken = null;
    repo.deviceToken = 'account-two';
    waiting.complete('account-one');
    await controller.sync();
    expect(repo.registrations, ['account-two|en']);
  });

  test(
    'logout invalidates pending work and deletes the installation token',
    () async {
      final waiting = Completer<String?>();
      repo.pendingToken = waiting;
      login();
      await Future<void>.delayed(Duration.zero);
      final logout = controller.prepareSignOut();
      waiting.complete('late');
      await logout;
      expect(repo.registrations, isEmpty);
      expect(repo.deletions, 1);
      repo.tokens.add('later');
      await Future<void>.delayed(Duration.zero);
      await controller.sync();
      expect(repo.registrations, isEmpty);
    },
  );

  test(
    'foreground and tap events are deduplicated and recipient scoped',
    () async {
      final received = <PushNotification>[], opened = <PushNotification>[];
      controller.received.listen(received.add);
      controller.opened.listen(opened.add);
      login();
      await controller.sync();
      final event = parsePushNotification(payload())!;
      repo.foregroundEvents.add(event);
      repo.foregroundEvents.add(event);
      repo.foregroundEvents.add(
        parsePushNotification(payload(recipient: '2'))!,
      );
      repo.openedEvents.add(event);
      repo.openedEvents.add(event);
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      expect(opened, hasLength(1));
      expect(repo.registrations, hasLength(1));
    },
  );

  test(
    'cold start waits for session restore before opening its destination',
    () async {
      // Recreate to inject an asynchronous cold-start message before initialization.
      await controller.dispose();
      repo.initial = Completer<PushNotification?>();
      controller = PushDeliveryController(repo)..initialize();
      final opened = <PushNotification>[];
      controller.opened.listen(opened.add);
      repo.initial!.complete(parsePushNotification(payload()));
      await Future<void>.delayed(Duration.zero);
      expect(opened, isEmpty);
      login();
      await controller.sync();
      expect(opened, hasLength(1));
    },
  );
}
