import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/data/data_sources/chat_remote_data_source.dart';
import 'package:octogear/features/customer_chats/data/models/chat_dto.dart';
import 'package:octogear/features/customer_chats/data/repositories/chat_repository_impl.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';

import 'chat_fixtures.dart';

void main() {
  const target = ChatTarget.offer(17, 42);
  Future<ProviderContainer> setup(FakeChatRepository repo) async {
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        sessionControllerProvider.overrideWith(ChatTestSession.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    container.listen(chatProvider(target), (_, _) {});
    await container.read(chatProvider(target).future);
    return container;
  }

  test(
    'opening is read only; first send trims and adopts conversation',
    () async {
      final repo = FakeChatRepository();
      final c = await setup(repo);
      expect(repo.sends, 0);
      expect(
        c.read(chatProvider(target)).requireValue.context.conversation,
        isNull,
      );
      expect(await c.read(chatProvider(target).notifier).send('   '), false);
      expect(await c.read(chatProvider(target).notifier).send(' Hello '), true);
      expect(repo.contents, ['Hello']);
      expect(
        c.read(chatProvider(target)).requireValue.context.conversation!.id,
        7,
      );
    },
  );
  test(
    'uncertain send retains exact text/key; concurrent taps do not send twice',
    () async {
      final repo = FakeChatRepository()..failSend = true;
      final c = await setup(repo);
      final controller = c.read(chatProvider(target).notifier);
      expect(await controller.send('Hello'), false);
      repo.failSend = false;
      final pending = Completer<ChatReceipt>();
      repo.onSend = (_, _, _) => pending.future;
      final retry = controller.send('Different');
      expect(await controller.send('Third'), false);
      expect(repo.contents, ['Hello', 'Hello']);
      expect(repo.keys.toSet(), hasLength(1));
      pending.complete(
        ChatReceipt(
          ChatMessage(
            id: 1,
            text: 'Hello',
            mine: true,
            read: false,
            createdAt: DateTime.now(),
          ),
          sampleChat,
        ),
      );
      expect(await retry, true);
      expect(c.read(chatProvider(target)).requireValue.failedText, isNull);
    },
  );
  test(
    'older pages merge without duplicates and refresh does not skip a burst',
    () async {
      ChatMessage msg(int id) => ChatMessage(
        id: id,
        text: '$id',
        mine: false,
        read: false,
        createdAt: DateTime.now(),
      );
      final repo = FakeChatRepository()
        ..context = const ChatContext(conversation: sampleChat)
        ..page = ChatMessages([msg(10), msg(9)], true);
      final c = await setup(repo);
      final controller = c.read(chatProvider(target).notifier);
      repo.onMessages = (before, after) async {
        if (before != null) {
          expect(before, 9);
          return ChatMessages([msg(9), msg(8)], false);
        }
        if (after == 10) return ChatMessages([msg(12), msg(11)], true);
        expect(after, 12);
        return const ChatMessages([], false);
      };
      await controller.older();
      await controller.refresh();
      expect(
        c.read(chatProvider(target)).requireValue.messages.map((m) => m.id),
        [12, 11, 10, 9, 8],
      );
    },
  );
  test(
    'read failures do not loop and read writes stop after successful boundary',
    () async {
      final repo = FakeChatRepository()
        ..context = const ChatContext(conversation: sampleChat)
        ..page = ChatMessages([
          ChatMessage(
            id: 1,
            text: 'Hi',
            mine: false,
            read: false,
            createdAt: DateTime.now(),
          ),
        ], false)
        ..failRead = true;
      final c = await setup(repo);
      final controller = c.read(chatProvider(target).notifier);
      await controller.markRead();
      await controller.markRead();
      expect(repo.reads, 1);
      repo.failRead = false;
      await controller.refresh();
      await controller.markRead();
      await controller.markRead();
      expect(repo.reads, 2);
    },
  );
  test(
    'a send receipt cannot skip incoming messages not yet fetched',
    () async {
      ChatMessage msg(int id) => ChatMessage(
        id: id,
        text: '$id',
        mine: false,
        read: false,
        createdAt: DateTime.now(),
      );
      final repo = FakeChatRepository()
        ..context = const ChatContext(conversation: sampleChat)
        ..page = ChatMessages([msg(10)], false);
      final c = await setup(repo);
      final controller = c.read(chatProvider(target).notifier);
      repo.onSend = (_, _, _) async => ChatReceipt(msg(100), sampleChat);
      await controller.send('Hello');
      repo.onMessages = (_, after) async {
        expect(after, 10);
        return ChatMessages([msg(12), msg(11)], true);
      };
      await controller.refresh();
      repo.onMessages = (_, after) async {
        expect(after, 12);
        return ChatMessages([msg(100), msg(13)], false);
      };
      await controller.refresh();
      expect(
        c.read(chatProvider(target)).requireValue.messages.map((m) => m.id),
        [100, 13, 12, 11, 10],
      );
    },
  );
  test('loading history preserves a failed-send retry', () {
    final failed = ChatState(
      context: const ChatContext(),
      failedText: 'Hello',
      clientId: 'key',
      error: Exception('offline'),
      sendError: true,
    );
    final loading = failed.copy(loadingOlder: true);
    expect(loading.error, isNotNull);
    expect(loading.failedText, 'Hello');
    expect(loading.copy(sendError: false).error, isNull);
  });
  test(
    'malformed messages fail instead of inventing timestamps or ownership',
    () {
      expect(
        () => chatMessage({'id': 1, 'content': 'Hello'}),
        throwsFormatException,
      );
      expect(
        () => chatMessage({
          'id': 1,
          'content': 'Hello',
          'is_mine': true,
          'is_read': false,
          'created_at': 'bad',
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'open endpoint sends authenticated localized GET without creating a chat',
    () async {
      final calls = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test',
        localeResolver: () => 'ar',
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'conversation': null,
                    'can_send': true,
                    'order_id': 17,
                    'offer_id': 42,
                    'store': {
                      'id': 2,
                      'name': 'Store',
                      'employee_name': 'Ahmed',
                    },
                  },
                },
              ),
            );
          },
        ),
      );
      final result = await ChatRepositoryImpl(
        ChatRemoteDataSource(api),
      ).open(target);
      expect(result, isA<ChatContext>());
      expect(result.employeeName, 'Ahmed');
      expect(result.conversation, isNull);
      expect(calls.single.method, 'GET');
      expect(calls.single.path, 'customer/orders/17/offers/42/conversation');
      expect(calls.single.headers['Authorization'], 'Bearer test');
      expect(calls.single.headers['Accept-Language'], 'ar');
    },
  );
}
