import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/features/customer_chats/domain/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/chat_update.dart';
import 'chat_realtime_providers.dart';
import '../../domain/use_cases/get_chat_inbox_use_case.dart';
import '../../domain/use_cases/get_chat_messages_use_case.dart';
import '../../domain/use_cases/mark_chat_read_use_case.dart';
import '../../domain/use_cases/open_chat_use_case.dart';
import '../../domain/use_cases/send_chat_message_use_case.dart';

final chatRemoteDataSourceProvider = Provider(
  (ref) => ChatRemoteDataSource(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider)),
);

final openChatProvider = Provider(
  (ref) => OpenChatUseCase(ref.watch(chatRepositoryProvider)),
);

final getChatInboxProvider = Provider(
  (ref) => GetChatInboxUseCase(ref.watch(chatRepositoryProvider)),
);

final getChatMessagesProvider = Provider(
  (ref) => GetChatMessagesUseCase(ref.watch(chatRepositoryProvider)),
);

final sendChatMessageProvider = Provider(
  (ref) => SendChatMessageUseCase(ref.watch(chatRepositoryProvider)),
);

final markChatReadProvider = Provider(
  (ref) => MarkChatReadUseCase(ref.watch(chatRepositoryProvider)),
);

final chatInboxProvider =
    AsyncNotifierProvider.autoDispose<ChatInboxController, ChatInbox>(
      ChatInboxController.new,
      retry: (_, _) => null,
    );

class ChatInboxController extends AsyncNotifier<ChatInbox> {
  bool busy = false;
  Timer? _reload;
  bool _reloadPending = false;
  bool _initializing = true;
  final _pendingUpdates = <ChatUpdate>[];
  final _snapshots = <int, DateTime>{};
  int _generation = 0;
  @override
  Future<ChatInbox> build() async {
    _initializing = true;
    _pendingUpdates.clear();
    _snapshots.clear();
    final generation = ++_generation;
    ref.onDispose(() {
      ++_generation;
      _reload?.cancel();
    });
    ref.watch(appLocaleProvider);
    ref.watch(sessionControllerProvider);
    ref.listen(chatRealtimeUpdatesProvider, (_, next) {
      final event = next.asData?.value;
      if (event != null) _receive(event);
    });
    final inbox = await ref.watch(getChatInboxProvider).call(1);
    unawaited(
      Future(() {
        if (!ref.mounted || generation != _generation) return;
        _initializing = false;
        final pending = List<ChatUpdate>.of(_pendingUpdates);
        _pendingUpdates.clear();
        for (final event in pending) {
          _receive(event);
        }
        if (_reloadPending) requestRefresh();
      }),
    );
    return inbox;
  }

  void _receive(ChatUpdate update) {
    if (update.kind == ChatUpdateKind.disconnected) return;
    if (_initializing || busy) {
      if (_pendingUpdates.length < 512) {
        _pendingUpdates.add(update);
      } else {
        _reloadPending = true;
      }
      return;
    }
    if (update.kind == ChatUpdateKind.connected ||
        update.conversation == null) {
      requestRefresh();
      return;
    }
    final current = state.asData?.value;
    if (current == null) return;
    final chat = update.conversation!;
    final snapshot = update.snapshotAt!;
    final previous = _snapshots[chat.id];
    if (previous != null && !snapshot.isAfter(previous)) return;
    _snapshots[chat.id] = snapshot;
    final chats =
        {
          ...{for (final item in current.chats) item.id: item},
          chat.id: chat,
        }.values.toList()..sort(
          (a, b) => b.latestMessageId != a.latestMessageId
              ? b.latestMessageId.compareTo(a.latestMessageId)
              : b.id.compareTo(a.id),
        );
    state = AsyncData(ChatInbox(chats, current.page, current.lastPage));
  }

