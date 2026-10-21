import '../../../customer_chats/domain/entities/chat.dart';
import '../../domain/entities/support_chat.dart';

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid support object');
  }
  return value;
}

int _int(Map<String, dynamic> value, String key, {int min = 0}) {
  final n = value[key];
  if (n is! int || n < min) {
    throw const FormatException('Invalid support number');
  }
  return n;
}

class SupportMessageDto {
  SupportMessageDto(Object? value) {
    final map = _map(value);
    final text = map['content'],
        sender = map['sender_kind'],
        client = map['client_message_id'];
    final time = map['created_at'] is String
        ? DateTime.tryParse(map['created_at'])
        : null;
    if (text is! String ||
        !['user', 'admin'].contains(sender) ||
        time == null ||
        client is! String) {
      throw const FormatException('Invalid support message');
    }
    entity = ChatMessage(
      id: _int(map, 'id', min: 1),
      text: text,
      mine: sender == 'user',
      read: false,
      createdAt: time,
      clientId: client,
    );
  }
  late final ChatMessage entity;
}

class SupportConversationDto {
  SupportConversationDto(Object? value) {
    final map = _map(value);
    if (!['open', 'closed'].contains(map['status'])) {
      throw const FormatException('Invalid support status');
    }
    entity = SupportConversation(
      id: _int(map, 'id', min: 1),
      version: _int(map, 'version', min: 1),
      closed: map['status'] == 'closed',
      unread: _int(map, 'unread_count'),
      userReadThrough: _int(map, 'user_read_through_id'),
      supportReadThrough: _int(map, 'support_read_through_id'),
      lastMessage: map['last_message'] == null
          ? null
          : SupportMessageDto(map['last_message']).entity,
    );
  }
  late final SupportConversation entity;
}

class SupportPageDto {
  SupportPageDto(Object? value) {
    final map = _map(value);
    if (map['messages'] is! List || map['has_more'] is! bool) {
      throw const FormatException('Invalid support timeline');
    }
    entity = SupportPage(
      SupportConversationDto(map['conversation']).entity,
      List.unmodifiable(
        (map['messages'] as List).map((m) => SupportMessageDto(m).entity),
      ),
      map['has_more'],
    );
  }
  late final SupportPage entity;
}

class SupportReceiptDto {
  SupportReceiptDto(Object? value) {
    final map = _map(value);
    entity = SupportReceipt(
      SupportConversationDto(map['conversation']).entity,
      SupportMessageDto(map['message']).entity,
    );
  }
  late final SupportReceipt entity;
}

SupportUpdate? parseSupportUpdate(Object? value) {
  try {
    final map = _map(value);
    if (!['message', 'read', 'status'].contains(map['kind'])) return null;
    return SupportUpdate(
      SupportConversationDto(map['conversation']).entity,
      message: map['message'] == null
          ? null
          : SupportMessageDto(map['message']).entity,
    );
  } on FormatException {
    return null;
  }
}
