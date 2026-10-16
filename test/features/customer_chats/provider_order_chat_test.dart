import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/data/data_sources/chat_remote_data_source.dart';
import 'package:octogear/features/customer_chats/data/repositories/chat_repository_impl.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';

import 'chat_fixtures.dart';

void main() {
  const target = ChatTarget.providerOrder(17);
  Map<String, Object?> summary({int order = 17, int? offer}) => {
    'id': 7,
    'order_id': order,
    'offer_id': offer,
    'other_user': {'id': 3, 'name': 'Saleh Customer'},
    'store': {'id': 2, 'name': 'Octo Parts'},
    'unread_count': 0,
    'can_send': true,
    'updated_at': '2026-10-16T10:00:00Z',
  };

  ChatRepositoryImpl repository(
    Object? Function(RequestOptions) response,
    List<RequestOptions> requests,
  ) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
    final api = ApiClient(
      dio: dio,
      accessTokenResolver: () => 'test',
      localeResolver: () => 'ar',
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {'success': true, 'data': response(request)},
            ),
          );
        },
      ),
    );
    return ChatRepositoryImpl(ChatRemoteDataSource(api));
  }

  for (final offer in <int?>[null, 42]) {
    test(
      'provider opens an order chat without writing for offer $offer',
      () async {
        final calls = <RequestOptions>[];
        final repo = repository(
          (_) => {
            'order_id': 17,
            'offer_id': offer,
            'conversation': null,
            'other_user': {'id': 3, 'name': 'Saleh Customer'},
            'store': {'id': 2, 'name': 'Octo Parts'},
            'can_send': true,
          },
          calls,
        );
        final result = await repo.open(target);
        expect(result.conversation, isNull);
        expect(result.otherUserName, 'Saleh Customer');
        expect(result.offerId, offer);
        expect(result.canSend, true);
        expect(calls.single.path, 'provider/orders/17/conversation');
        expect(calls.single.method, 'GET');
        expect(calls.single.headers['Authorization'], 'Bearer test');
        expect(calls.single.headers['Accept-Language'], 'ar');
      },
    );
  }

  test(
    'provider first send validates the order and adopts the accepted offer chat',
    () async {
      final calls = <RequestOptions>[];
      var order = 17;
      final repo = repository(
        (request) => {
          'conversation': summary(order: order, offer: 42),
          'message': {
            'id': 1,
            'content': 'Hello',
            'is_mine': true,
            'is_read': false,
            'created_at': '2026-10-16T10:00:00Z',
            'client_message_id': 'retry-key',
          },
        },
        calls,
      );
      final receipt = await repo.send(target, 'Hello', 'retry-key');
      expect(receipt.conversation!.offerId, 42);
      expect(calls.single.path, 'provider/orders/17/conversation/messages');
      expect(calls.single.data, {
        'content': 'Hello',
        'client_message_id': 'retry-key',
      });
      order = 99;
      await expectLater(
        repo.send(target, 'Hello', 'retry-key'),
        throwsA(anything),
      );
    },
  );

  test('wrong nested order or offer context is rejected', () async {
    final calls = <RequestOptions>[];
    var nested = summary(order: 99, offer: 42);
    final repo = repository(
      (_) => {
        'order_id': 17,
        'offer_id': 42,
        'conversation': nested,
        'other_user': {'id': 3, 'name': 'Saleh Customer'},
        'store': {'id': 2, 'name': 'Octo Parts'},
        'can_send': true,
      },
      calls,
    );
    await expectLater(repo.open(target), throwsA(anything));
    nested = summary(offer: 99);
    await expectLater(repo.open(target), throwsA(anything));
  });

  test(
    'provider first-send realtime matches the accepted offer on this order',
    () async {
      final events = StreamController<ChatUpdate>.broadcast();
      final repo = FakeChatRepository()
        ..context = const ChatContext(
          orderId: 17,
          offerId: 42,
          otherUserName: 'Saleh Customer',
          storeName: 'Octo Parts',
        );
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
      ChatUpdate update(int offer) => ChatUpdate(
        ChatUpdateKind.message,
        conversationId: 7,
        orderId: 17,
        offerId: offer,
        conversation: const ChatSummary(
          id: 7,
          name: 'Saleh Customer',
          orderId: 17,
          offerId: 42,
        ),
        message: ChatMessage(
          id: 1,
          text: 'Hello',
          mine: false,
          read: false,
          createdAt: DateTime(2026),
        ),
      );
      events.add(update(999));
      await pumpEventQueue();
      expect(
        container.read(chatProvider(target)).requireValue.messages,
        isEmpty,
      );
      events.add(update(42));
      await pumpEventQueue();
      final state = container.read(chatProvider(target)).requireValue;
      expect(state.context.conversation!.id, 7);
      expect(state.context.otherUserName, 'Saleh Customer');
      expect(state.messages.single.text, 'Hello');
    },
  );
}