  void _drainUpdates() {
    final pending = List<ChatUpdate>.of(_pendingUpdates);
    _pendingUpdates.clear();
    for (final update in pending) {
      _receive(update);
    }
  }

  void requestRefresh() {
    _reloadPending = true;
    _reload?.cancel();
    _reload = Timer(
      const Duration(milliseconds: 180),
      () => unawaited(_refreshFirstPage()),
    );
  }

  Future<void> _refreshFirstPage() async {
    final current = state.asData?.value;
    if (busy || current == null) return;
    busy = true;
    _reloadPending = false;
    final generation = _generation;
    try {
      final first = await ref.read(getChatInboxProvider).call(1);
      if (!ref.mounted || generation != _generation) return;
      final ids = first.chats.map((chat) => chat.id).toSet();
      state = AsyncData(
        ChatInbox(
          [
            ...first.chats,
            if (current.page > 1)
              ...current.chats.where((chat) => !ids.contains(chat.id)),
          ],
          current.page.clamp(1, first.lastPage),
          first.lastPage,
        ),
      );
    } catch (_) {
      // Retain readable history; manual refresh or the next event can retry.
    } finally {
      busy = false;
      if (ref.mounted && generation == _generation) _drainUpdates();
      if (ref.mounted && generation == _generation && _reloadPending) {
        requestRefresh();
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (busy || current == null || current.page >= current.lastPage) return;
    busy = true;
    final generation = _generation;
    try {
      final next = await ref.read(getChatInboxProvider).call(current.page + 1);
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
      if (ref.mounted && generation == _generation) _drainUpdates();
      if (ref.mounted && generation == _generation && _reloadPending) {
        requestRefresh();
      }
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
  bool _initializing = true, _refreshAgain = false;
  final List<ChatUpdate> _pendingUpdates = [];
  int _mineReadThrough = 0, _incomingReadThrough = 0;
  @override
  Future<ChatState> build() async {
    ref.watch(sessionControllerProvider);
    _initializing = true;
    _pendingUpdates.clear();
    _mineReadThrough = _incomingReadThrough = 0;
    _readThrough = 0;
    final generation = ++_generation;
    ref.onDispose(() => ++_generation);
    ref.listen(chatRealtimeUpdatesProvider, (_, next) {
      final update = next.asData?.value;
      if (update != null) _receive(update);
    });
    final open = ref.watch(openChatProvider);
    final messages = ref.watch(getChatMessagesProvider);
    final context = await open(target);
    final id = context.conversation?.id;
    final page = id == null
        ? const ChatMessages([], false)
        : await messages(id);
    if (ref.mounted && generation == _generation) {
      _syncAfter = page.messages.isEmpty ? 0 : page.messages.first.id;
      _mineReadThrough = page.readThroughId;
      unawaited(
        Future(() {
          if (!ref.mounted || generation != _generation) return;
          _initializing = false;
          final pending = List<ChatUpdate>.of(_pendingUpdates);
          _pendingUpdates.clear();
          for (final update in pending) {
            _receive(update);
          }
          if (_refreshAgain && !_refreshing) unawaited(refresh());
        }),
      );
    }
    return ChatState(
      context: context,
      messages: page.messages.map(_withRead).toList(),
      hasOlder: page.hasMore,
    );
  }

  ChatMessage _withRead(ChatMessage message) => ChatMessage(
    id: message.id,
    text: message.text,
    mine: message.mine,
    read:
        message.read ||
        message.id <= (message.mine ? _mineReadThrough : _incomingReadThrough),
    createdAt: message.createdAt,
    clientId: message.clientId,
  );

  List<ChatMessage> _merge(List<ChatMessage> current, List<ChatMessage> next) {
    for (final message in [...current, ...next]) {
      if (!message.read) continue;
      if (message.mine && message.id > _mineReadThrough) {
        _mineReadThrough = message.id;
      }
      if (!message.mine && message.id > _incomingReadThrough) {
        _incomingReadThrough = message.id;
      }
    }
    return ({
      for (final m in current) m.id: m,
      for (final m in next) m.id: m,
    }.values.map(_withRead).toList()..sort((a, b) => b.id.compareTo(a.id)));
  }

  void _receive(ChatUpdate update) {
    if (_initializing) {
      if (_pendingUpdates.length < 512) {
        _pendingUpdates.add(update);
      } else {
        _refreshAgain = true;
      }
      return;
    }
    if (update.kind == ChatUpdateKind.connected) {
      unawaited(refresh());
      return;
    }
    if (update.kind == ChatUpdateKind.disconnected) return;
    final current = state.asData?.value;
    if (current == null) return;
    final id = current.context.conversation?.id ?? target.conversationId;
    if (id != null
        ? update.conversationId != id
        : (update.offerId != target.offerId ||
              update.orderId != target.orderId)) {
      return;
    }
    if (update.kind == ChatUpdateKind.read) {
      final through = update.throughId!;
      if (update.readerIsMe!) {
        if (through > _incomingReadThrough) _incomingReadThrough = through;
      } else {
        if (through > _mineReadThrough) _mineReadThrough = through;
      }
      state = AsyncData(
        current.copy(messages: current.messages.map(_withRead).toList()),
      );
    } else if (update.message != null) {
      state = AsyncData(
        current.copy(
          context: update.conversation == null
              ? current.context
              : ChatContext(
                  conversation: update.conversation,
                  storeName: update.conversation!.storeName,
                  employeeName: update.conversation!.employeeName,
                  orderId: update.orderId,
                  offerId: update.offerId,
                ),
          messages: _merge(current.messages, [update.message!]),
        ),
      );
      // Another device can start this offer's conversation while it is open here.
      if (current.context.conversation == null && update.conversation == null) {
        unawaited(refresh());
      }
    }
  }

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
          .read(sendChatMessageProvider)
          .call(
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
    } finally {
      if (ref.mounted && generation == _generation && _refreshAgain) {
        unawaited(refresh());
      }
    }
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null) return;
    if (_refreshing || current.sending) {
      _refreshAgain = true;
      return;
    }
    _refreshAgain = false;
    _refreshing = true;
    final generation = _generation;
    try {
      final open = ref.read(openChatProvider);
      final messages = ref.read(getChatMessagesProvider);
      final context = await open(
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
      // Drain every missed page; socket events and POST receipts never advance
      // this API cursor, so out-of-order deliveries cannot skip unseen messages.
      bool more;
      do {
        final previousCursor = _syncAfter;
        final newer = await messages(id, after: _syncAfter);
        if (!ref.mounted || generation != _generation) return;
        if (newer.readThroughId > _mineReadThrough) {
          _mineReadThrough = newer.readThroughId;
        }
        for (final message in newer.messages) {
          if (message.id > _syncAfter) _syncAfter = message.id;
        }
        final latest = state.requireValue;
        state = AsyncData(
          latest.copy(
            context: context,
            messages: _merge(latest.messages, newer.messages),
            hasOlder: latest.hasOlder,
            error: latest.sendError ? latest.error : null,
          ),
        );
        more =
            newer.hasMore &&
            newer.messages.isNotEmpty &&
            _syncAfter > previousCursor;
      } while (more);
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(state.requireValue.copy(error: error));
      }
    } finally {
      _refreshing = false;
      if (ref.mounted && generation == _generation && _refreshAgain) {
        unawaited(refresh());
      }
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
          .read(getChatMessagesProvider)
          .call(
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
    final through = current.messages.first.id;
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
          .read(markChatReadProvider)
          .call(current.context.conversation!.id, through);
      if (ref.mounted && generation == _generation) {
        _readThrough = through;
        _incomingReadThrough = through;
        state = AsyncData(
          state.requireValue.copy(
            messages: state.requireValue.messages.map(_withRead).toList(),
          ),
        );
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
