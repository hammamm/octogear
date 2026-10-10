import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/data/models/chat_realtime_dto.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';

import 'chat_fixtures.dart';
import 'chat_screen_test.dart' show English;

void main() {
  const target = ChatTarget.conversation(7);
  ChatMessage message(int id, {bool mine = false, bool read = false}) =>
      ChatMessage(
        id: id,
        text: 'Message $id',
        mine: mine,
        read: read,
        createdAt: DateTime(2026),
      );
  Future<(ProviderContainer, StreamController<ChatUpdate>, FakeChatRepository)>
  setup() async {
    final events = StreamController<ChatUpdate>.broadcast();
    final repo = FakeChatRepository()
      ..context = const ChatContext(conversation: sampleChat)
      ..page = ChatMessages([message(1)], false);
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        sessionControllerProvider.overrideWith(ChatTestSession.new),
        chatRealtimeUpdatesProvider.overrideWith((_) => events.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await events.close();
    });
    await container.read(sessionControllerProvider.future);
    container.listen(chatProvider(target), (_, _) {});
    await container.read(chatProvider(target).future);
    await pumpEventQueue();
    return (container, events, repo);
  }

  test(
    'incoming messages render directly without a GET and duplicate echoes are merged',
    () async {
      final (container, events, repo) = await setup();
      final opens = repo.opens;
      for (var i = 0; i < 2; i++) {
        events.add(
          ChatUpdate(
            ChatUpdateKind.message,
            conversationId: 7,
            message: message(2),
          ),
        );
      }
      events.add(
        ChatUpdate(
          ChatUpdateKind.message,
          conversationId: 999,
          message: message(3),
        ),
      );
      await pumpEventQueue();
      expect(
        container
            .read(chatProvider(target))
            .requireValue
            .messages
            .map((m) => m.id),
        [2, 1],
      );
      expect(repo.opens, opens);
    },
  );

  test(
    'inbox snapshots and read receipts update locally without HTTP refreshes',
    () async {
      final events = StreamController<ChatUpdate>.broadcast();
      final repo = FakeChatRepository();
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          sessionControllerProvider.overrideWith(ChatTestSession.new),
          appLocaleProvider.overrideWith(English.new),
          chatRealtimeUpdatesProvider.overrideWith((_) => events.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await events.close();
      });
      await container.read(sessionControllerProvider.future);
      container.listen(chatInboxProvider, (_, _) {});
      await container.read(chatInboxProvider.future);
      await pumpEventQueue();
      final calls = repo.inboxCalls;
      final message = ChatUpdate(
        ChatUpdateKind.message,
        conversationId: 7,
        conversation: const ChatSummary(
          id: 7,
          name: 'Store',
          latestText: 'Hello',
          unread: 1,
        ),
        snapshotAt: DateTime(2026),
      );
      events.add(message);
      events.add(message);
      await pumpEventQueue();
      expect(
        container.read(chatInboxProvider).requireValue.chats.single.unread,
        1,
      );
      events.add(
        ChatUpdate(
          ChatUpdateKind.read,
          conversationId: 7,
          readerIsMe: true,
          throughId: 1,
          conversation: const ChatSummary(
            id: 7,
            name: 'Store',
            latestText: 'Hello',
            unread: 0,
          ),
          snapshotAt: DateTime(2026, 1, 2),
        ),
      );
      events.add(message); // Delayed old snapshot cannot resurrect the badge.
      await pumpEventQueue();
      expect(
        container.read(chatInboxProvider).requireValue.chats.single.unread,
        0,
      );
      expect(repo.inboxCalls, calls);
    },
  );

  test(
    'read receipts remain monotonic across duplicate and out-of-order message events',
    () async {
      final (container, events, _) = await setup();
      events.add(
        const ChatUpdate(
          ChatUpdateKind.read,
          conversationId: 7,
          readerIsMe: false,
          throughId: 9,
        ),
      );
      events.add(
        ChatUpdate(
          ChatUpdateKind.message,
          conversationId: 7,
          message: message(9, mine: true),
        ),
      );
      events.add(
        const ChatUpdate(
          ChatUpdateKind.read,
          conversationId: 7,
          readerIsMe: false,
          throughId: 3,
        ),
      );
      events.add(
        ChatUpdate(
          ChatUpdateKind.message,
          conversationId: 7,
          message: message(9, mine: true),
        ),
      );
      await pumpEventQueue();
      expect(
        container.read(chatProvider(target)).requireValue.messages.first.read,
        isTrue,
      );
    },
  );

  test(
    'reconnect drains missed pages without skipping older messages behind a live event',
    () async {
      final (container, events, repo) = await setup();
      final cursors = <int?>[];
      repo.onMessages = (_, after) async {
        cursors.add(after);
        if (after == 1) return ChatMessages([message(3), message(2)], true);
        return ChatMessages([message(4)], false);
      };
      events.add(
        ChatUpdate(
          ChatUpdateKind.message,
          conversationId: 7,
          message: message(4),
        ),
      );
      events.add(const ChatUpdate(ChatUpdateKind.connected));
      await pumpEventQueue();
      expect(cursors, [1, 3]);
      expect(
        container
            .read(chatProvider(target))
            .requireValue
            .messages
            .map((m) => m.id),
        [4, 3, 2, 1],
      );
    },
  );

  test(
    'reconnect restores missed read receipts even with no new messages',
    () async {
      final (container, events, repo) = await setup();
      events.add(
        ChatUpdate(
          ChatUpdateKind.message,
          conversationId: 7,
          message: message(2, mine: true),
        ),
      );
      await pumpEventQueue();
      expect(
        container.read(chatProvider(target)).requireValue.messages.first.read,
        isFalse,
      );
      repo.onMessages = (_, _) async =>
          const ChatMessages([], false, readThroughId: 2);
      events.add(const ChatUpdate(ChatUpdateKind.connected));
      await pumpEventQueue();
      expect(
        container.read(chatProvider(target)).requireValue.messages.first.read,
        isTrue,
      );
    },
  );

  test(
    'socket data is validated and mine is calculated from the authenticated user',
    () {
      final payload = {
        'kind': 'message',
        'conversation_id': 7,
        'offer_id': 42,
        'order_id': 17,
        'message': {
          'id': 1,
          'sender_id': 3,
          'content': 'Hello',
          'is_read': false,
          'client_message_id': null,
          'created_at': '2026-10-09T10:00:00Z',
        },
      };
      expect(parseChatUpdate(payload, 3)!.message!.mine, isTrue);
      expect(parseChatUpdate(payload, 4)!.message!.mine, isFalse);
      expect(
        parseChatUpdate({...payload, 'kind': 'client-message'}, 3),
        isNull,
      );
      expect(parseChatUpdate({...payload, 'conversation_id': -1}, 3), isNull);
      expect(parseChatUpdate('not JSON', 3), isNull);
    },
  );

  test(
    'conversation snapshots decode each participant and preserve latest message ordering',
    () {
      final payload = {
        'kind': 'read',
        'conversation_id': 7,
        'reader_id': 3,
        'through_id': 99,
        'snapshot_at': '2026-10-09T10:00:00Z',
        'conversation': {
          'id': 7,
          'customer_id': 3,
          'customer_name': 'Customer',
          'provider_name': 'Store',
          'customer_unread': 2,
          'provider_unread': 0,
          'can_send': true,
          'latest_message': {'id': 99, 'content': 'Hello'},
          'updated_at': '2026-10-09T09:59:00Z',
        },
      };
      final customer = parseChatUpdate(payload, 3)!.conversation!;
      final provider = parseChatUpdate(payload, 4)!.conversation!;
      expect(customer.name, 'Store');
      expect(customer.unread, 2);
      expect(customer.latestMessageId, 99);
      expect(provider.name, 'Customer');
      expect(provider.unread, 0);
    },
  );

  test(
    'WebSocket configuration accepts implicit and explicit standard ports',
    () {
      ChatSocketConfiguration parse(String url, {bool development = false}) =>
          ChatSocketConfiguration.parse({
            'enabled': true,
            'url': url,
            'channel': 'private-chat.sessions.4',
          }, allowInsecure: development)!;

      for (final address in [
        'wss://chat.example.com/app/key',
        'wss://chat.example.com:443/app/key',
      ]) {
        final configuration = parse(address);
        expect(configuration.url.port, 443);
        expect(configuration.url.path, '/app/key');
        expect(configuration.url.queryParameters['protocol'], '7');
        expect(configuration.channel, 'private-chat.sessions.4');
      }
      expect(parse('wss://chat.example.com:8443/app/key').url.port, 8443);
      expect(parse('ws://localhost/app/key', development: true).url.port, 80);
      for (final port in [0, 65536]) {
        expect(
          () => parse('wss://chat.example.com:$port/app/key'),
          throwsFormatException,
        );
      }
      expect(
        () => parse('ws://chat.example.com/app/key'),
        throwsFormatException,
      );
    },
  );

  test('production config requires WSS and a private session channel', () {
    final config = {
      'enabled': true,
      'url': 'ws://localhost:8080/app/key',
      'channel': 'private-chat.sessions.1',
    };
    expect(
      () => ChatSocketConfiguration.parse(config, allowInsecure: false),
      throwsFormatException,
    );
    expect(
      ChatSocketConfiguration.parse(config, allowInsecure: true)!.url.scheme,
      'ws',
    );
    expect(
      () => ChatSocketConfiguration.parse({
        ...config,
        'channel': 'public-chat',
      }, allowInsecure: true),
      throwsFormatException,
    );
    expect(
      ChatSocketConfiguration.parse({'enabled': false}, allowInsecure: false),
      isNull,
    );
  });
}
