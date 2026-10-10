import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/chat.dart';
import '../models/chat_dto.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource(this.api);
  final ApiClient api;
  String _offer(ChatTarget target) =>
      'customer/orders/${target.orderId}/offers/${target.offerId}/conversation';

  Future<ChatContextDto> open(ChatTarget target) async {
    final result = await api.get(
      target.conversationId != null
          ? 'conversations/${target.conversationId}'
          : _offer(target),
      requiresAuthentication: true,
      decode: (value) {
        if (target.conversationId != null) {
          final chat = chatSummary(value);
          if (chat.id != target.conversationId) {
            throw const FormatException('Wrong conversation');
          }
          return ChatContextDto(
            conversation: chat,
            storeName: chat.storeName,
            employeeName: chat.employeeName,
            orderId: chat.orderId,
            offerId: chat.offerId,
          );
        }
        final json = chatMap(value);
        if (json['order_id'] != target.orderId ||
            json['offer_id'] != target.offerId) {
          throw const FormatException('Wrong offer');
        }
        final store = json['store'] == null ? null : chatMap(json['store']);
        if (json['can_send'] is! bool) {
          throw const FormatException('Missing send permission');
        }
        final conversation = json['conversation'] == null
            ? null
            : chatSummary(json['conversation']);
        if (conversation != null &&
            (conversation.offerId != target.offerId ||
                conversation.orderId != target.orderId)) {
          throw const FormatException('Wrong offer conversation');
        }
        return ChatContextDto(
          conversation: conversation,
          canStart: json['can_send'] as bool,
          storeName: chatText(store?['name']),
          employeeName: chatText(store?['employee_name']),
          orderId: target.orderId,
          offerId: target.offerId,
        );
      },
    );
    return result.data ?? (throw const ApiFailure.unexpected());
  }

  Future<ChatInboxDto> inbox(int page) async {
    final result = await api.get(
      'conversations',
      requiresAuthentication: true,
      queryParameters: {'page': page, 'with_messages': true},
      decode: (value) => (value as List).map(chatSummary).toList(),
    );
    final meta = result.pagination;
    if (meta == null || result.data == null || meta.currentPage != page) {
      throw const ApiFailure.unexpected();
    }
    return ChatInboxDto(result.data!, meta.currentPage, meta.lastPage);
  }

  Future<ChatMessagesDto> messages(int id, {int? before, int? after}) async {
    final result = await api.get(
      'conversations/$id/timeline',
      requiresAuthentication: true,
      queryParameters: {'before_id': ?before, 'after_id': ?after},
      decode: (value) {
        final json = chatMap(value);
        return ChatMessagesDto(
          (json['messages'] as List).map(chatMessage).toList(),
          json['has_more'] as bool,
          readThroughId: switch (json['read_through_id']) {
            null => 0,
            int value when value >= 0 => value,
            _ => throw const FormatException('Invalid read boundary'),
          },
        );
      },
    );
    return result.data ?? (throw const ApiFailure.unexpected());
  }

  Future<ChatReceiptDto> send(
    ChatTarget target,
    String text,
    String clientId,
  ) async {
    final first = target.conversationId == null;
    final result = await api.post(
      first
          ? '${_offer(target)}/messages'
          : 'conversations/${target.conversationId}/messages',
      requiresAuthentication: true,
      data: {'content': text, 'client_message_id': clientId},
      decode: (value) {
        final json = chatMap(value);
        final message = chatMessage(first ? json['message'] : json);
        if (message.clientId != clientId ||
            message.text != text ||
            !message.mine) {
          throw const FormatException('Wrong message receipt');
        }
        final chat = first ? chatSummary(json['conversation']) : null;
        if (first &&
            (chat!.offerId != target.offerId ||
                chat.orderId != target.orderId)) {
          throw const FormatException('Wrong conversation receipt');
        }
        return ChatReceiptDto(message, chat);
      },
    );
    return result.data ?? (throw const ApiFailure.unexpected());
  }

  Future<void> markRead(int id, int through) async {
    final result = await api.patch(
      'conversations/$id/read',
      requiresAuthentication: true,
      data: {'through_id': through},
      decode: (value) => chatMap(value)['through_id'] == through,
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }
}
