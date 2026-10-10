import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/customer_chats/data/data_sources/chat_realtime_data_source.dart';
import 'package:octogear/features/customer_chats/data/models/chat_realtime_dto.dart';
import 'package:octogear/features/customer_chats/data/repositories/pusher_chat_realtime_repository.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat_update.dart';

void main() {
  test(
    'real WebSocket handshake authorizes, receives messages, reconnects and pauses',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <WebSocket>[];
      final requests = <Map<String, dynamic>>[];
      final listener = server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        sockets.add(socket);
        socket.add(
          jsonEncode({
            'event': 'pusher:connection_established',
            'data': jsonEncode({
              'socket_id': '${sockets.length}.1',
              'activity_timeout': 120,
            }),
          }),
        );
        socket.listen((raw) {
          final event = jsonDecode(raw as String) as Map<String, dynamic>;
          requests.add(event);
          if (event['event'] == 'pusher:subscribe') {
            socket.add(
              jsonEncode({
                'event': 'pusher_internal:subscription_succeeded',
                'channel': 'private-chat.sessions.1',
                'data': '{}',
              }),
            );
          }
        });
      });
      final source = _Source(
        Uri.parse('ws://127.0.0.1:${server.port}/app/key'),
      );
      final repository = PusherChatRealtimeRepository(source, userId: 9);
      final updates = <ChatUpdate>[];
      final subscription = repository.updates.listen(updates.add);
      addTearDown(() async {
        await repository.dispose();
        await subscription.cancel();
        for (final socket in sockets) {
          await socket.close();
        }
        await listener.cancel();
        await server.close(force: true);
      });
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 12));
        while (!condition()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('WebSocket condition timed out');
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      await repository.connect();
      await until(() => updates.any((u) => u.kind == ChatUpdateKind.connected));
      expect(source.authorizations, ['1.1:private-chat.sessions.1']);
      expect((requests.single['data'] as Map)['auth'], 'key:signature');
      // Focus returning from an inactive state must reuse a healthy connection.
      await repository.connect();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(sockets, hasLength(1));
      expect(source.authorizations, hasLength(1));
      sockets.single.add(
        jsonEncode({
          'event': 'chat.updated',
          'channel': 'private-chat.sessions.1',
          'data': jsonEncode({
            'kind': 'message',
            'conversation_id': 7,
            'message': {
              'id': 4,
              'sender_id': 8,
              'content': 'Hello over WebSocket',
              'is_read': false,
              'created_at': '2026-10-09T01:00:00Z',
            },
          }),
        }),
      );
      await until(() => updates.any((u) => u.kind == ChatUpdateKind.message));
      expect(updates.last.message!.text, 'Hello over WebSocket');
      expect(updates.last.message!.mine, isFalse);
      await sockets.single.close();
      await until(
        () =>
            updates.where((u) => u.kind == ChatUpdateKind.connected).length ==
            2,
      );
      expect(source.authorizations, hasLength(2));
      repository.pause();
      final connections = sockets.length;
      await Future<void>.delayed(const Duration(seconds: 4));
      expect(sockets.length, connections);
    },
  );
}

class _Source extends ChatRealtimeDataSource {
  _Source(this.url) : super(ApiClient(dio: Dio()), allowInsecure: true);
  final Uri url;
  final authorizations = <String>[];
  @override
  Future<ChatSocketConfiguration?> configuration() async =>
      ChatSocketConfiguration(url, 'private-chat.sessions.1');
  @override
  Future<String> authorize(String socketId, String channel) async {
    authorizations.add('$socketId:$channel');
    return 'key:signature';
  }
}
