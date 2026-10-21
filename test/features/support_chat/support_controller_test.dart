import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/support_chat/domain/entities/support_chat.dart';
import 'package:octogear/features/support_chat/data/models/support_dto.dart';
import 'package:octogear/features/support_chat/presentation/controllers/support_providers.dart';
import 'package:octogear/features/notifications/data/models/push_notification_dto.dart';
import 'package:octogear/features/notifications/presentation/notification_destination.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'support_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> flush() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<ProviderContainer> setup(
    FakeSupportRepository repo,
    StreamController<ChatUpdate> events,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(SupportSession.new),
        supportRepositoryProvider.overrideWithValue(repo),
        chatRealtimeUpdatesProvider.overrideWith((ref) => events.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await events.close();
    });
    await container.read(sessionControllerProvider.future);
    container.listen(supportChatProvider, (_, _) {});
    await flush();
    return container;
  }

  test(
    'session startup reads once and socket snapshots update unread without polling',
    () async {
      final repo = FakeSupportRepository();
      final events = StreamController<ChatUpdate>.broadcast();
      final c = await setup(repo, events);
      expect(repo.summaries, 1);
      expect(repo.keys, isEmpty);
      events.add(
        ChatUpdate(
          ChatUpdateKind.support,
          support: SupportUpdate(conversation(version: 3, unread: 2)),
        ),
      );
      await flush();
      expect(c.read(supportChatProvider).conversation!.unread, 2);
      events.add(
        ChatUpdate(
          ChatUpdateKind.support,
          support: SupportUpdate(conversation(version: 2, unread: 1)),
        ),
      );
      await flush();
      expect(c.read(supportChatProvider).conversation!.unread, 2);
      expect(repo.summaries, 1);
    },
  );
  test('late summary cannot replace a newer socket badge', () async {
    final pending = Completer<SupportConversation?>();
    final repo = FakeSupportRepository()..onSummary = () => pending.future;
    final events = StreamController<ChatUpdate>.broadcast();
    final c = await setup(repo, events);
    events.add(
      ChatUpdate(
        ChatUpdateKind.support,
        support: SupportUpdate(conversation(version: 3, unread: 2)),
      ),
    );
    await flush();
    pending.complete(conversation(version: 1));
    await flush();
    expect(c.read(supportChatProvider).conversation!.unread, 2);
  });
  test(
    'failed manual retry preserves UUID and text and does not retry automatically',
    () async {
      final repo = FakeSupportRepository()..failSend = true;
      final events = StreamController<ChatUpdate>.broadcast();
      final c = await setup(repo, events);
      final controller = c.read(supportChatProvider.notifier);
      expect(await controller.send('Help'), false);
      await flush();
      expect(repo.keys.length, 1);
      expect(await controller.send('Changed'), false);
      expect(repo.keys.length, 1);
      repo.failSend = false;
      expect(await controller.send('Help'), true);
      expect(repo.keys[0], repo.keys[1]);
      expect(repo.texts, ['Help', 'Help']);
    },
  );
  test('late send cannot repopulate another session', () async {
    final pending = Completer<SupportReceipt>();
    final repo = FakeSupportRepository()..pendingSend = pending;
    final events = StreamController<ChatUpdate>.broadcast();
    final c = await setup(repo, events);
    final sending = c.read(supportChatProvider.notifier).send('Help');
    (c.read(sessionControllerProvider.notifier) as SupportSession).replace(
      const SignedOutSession(),
    );
    c.read(supportChatProvider);
    pending.complete(SupportReceipt(conversation(), message(1, mine: true)));
    expect(await sending, false);
    expect(c.read(supportChatProvider).conversation, isNull);
  });
  test('closed conversations require explicit reopen', () async {
    final repo = FakeSupportRepository()..current = conversation(closed: true);
    final events = StreamController<ChatUpdate>.broadcast();
    final c = await setup(repo, events);
    final controller = c.read(supportChatProvider.notifier);
    await controller.open();
    expect(repo.reopens, 0);
    expect(await controller.send('Hello'), false);
    expect(repo.keys, isEmpty);
    await controller.reopen();
    expect(repo.reopens, 1);
    expect(c.read(supportChatProvider).conversation!.closed, false);
  });
  test('failed reads keep unread count and explicit retry clears it', () async {
    final repo = FakeSupportRepository()
      ..current = conversation(unread: 2)
      ..failRead = true;
    final events = StreamController<ChatUpdate>.broadcast();
    final c = await setup(repo, events);
    final controller = c.read(supportChatProvider.notifier);
    await controller.markRead(2);
    expect(c.read(supportChatProvider).readError, true);
    expect(c.read(supportChatProvider).conversation!.unread, 2);
    repo.failRead = false;
    await controller.markRead(2);
    expect(c.read(supportChatProvider).conversation!.unread, 0);
  });
  test('live messages do not advance the HTTP reconnect cursor', () async {
    final repo = FakeSupportRepository()
      ..current = conversation(last: 10)
      ..messages = [message(10)];
    final events = StreamController<ChatUpdate>.broadcast();
    final c = await setup(repo, events);
    await c.read(supportChatProvider.notifier).open();
    events.add(
      ChatUpdate(
        ChatUpdateKind.support,
        support: SupportUpdate(
          conversation(version: 3, last: 90),
          message: message(90),
        ),
      ),
    );
    await flush();
    repo.onTimeline = (before, after) async => after == 10
        ? SupportPage(conversation(version: 3, last: 90), [message(50)], true)
        : SupportPage(conversation(version: 3, last: 90), [
            message(90),
            message(51),
          ], false);
    events.add(const ChatUpdate(ChatUpdateKind.connected));
    await flush();
    expect(repo.afters, [null, 10, 50]);
    expect(c.read(supportChatProvider).messages.map((m) => m.id), [
      90,
      51,
      50,
      10,
    ]);
  });
  test(
    'push during summary refresh is reconciled after the in-flight result',
    () async {
      final pending = Completer<SupportConversation?>();
      final repo = FakeSupportRepository()..onSummary = () => pending.future;
      final c = await setup(repo, StreamController<ChatUpdate>.broadcast());
      await c.read(supportChatProvider.notifier).refreshSummary();
      repo.onSummary = () async => conversation(version: 3, unread: 2);
      pending.complete(conversation(version: 1));
      await flush();
      expect(repo.summaries, 2);
      expect(c.read(supportChatProvider).conversation!.unread, 2);
    },
  );
  test(
    'late read acknowledgement cannot erase a newer unread socket snapshot',
    () async {
      final pending = Completer<SupportConversation>();
      final repo = FakeSupportRepository()
        ..current = conversation(unread: 1)
        ..onRead = (_) => pending.future;
      final events = StreamController<ChatUpdate>.broadcast();
      final c = await setup(repo, events);
      final reading = c.read(supportChatProvider.notifier).markRead(1);
      events.add(
        ChatUpdate(
          ChatUpdateKind.support,
          support: SupportUpdate(
            conversation(version: 4, unread: 1, read: 1, last: 2),
          ),
        ),
      );
      await flush();
      pending.complete(conversation(version: 3, read: 1));
      await reading;
      expect(c.read(supportChatProvider).conversation!.unread, 1);
      expect(c.read(supportChatProvider).conversation!.version, 4);
    },
  );
  test('signed-out scope makes no support requests', () async {
    final repo = FakeSupportRepository();
    final c = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(_SignedOutSupportSession.new),
        supportRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(supportChatProvider, (_, _) {});
    await c.read(sessionControllerProvider.future);
    await flush();
    expect(repo.summaries, 0);
    expect(c.read(supportChatProvider).conversation, isNull);
  });

  test('invalid socket shapes are ignored', () {
    expect(parseSupportUpdate({'kind': 'message', 'conversation': {}}), isNull);
    expect(
      () => SupportConversationDto({'status': 'unknown'}),
      throwsFormatException,
    );
  });
  test('support push opens the role-specific support page', () {
    final event = parsePushNotification({
      'notification_id': '12345678-1234-1234-1234-123456789abc',
      'recipient_id': '1',
      'type': 'support_reply',
      'support_conversation_id': '2',
      'support_message_id': '3',
    });
    expect(event, isNotNull);
    expect(
      notificationDestination(event!.item, AppUserRole.customer),
      '/customer/support',
    );
    expect(
      notificationDestination(event.item, AppUserRole.provider),
      '/provider/support',
    );
    expect(event.messageId, 3);
  });
}

class _SignedOutSupportSession extends SessionController {
  @override
  Future<SessionOutcome> build() async => const SignedOutSession();
}
