import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../customer_chats/domain/entities/chat.dart';
import '../../../customer_chats/domain/entities/chat_update.dart';
import '../../../customer_chats/presentation/controllers/chat_realtime_providers.dart';
import '../../data/data_sources/support_remote_data_source.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../domain/repositories/support_repository.dart';
import '../../domain/entities/support_chat.dart';
import '../../domain/use_cases/support_actions.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  ref.watch(sessionControllerProvider);
  return SupportRepositoryImpl(
    SupportRemoteDataSource(
      ref.watch(apiClientProvider),
      ref.watch(sessionStorageProvider).cachedAccessToken,
    ),
  );
});
final supportActionsProvider = Provider(
  (ref) => SupportActions(ref.watch(supportRepositoryProvider)),
);
final supportChatProvider =
    NotifierProvider<SupportChatController, SupportState>(
      SupportChatController.new,
    );

class SupportState {
  const SupportState({
    this.conversation,
    this.messages = const [],
    this.loading = true,
    this.loaded = false,
    this.hasMore = false,
    this.busy = false,
    this.paging = false,
    this.error,
    this.sendError,
    this.readError = false,
  });
  final SupportConversation? conversation;
  final List<ChatMessage> messages;
  final bool loading, loaded, hasMore, busy, paging, readError;
  final Object? error, sendError;
  SupportState copy({
    SupportConversation? conversation,
    List<ChatMessage>? messages,
    bool? loading,
    bool? loaded,
    bool? hasMore,
    bool? busy,
    bool? paging,
    Object? error,
    Object? sendError,
    bool? readError,
  }) => SupportState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    hasMore: hasMore ?? this.hasMore,
    busy: busy ?? this.busy,
    paging: paging ?? this.paging,
    error: error,
    sendError: sendError,
    readError: readError ?? this.readError,
  );
}

class SupportChatController extends Notifier<SupportState> {
  int _epoch = 0, _cursor = 0;
  bool _summaryBusy = false,
      _summaryAgain = false,
      _historyBusy = false,
      _readBusy = false,
      _recoverAgain = false;
  String? _pendingText, _pendingId;
  @override
  SupportState build() {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final epoch = ++_epoch;
    _cursor = 0;
    _summaryBusy = false;
    _summaryAgain = false;
    _historyBusy = false;
    _readBusy = false;
    _recoverAgain = false;
    _pendingText = null;
    _pendingId = null;
    ref.onDispose(() => _epoch++);
    if (session is! AuthenticatedSession) {
      return const SupportState(loading: false);
    }
    ref.listen(chatRealtimeUpdatesProvider, (_, next) {
      final update = next.asData?.value;
      if (epoch != _epoch || update == null) return;
      if (update.support case final SupportUpdate event) {
        _summary(event.conversation);
        if (event.message != null) _merge([event.message!]);
      } else if (update.kind == ChatUpdateKind.connected) {
        unawaited(state.loaded ? open() : refreshSummary());
      }
    });
    unawaited(
      Future.microtask(() {
        if (epoch == _epoch) return refreshSummary();
      }),
    );
    return const SupportState();
  }

  void _summary(SupportConversation incoming) {
    if (state.conversation == null ||
        incoming.version >= state.conversation!.version) {
      state = state.copy(
        conversation: incoming,
        error: state.error,
        loading: false,
        sendError: state.sendError,
      );
    }
  }

  void _merge(List<ChatMessage> messages) {
    final merged = {
      for (final m in state.messages) m.id: m,
      for (final m in messages) m.id: m,
    }.values.toList()..sort((a, b) => b.id.compareTo(a.id));
    state = state.copy(
      messages: merged,
      error: state.error,
      sendError: state.sendError,
    );
  }

  Future<void> refreshSummary() async {
    if (_summaryBusy) {
      _summaryAgain = true;
      return;
    }
    _summaryBusy = true;
    final epoch = _epoch;
    try {
      final summary = await ref.read(supportActionsProvider).summary();
      if (epoch != _epoch) return;
      if (summary != null) {
        _summary(summary);
      } else {
        state = state.copy(loading: false, sendError: state.sendError);
      }
    } catch (error) {
      if (epoch == _epoch) {
        state = state.copy(
          loading: false,
          error: error,
          sendError: state.sendError,
        );
      }
    } finally {
      if (epoch == _epoch) {
        _summaryBusy = false;
        if (_summaryAgain) {
          _summaryAgain = false;
          unawaited(refreshSummary());
        }
      }
    }
  }

