import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/domain/repositories/chat_repository.dart';

const sampleChat = ChatSummary(
  id: 7,
  name: 'Store owner',
  storeName: 'Octo Parts',
  employeeName: 'Ahmed',
  orderId: 17,
  offerId: 42,
);

class ChatTestSession extends SessionController {
  @override
  Future<SessionOutcome> build() async => const SignedOutSession();
}

class FakeChatRepository implements ChatRepository {
  ChatContext context = const ChatContext(
    storeName: 'Octo Parts',
    employeeName: 'Ahmed',
    orderId: 17,
    offerId: 42,
  );
  ChatMessages page = const ChatMessages([], false);
  int opens = 0, sends = 0, reads = 0, inboxCalls = 0;
  bool failSend = false, failRead = false;
  final keys = <String>[];
  final contents = <String>[];
  final readBoundaries = <int>[];
  Future<void> Function(int through)? onRead;
  Future<ChatReceipt> Function(ChatTarget, String, String)? onSend;
  Future<ChatMessages> Function(int?, int?)? onMessages;
  @override
  Future<ChatContext> open(ChatTarget target) async {
    opens++;
    return context;
  }

  @override
  Future<ChatInbox> inbox(int page) async {
    inboxCalls++;
    return const ChatInbox([], 1, 1);
  }

  @override
  Future<ChatMessages> messages(int id, {int? before, int? after}) async =>
      onMessages != null ? onMessages!(before, after) : page;
  @override
  Future<ChatReceipt> send(
    ChatTarget target,
    String text,
    String clientId,
  ) async {
    sends++;
    keys.add(clientId);
    contents.add(text);
    if (onSend != null) return onSend!(target, text, clientId);
    if (failSend) throw Exception('offline');
    context = const ChatContext(
      conversation: sampleChat,
      storeName: 'Octo Parts',
      employeeName: 'Ahmed',
      orderId: 17,
      offerId: 42,
    );
    return ChatReceipt(
      ChatMessage(
        id: sends,
        text: text,
        mine: true,
        read: false,
        createdAt: DateTime(2026, 10, 4, 10, 30),
        clientId: clientId,
      ),
      sampleChat,
    );
  }

  @override
  Future<void> markRead(int id, int through) async {
    reads++;
    readBoundaries.add(through);
    if (onRead != null) await onRead!(through);
    if (failRead) throw Exception('offline');
  }
}
