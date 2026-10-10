import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/session_controller.dart';

/// New activity outside Chats, not a server unread-message count. Visiting the
/// tab clears the dot without marking conversations or notifications as read.
final chatActivityProvider = NotifierProvider<ChatActivityController, bool>(
  ChatActivityController.new,
);

class ChatActivityController extends Notifier<bool> {
  final Set<String> _seen = {};
  @override
  bool build() {
    ref.watch(sessionControllerProvider);
    _seen.clear();
    return false;
  }

  bool receive({required String key, required bool chatsVisible}) {
    if (!_seen.add(key)) return false;
    if (_seen.length > 512) _seen.remove(_seen.first);
    if (chatsVisible) return false;
    state = true;
    return true;
  }

  void viewed() => state = false;
}
