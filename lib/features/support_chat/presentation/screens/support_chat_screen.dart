import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../authentication/domain/entities/app_user.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../customer_chats/presentation/widgets/chat_message_bubble.dart';
import '../../../customer_chats/presentation/widgets/chat_connection_status.dart';
import '../controllers/support_providers.dart';

class SupportChatScreen extends ConsumerWidget {
  const SupportChatScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession) return const SizedBox.shrink();
    return _SupportPage(key: ObjectKey(session));
  }
}

class _SupportPage extends ConsumerStatefulWidget {
  const _SupportPage({super.key});
  @override
  ConsumerState<_SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<_SupportPage>
    with WidgetsBindingObserver {
  final _text = TextEditingController(), _scroll = ScrollController();
  Timer? _readTimer;
  bool _started = false;
  SupportChatController get _controller =>
      ref.read(supportChatProvider.notifier);
  bool get _visible =>
      mounted &&
      ModalRoute.of(context)?.isCurrent == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
  bool get _atLatest => !_scroll.hasClients || _scroll.offset < 24;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_scheduleRead);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _text.text = _controller.pendingText ?? '';
      unawaited(_controller.open());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _readTimer?.cancel();
    if (state == AppLifecycleState.resumed && _visible) {
      unawaited(_controller.open());
    }
  }

  void _scheduleRead() {
    _readTimer?.cancel();
    final state = ref.read(supportChatProvider);
    if (!_visible ||
        !_atLatest ||
        state.loading ||
        state.error != null ||
        state.readError) {
      return;
    }
    final incoming = state.messages.where(
      (m) => !m.mine && m.id > (state.conversation?.userReadThrough ?? 0),
    );
    if (incoming.isEmpty) return;
    final through = incoming.first.id;
    _readTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!_visible || !_atLatest) return;
      await _controller.markRead(through);
      if (mounted && !ref.read(supportChatProvider).readError) _scheduleRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readTimer?.cancel();
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportChatProvider);
    ref.listen(supportChatProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next.conversation?.closed == true &&
            previous?.conversation?.closed != true) {
          FocusScope.of(context).unfocus();
        }
        _scheduleRead();
      });
    });
    final closed = state.conversation?.closed == true;
    final canCompose =
        !closed &&
        !state.loading &&
        state.loaded &&
        (state.conversation != null || _started);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('support.title')),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const BackButtonIcon(),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            final session = ref.read(sessionControllerProvider).asData?.value;
            if (session is AuthenticatedSession &&
                session.user.role == AppUserRole.provider) {
              const ProviderMoreRoute().go(context);
            } else {
              const CustomerMoreRoute().go(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              const ChatConnectionStatus(),
              if (state.conversation != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    context.tr(closed ? 'support.closed' : 'support.open'),
                  ),
                ),
              if (state.error != null)
                _retry('support.error', () => _controller.open()),
              if (state.readError)
                _retry('support.read_error', () async {
                  final incoming = state.messages.where((m) => !m.mine);
                  if (incoming.isNotEmpty && _visible && _atLatest) {
                    await _controller.markRead(incoming.first.id);
                  }
                }),
              Expanded(
                flex: 3,
                child: state.loading && !state.loaded
                    ? const Center(child: CircularProgressIndicator())
                    : state.conversation == null &&
                          !_started &&
                          state.error == null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.support_agent_rounded, size: 56),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('support.welcome'),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                key: const Key('support-start'),
                                onPressed: () =>
                                    setState(() => _started = true),
                                child: Text(context.tr('support.start')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: const Key('support-timeline'),
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount:
                            state.messages.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return Center(
                              child: TextButton(
                                onPressed: state.paging
                                    ? null
                                    : _controller.older,
                                child: state.paging
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(),
                                      )
                                    : Text(context.tr('support.older')),
                              ),
                            );
                          }
                          final message = state.messages[index];
                          final day =
                              index == state.messages.length - 1 ||
                              !sameChatDay(
                                message.createdAt,
                                state.messages[index + 1].createdAt,
                              );
                          return Column(
                            children: [
                              if (day)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    chatDayLabel(context, message.createdAt),
                                  ),
                                ),
                              ChatMessageBubble(message: message),
                            ],
                          );
                        },
                      ),
              ),
              if (closed)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.4,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('support.resolved'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          key: const Key('support-reopen'),
                          onPressed: state.busy ? null : _controller.reopen,
                          child: Text(context.tr('support.reopen')),
                        ),
                      ],
                    ),
                  ),
                ),
              if (canCompose)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.4,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      4,
                      12,
                      12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.sendError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(context.tr('support.send_error')),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key('support-message'),
                                controller: _text,
                                readOnly:
                                    state.busy || _controller.hasPendingSend,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 2000,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: context.tr('support.message'),
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              key: const Key('support-send'),
                              tooltip: context.tr(
                                state.sendError != null
                                    ? 'support.retry'
                                    : 'support.send',
                              ),
                              onPressed: state.busy
                                  ? null
                                  : () async {
                                      if (_text.text.trim().isEmpty) return;
                                      final sent = await _controller.send(
                                        _text.text,
                                      );
                                      if (mounted && sent) {
                                        _text.clear();
                                        if (_scroll.hasClients) {
                                          _scroll.jumpTo(0);
                                        }
                                      }
                                    },
                              icon: state.busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _retry(String key, Future<void> Function() retry) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(child: Text(context.tr(key))),
        TextButton(onPressed: retry, child: Text(context.tr('support.retry'))),
      ],
    ),
  );
}
