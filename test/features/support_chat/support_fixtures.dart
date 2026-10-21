import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/support_chat/domain/entities/support_chat.dart';
import 'package:octogear/features/support_chat/domain/repositories/support_repository.dart';

const supportUser = AppUser(
  id: 1,
  fullName: 'Customer',
  mobile: '+966500000001',
  role: AppUserRole.customer,
);

class SupportSession extends SessionController {
  @override
  Future<SessionOutcome> build() async =>
      const AuthenticatedSession(supportUser);
  void replace(SessionOutcome value) => state = AsyncData(value);
}

ChatMessage message(int id, {bool mine = false}) => ChatMessage(
  id: id,
  text: 'Message $id',
  mine: mine,
  read: false,
  createdAt: DateTime.utc(2026, 10, 21),
  clientId: 'key-$id',
);
SupportConversation conversation({
  int version = 1,
  int unread = 0,
  bool closed = false,
  int read = 0,
  int last = 1,
}) => SupportConversation(
  id: 1,
  version: version,
  closed: closed,
  unread: unread,
  userReadThrough: read,
  supportReadThrough: 0,
  lastMessage: message(last),
);

class FakeSupportRepository implements SupportRepository {
  SupportConversation? current;
  List<ChatMessage> messages = [];
  int summaries = 0, reads = 0, reopens = 0;
  bool failSend = false, failRead = false;
  final keys = <String>[], texts = <String>[];
  final afters = <int?>[];
  Future<SupportConversation?> Function()? onSummary;
  Future<SupportPage> Function(int?, int?)? onTimeline;
  Completer<SupportReceipt>? pendingSend;
  Future<SupportConversation> Function(int)? onRead;
  @override
  Future<SupportConversation?> summary() async {
    summaries++;
    return onSummary == null ? current : onSummary!();
  }

  @override
  Future<SupportPage> timeline({int? before, int? after}) async {
    afters.add(after);
    return onTimeline != null
        ? onTimeline!(before, after)
        : SupportPage(current!, messages, false);
  }

  @override
  Future<SupportReceipt> send(String text, String clientId) async {
    keys.add(clientId);
    texts.add(text);
    if (pendingSend != null) return pendingSend!.future;
    if (failSend) throw Exception('offline');
    current = conversation(version: 2);
    final sent = ChatMessage(
      id: 1,
      text: text,
      mine: true,
      read: false,
      createdAt: DateTime.utc(2026),
      clientId: clientId,
    );
    messages = [sent];
    return SupportReceipt(current!, sent);
  }

  @override
  Future<SupportConversation> read(int through) async {
    reads++;
    if (onRead != null) return onRead!(through);
    if (failRead) throw Exception('offline');
    current = conversation(version: (current?.version ?? 1) + 1, read: through);
    return current!;
  }

  @override
  Future<SupportConversation> reopen(int version) async {
    reopens++;
    current = conversation(version: version + 1);
    return current!;
  }
}