  Future<void> open() async {
    if (_historyBusy) {
      _recoverAgain = true;
      return;
    }
    _historyBusy = true;
    final epoch = _epoch;
    state = state.copy(loading: !state.loaded, sendError: state.sendError);
    try {
      final actions = ref.read(supportActionsProvider);
      final summary = await actions.summary();
      if (epoch != _epoch) return;
      if (summary != null) _summary(summary);
      if (state.conversation == null) {
        state = state.copy(loading: false, loaded: true);
        return;
      }
      var forward = state.loaded && _cursor > 0;
      var more = true;
      while (more) {
        final page = await actions.timeline(after: forward ? _cursor : null);
        if (epoch != _epoch) return;
        _summary(page.conversation);
        _merge(page.messages);
        if (page.messages.isNotEmpty) {
          _cursor = max(_cursor, page.messages.map((m) => m.id).reduce(max));
        }
        if (!forward) {
          state = state.copy(hasMore: page.hasMore, sendError: state.sendError);
        }
        more = forward && page.hasMore && page.messages.isNotEmpty;
        if (!forward && (state.conversation?.lastMessage?.id ?? 0) > _cursor) {
          forward = true;
          more = true;
        }
      }
      state = state.copy(
        loaded: true,
        loading: false,
        sendError: state.sendError,
      );
    } catch (error) {
      if (epoch == _epoch) {
        state = state.copy(
          loading: false,
          error: error,
          sendError: state.sendError,
        );
      }
    } finally {
      if (epoch == _epoch) {
        _historyBusy = false;
        if (_recoverAgain) {
          _recoverAgain = false;
          unawaited(open());
        }
      }
    }
  }

  Future<void> older() async {
    if (state.paging || !state.hasMore || state.messages.isEmpty) return;
    final epoch = _epoch;
    state = state.copy(paging: true, sendError: state.sendError);
    try {
      final page = await ref
          .read(supportActionsProvider)
          .timeline(before: state.messages.last.id);
      if (epoch != _epoch) return;
      _summary(page.conversation);
      _merge(page.messages);
      state = state.copy(
        paging: false,
        hasMore: page.hasMore,
        sendError: state.sendError,
      );
    } catch (error) {
      if (epoch == _epoch) {
        state = state.copy(
          paging: false,
          error: error,
          sendError: state.sendError,
        );
      }
    }
  }

  Future<bool> send(String text) async {
    if (state.busy || state.conversation?.closed == true) return false;
    // An uncertain send retains its exact body and UUID until manually retried.
    if (_pendingId != null && _pendingText != text.trim()) return false;
    _pendingText ??= text.trim();
    _pendingId ??= const Uuid().v4();
    final epoch = _epoch;
    state = state.copy(busy: true);
    try {
      final receipt = await ref
          .read(supportActionsProvider)
          .send(_pendingText!, _pendingId!);
      if (epoch != _epoch) return false;
      _summary(receipt.conversation);
      _merge([receipt.message]);
      _pendingText = null;
      _pendingId = null;
      state = state.copy(busy: false, loaded: true);
      // Do not advance the recovery cursor from a send receipt or live event.

      return true;
    } catch (error) {
      if (epoch == _epoch) {
        if (error is ApiFailure &&
            (error.statusCode == 409 ||
                [
                  ApiFailureType.validation,
                  ApiFailureType.forbidden,
                ].contains(error.type))) {
          _pendingText = null;
          _pendingId = null;
        }
        state = state.copy(busy: false, sendError: error);
        if (error is ApiFailure && error.statusCode == 409) unawaited(open());
      }
      return false;
    }
  }

  String? get pendingText => _pendingText;
  bool get hasPendingSend => _pendingId != null;
  Future<void> markRead(int through) async {
    if (_historyBusy ||
        _readBusy ||
        through <= (state.conversation?.userReadThrough ?? 0)) {
      return;
    }
    _readBusy = true;
    final epoch = _epoch;
    try {
      final conversation = await ref.read(supportActionsProvider).read(through);
      if (epoch != _epoch) return;
      _summary(conversation);
      state = state.copy(readError: false, sendError: state.sendError);
    } catch (_) {
      if (epoch == _epoch) {
        state = state.copy(readError: true, sendError: state.sendError);
      }
    } finally {
      if (epoch == _epoch) _readBusy = false;
    }
  }

  Future<void> reopen() async {
    final conversation = state.conversation;
    if (state.busy || conversation == null || !conversation.closed) return;
    final epoch = _epoch;
    state = state.copy(busy: true);
    try {
      final result = await ref
          .read(supportActionsProvider)
          .reopen(conversation.version);
      if (epoch == _epoch) {
        _summary(result);
        state = state.copy(busy: false);
      }
    } catch (error) {
      if (epoch == _epoch) {
        state = state.copy(busy: false, error: error);
        await open();
        if (epoch == _epoch) state = state.copy(error: error);
      }
    }
  }
}
