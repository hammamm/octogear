import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/api_chat_repository.dart';
import '../../data/chat_remote_data_source.dart';
import '../../domain/chat.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) =>
      ApiChatRepository(ChatRemoteDataSource(ref.watch(apiClientProvider))),
);

final chatInboxProvider =
    AsyncNotifierProvider.autoDispose<ChatInboxController, ChatInbox>(
      ChatInboxController.new,
      retry: (_, _) => null,
    );

class ChatInboxController extends AsyncNotifier<ChatInbox> {
  bool busy = false;
  int _generation = 0;
  @override
  Future<ChatInbox> build() {
    ++_generation;
    ref.onDispose(() => ++_generation);
    ref.watch(appLocaleProvider);
    ref.watch(sessionControllerProvider);
    return ref.watch(chatRepositoryProvider).inbox(1);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (busy || current == null || current.page >= current.lastPage) return;
    busy = true;
    final generation = _generation;
    try {
      final next = await ref
          .read(chatRepositoryProvider)
          .inbox(current.page + 1);
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          ChatInbox(
            {
              for (final c in current.chats) c.id: c,
              for (final c in next.chats) c.id: c,
            }.values.toList(),
            next.page,
            next.lastPage,
          ),
        );
      }
    } finally {
      busy = false;
    }
  }
}

class ChatState {
  const ChatState({
    required this.context,
    this.messages = const [],
    this.hasOlder = false,
    this.loadingOlder = false,
    this.sending = false,
    this.failedText,
    this.clientId,
    this.error,
    this.sendError = false,
  });
  final ChatContext context;
  final List<ChatMessage> messages;
  final bool hasOlder, loadingOlder, sending, sendError;
  final String? failedText, clientId;
  final Object? error;
  ChatState copy({
    ChatContext? context,
    List<ChatMessage>? messages,
    bool? hasOlder,
    bool? loadingOlder,
    bool? sending,
    String? failedText,
    String? clientId,
    Object? error,
    bool? sendError,
    bool clearPending = false,
  }) => ChatState(
    context: context ?? this.context,
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    sending: sending ?? this.sending,
    failedText: clearPending ? null : failedText ?? this.failedText,
    clientId: clearPending ? null : clientId ?? this.clientId,
    error: error ?? ((sendError ?? this.sendError) ? this.error : null),
    sendError: sendError ?? this.sendError,
  );
}

final chatProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, ChatState, ChatTarget>(
      ChatController.new,
      retry: (_, _) => null,
    );

class ChatController extends AsyncNotifier<ChatState> {
  ChatController(this.target);
  final ChatTarget target;
  bool _refreshing = false, _reading = false;
  int _readThrough = 0, _generation = 0, _syncAfter = 0;
  @override
  Future<ChatState> build() async {
    ref.watch(sessionControllerProvider);
    _readThrough = 0;
    final generation = ++_generation;
    ref.onDispose(() => ++_generation);
    final repo = ref.watch(chatRepositoryProvider);
    final context = await repo.open(target);
    final id = context.conversation?.id;
    final page = id == null
        ? const ChatMessages([], false)
        : await repo.messages(id);
    if (ref.mounted && generation == _generation) {
      _syncAfter = page.messages.isEmpty ? 0 : page.messages.first.id;
    }
    return ChatState(
      context: context,
      messages: page.messages,
      hasOlder: page.hasMore,
    );
  }

  List<ChatMessage> _merge(List<ChatMessage> current, List<ChatMessage> next) =>
      ({
        for (final m in current) m.id: m,
        for (final m in next) m.id: m,
      }.values.toList()..sort((a, b) => b.id.compareTo(a.id)));

  Future<bool> send(String text) async {
    final current = state.asData?.value;
    if (current == null || current.sending || !current.context.canSend) {
      return false;
    }
    final content = current.failedText ?? text.trim();
    if (content.isEmpty || content.runes.length > 2000) return false;
    final key = current.clientId ?? const Uuid().v4();
    final generation = _generation;
    state = AsyncData(
      current.copy(
        sending: true,
        failedText: content,
        clientId: key,
        sendError: false,
      ),
    );
    try {
      final id = current.context.conversation?.id;
      final receipt = await ref
          .read(chatRepositoryProvider)
          .send(
            id == null ? target : ChatTarget.conversation(id),
            content,
            key,
          );
      if (!ref.mounted || generation != _generation) return false;
      final latest = state.requireValue;
      final chat = receipt.conversation ?? latest.context.conversation;
      state = AsyncData(
        latest.copy(
          context: ChatContext(
            conversation: chat,
            storeName: latest.context.storeName,
            employeeName: latest.context.employeeName,
            orderId: latest.context.orderId,
            offerId: latest.context.offerId,
          ),
          messages: _merge(latest.messages, [receipt.message]),
          sending: false,
          clearPending: true,
          sendError: false,
        ),
      );
      ref.invalidate(chatInboxProvider);
      return true;
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          state.requireValue.copy(
            sending: false,
            error: error,
            sendError: true,
          ),
        );
      }
      return false;
    }
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null || _refreshing || current.sending) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final repo = ref.read(chatRepositoryProvider);
      final context = await repo.open(
        current.context.conversation == null
            ? target
            : ChatTarget.conversation(current.context.conversation!.id),
      );
      final id = context.conversation?.id;
      if (id == null) {
        if (ref.mounted && generation == _generation) {
          final latest = state.requireValue;
          state = AsyncData(
            latest.copy(
              context: context,
              error: latest.sendError ? latest.error : null,
            ),
          );
        }
        return;
      }
      final newer = await repo.messages(id, after: _syncAfter);
      if (!ref.mounted || generation != _generation) return;
      // A send receipt may jump ahead of incoming messages not fetched yet.
      for (final message in newer.messages) {
        if (message.id > _syncAfter) _syncAfter = message.id;
      }
      final latest = state.requireValue;
      state = AsyncData(
        latest.copy(
          context: context,
          messages: _merge(latest.messages, newer.messages),
          hasOlder: latest.messages.isEmpty ? newer.hasMore : latest.hasOlder,
          error: latest.sendError ? latest.error : null,
        ),
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(state.requireValue.copy(error: error));
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> older() async {
    final current = state.asData?.value;
    if (current == null ||
        current.loadingOlder ||
        !current.hasOlder ||
        current.messages.isEmpty) {
      return;
    }
    final generation = _generation;
    state = AsyncData(current.copy(loadingOlder: true));
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .messages(
            current.context.conversation!.id,
            before: current.messages.last.id,
          );
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          state.requireValue.copy(
            messages: _merge(state.requireValue.messages, page.messages),
            hasOlder: page.hasMore,
            loadingOlder: false,
          ),
        );
      }
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          state.requireValue.copy(loadingOlder: false, error: error),
        );
      }
    }
  }

  Future<void> markRead() async {
    final current = state.asData?.value;
    if (current == null ||
        current.messages.isEmpty ||
        _reading ||
        current.error != null ||
        current.context.conversation == null) {
      return;
    }
    final through = _syncAfter;
    if (through <= _readThrough) return;
    if (!current.messages.any(
      (message) => !message.mine && !message.read && message.id > _readThrough,
    )) {
      _readThrough = through;
      return;
    }
    _reading = true;
    final generation = _generation;
    try {
      await ref
          .read(chatRepositoryProvider)
          .markRead(current.context.conversation!.id, through);
      if (ref.mounted && generation == _generation) {
        _readThrough = through;
        ref.invalidate(chatInboxProvider);
      }
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(state.requireValue.copy(error: error));
      }
    } finally {
      _reading = false;
    }
  }
}
