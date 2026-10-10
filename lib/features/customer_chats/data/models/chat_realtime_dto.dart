import 'dart:convert';

import '../../domain/entities/chat.dart';
import '../../domain/entities/chat_update.dart';
import 'chat_dto.dart';

class ChatSocketConfiguration {
  const ChatSocketConfiguration(this.url, this.channel);
  final Uri url;
  final String channel;

  static ChatSocketConfiguration? parse(
    Object? value, {
    required bool allowInsecure,
  }) {
    if (value is! Map || value['enabled'] is! bool) {
      throw const FormatException('Invalid realtime configuration');
    }
    if (value['enabled'] == false) return null;
    final address = value['url'];
    final url = address is String ? Uri.tryParse(address) : null;
    // Uri knows HTTP's default ports, but treats an omitted ws/wss port and
    // explicit :0 alike. Parse the HTTP equivalent to distinguish those cases.
    final port = address is String && url != null
        ? Uri.tryParse(
            address.replaceFirst(
              RegExp(r'^[^:]+:'),
              url.scheme == 'wss' ? 'https:' : 'http:',
            ),
          )?.port
        : null;
    final channel = value['channel'];
    if (url == null ||
        !url.hasAuthority ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment ||
        port == null ||
        port < 1 ||
        port > 65535 ||
        (url.scheme != 'wss' && !(allowInsecure && url.scheme == 'ws')) ||
        channel is! String ||
        !RegExp(r'^private-chat\.sessions\.[1-9][0-9]*$').hasMatch(channel)) {
      throw const FormatException('Invalid realtime destination');
    }
    return ChatSocketConfiguration(
      url.replace(
        port: port,
        queryParameters: {
          'protocol': '7',
          'client': 'octogear',
          'version': '1.0',
        },
      ),
      channel,
    );
  }
}

ChatUpdate? parseChatUpdate(Object? raw, int userId) {
  try {
    final value = raw is String ? jsonDecode(raw) : raw;
    if (value is! Map) return null;
    int positive(Object? v) {
      if (v is! int || v < 1) throw const FormatException('Invalid ID');
      return v;
    }

    final conversation = positive(value['conversation_id']);
    ChatSummary? summary;
    DateTime? snapshotAt;
    if (value['conversation'] != null) {
      final data = chatMap(value['conversation']);
      final customer = positive(data['customer_id']) == userId;
      summary = chatSummary({
        ...data,
        'other_user': {
          'name': data[customer ? 'provider_name' : 'customer_name'],
        },
        'unread_count': data[customer ? 'customer_unread' : 'provider_unread'],
      }).toEntity();
      if (summary.id != conversation) return null;
      snapshotAt = chatDate(value['snapshot_at']);
    }
    final offer = value['offer_id'] == null
        ? null
        : positive(value['offer_id']);
    final order = value['order_id'] == null
        ? null
        : positive(value['order_id']);
    if (value['kind'] == 'read') {
      return ChatUpdate(
        ChatUpdateKind.read,
        conversation: summary,
        snapshotAt: snapshotAt,
        conversationId: conversation,
        offerId: offer,
        orderId: order,
        readerIsMe: positive(value['reader_id']) == userId,
        throughId: positive(value['through_id']),
      );
    }
    if (value['kind'] != 'message' || value['message'] is! Map) return null;
    final message = value['message'] as Map;
    final content = message['content'];
    final date = message['created_at'];
    final key = message['client_message_id'];
    if (content is! String ||
        content.isEmpty ||
        content.runes.length > 2000 ||
        message['is_read'] is! bool ||
        date is! String ||
        (key != null && key is! String)) {
      return null;
    }
    final createdAt = DateTime.tryParse(date);
    if (createdAt == null) return null;
    return ChatUpdate(
      ChatUpdateKind.message,
      conversation: summary,
      snapshotAt: snapshotAt,
      conversationId: conversation,
      offerId: offer,
      orderId: order,
      message: ChatMessage(
        id: positive(message['id']),
        text: content,
        mine: positive(message['sender_id']) == userId,
        read: message['is_read'] as bool,
        createdAt: createdAt,
        clientId: key as String?,
      ),
    );
  } on FormatException {
    return null;
  }
}
