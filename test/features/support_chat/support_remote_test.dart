import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/support_chat/data/data_sources/support_remote_data_source.dart';
import 'support_wire.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? response;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'message': 'OK', 'data': response}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'support HTTP contract keeps authentication, locale, pagination and write identity',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'))
        ..httpClientAdapter = adapter;
      final source = SupportRemoteDataSource(
        ApiClient(
          dio: dio,
          accessTokenResolver: () => 'session-a',
          localeResolver: () => 'ar',
        ),
        'session-a',
      );
      expect(await source.summary(), isNull);
      adapter.response = {
        'conversation': wireConversation(),
        'messages': [wireMessage()],
        'has_more': false,
      };
      final page = await source.timeline(after: 1);
      expect(page.entity.messages.single.mine, false);
      expect(adapter.requests.last.queryParameters, {'after_id': 1});
      adapter.response = {
        'conversation': wireConversation(),
        'message': wireMessage(),
      };
      await source.send('Help', 'retry-key');
      final send = adapter.requests.last;
      expect(send.path, 'support/conversation/messages');
      expect(send.method, 'POST');
      expect(send.data, {'content': 'Help', 'client_message_id': 'retry-key'});
      expect(send.headers['Authorization'], 'Bearer session-a');
      expect(send.headers['Accept-Language'], 'ar');
      adapter.response = wireConversation();
      await source.read(2);
      expect(adapter.requests.last.data, {'through_id': 2});
      await source.reopen(3);
      expect(adapter.requests.last.data, {'version': 3});
      expect(adapter.requests.last.method, 'PATCH');
      adapter.response = null;
      await expectLater(
        source.send('Help', 'retry-key'),
        throwsA(isA<ApiFailure>()),
      );
      dio.close();
    },
  );
  test(
    'all support writes reject a changed session before reaching the network',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'))
        ..httpClientAdapter = adapter;
      final source = SupportRemoteDataSource(
        ApiClient(dio: dio, accessTokenResolver: () => 'session-b'),
        'session-a',
      );
      await expectLater(source.send('Help', 'key'), throwsA(isA<ApiFailure>()));
      await expectLater(source.read(2), throwsA(isA<ApiFailure>()));
      await expectLater(source.reopen(3), throwsA(isA<ApiFailure>()));
      expect(adapter.requests, isEmpty);
      dio.close();
    },
  );
}
