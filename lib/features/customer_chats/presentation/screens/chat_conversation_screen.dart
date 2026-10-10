import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../domain/entities/chat.dart';
import '../controllers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_connection_status.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.target,
    this.provider = false,
  });
  final ChatTarget target;
  final bool provider;
  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _readDebounce;
  int? _pendingReadThrough;
  int _readGeneration = 0;
  bool _markingRead = false;
  bool _resumed = true;
  bool get _visible =>
      mounted &&
      _resumed &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? false);
  bool get _atBottom => !_scroll.hasClients || _scroll.offset < 64;
  ChatController get _controller =>
      ref.read(chatProvider(widget.target).notifier);
  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    _scheduleReadReceipt();
  }

  void _cancelReadReceipt() {
    _readDebounce?.cancel();
    _readDebounce = null;
    _pendingReadThrough = null;
  }

  void _scheduleReadReceipt() {
    if (!_visible || !_atBottom) {
      _cancelReadReceipt();
      return;
    }
    final state = ref.read(chatProvider(widget.target)).asData?.value;
    final unread = state?.messages.where((m) => !m.mine && !m.read);
    if (state == null ||
        state.error != null ||
        state.context.conversation == null ||
        unread == null ||
        unread.isEmpty) {
      _cancelReadReceipt();
      return;
    }
    if (_markingRead) return;
    final through = unread.first.id;
    // Rebuilds, own messages and scroll events must not reset the quiet period.
    if (_readDebounce?.isActive == true && _pendingReadThrough == through) {
      return;
    }
    _cancelReadReceipt();
    _pendingReadThrough = through;
    _readDebounce = Timer(
      const Duration(milliseconds: 1500),
      () => unawaited(_flushReadReceipt()),
    );
  }

  Future<void> _flushReadReceipt() async {
    _cancelReadReceipt();
    if (!_visible || !_atBottom) return;
    final generation = _readGeneration;
    _markingRead = true;
    try {
      await _controller.markRead();
    } finally {
      if (mounted && generation == _readGeneration) {
        _markingRead = false;
        // Messages received during the request need their own trailing batch.
        _scheduleReadReceipt();
      }
    }
  }

  void _checkReadAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleReadReceipt();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_visible) _cancelReadReceipt();
    _checkReadAfterFrame();
  }

  @override
  void didUpdateWidget(ChatConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      ++_readGeneration;
      _markingRead = false;
      _cancelReadReceipt();
      _checkReadAfterFrame();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) {
      _checkReadAfterFrame();
    } else {
      _cancelReadReceipt();
    }
  }

  @override
  void dispose() {
    ++_readGeneration;
    _cancelReadReceipt();
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final success = await _controller.send(_text.text);
    if (!mounted || !success) return;
    _text.clear();
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatProvider(widget.target));
    ref.listen(chatProvider(widget.target), (previous, next) {
      _checkReadAfterFrame();
    });
    final info = async.asData?.value.context;
    final title = widget.provider
        ? info?.conversation?.name
        : info?.storeName ?? info?.conversation?.name;
    final subtitle = widget.provider ? info?.storeName : info?.employeeName;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        toolbarHeight:
            68 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: OctoGearColors.yellowSoft,
              child: Icon(
                Icons.storefront_outlined,
                color: OctoGearColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title?.isNotEmpty == true
                        ? title!
                        : context.tr('customer_chats.tab'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle?.isNotEmpty == true)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: const [AppLanguageToggleButton(compact: true)],
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(chatProvider(widget.target)),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('chat.load_error')),
            ),
          ),
          data: (state) => Column(
            children: [
              if (state.context.orderId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    context.tr(
                      'chat.request',
                      args: ['${state.context.orderId}'],
                    ),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              Expanded(
                child: state.messages.isEmpty
                    ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.forum_outlined,
                                size: 44,
                                color: OctoGearColors.structuralGray,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                context.tr('chat.start'),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            itemCount:
                                state.messages.length +
                                (state.hasOlder ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.messages.length) {
                                return Center(
                                  child: state.loadingOlder
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(),
                                        )
                                      : TextButton(
                                          onPressed: _controller.older,
                                          child: Text(context.tr('chat.older')),
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
                                key: ValueKey('row-${message.id}'),
                                children: [
                                  if (day)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5E9EF),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          chatDayLabel(
                                            context,
                                            message.createdAt,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                        ),
                                      ),
                                    ),
                                  ChatMessageBubble(message: message),
                                ],
                              );
                            },
                          ),
                          PositionedDirectional(
                            end: 12,
                            bottom: 12,
                            child: ListenableBuilder(
                              listenable: _scroll,
                              builder: (_, _) => !_atBottom
                                  ? FloatingActionButton.small(
                                      heroTag: null,
                                      tooltip: context.tr('chat.latest'),
                                      backgroundColor: Colors.white,
                                      foregroundColor: OctoGearColors.navy,
                                      onPressed: () => _scroll.animateTo(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOut,
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
              ),
              if (state.error != null)
                Container(
                  width: double.infinity,
                  color: OctoGearColors.yellowSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        context.tr(
                          state.sendError
                              ? 'chat.send_error'
                              : 'chat.refresh_error',
                        ),
                      ),
                      TextButton(
                        onPressed: state.sending
                            ? null
                            : state.sendError
                            ? _send
                            : _controller.refresh,
                        child: Text(context.tr('common.retry')),
                      ),
                    ],
                  ),
                ),
              const ChatConnectionStatus(),
              if (!state.context.canSend)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.tr('chat.read_only')),
                )
              else
                Material(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      10,
                      8,
                      10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('chat-composer'),
                            controller: _text,
                            enabled: !state.sending && !state.sendError,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 2000,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: context.tr('chat.message_hint'),
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ValueListenableBuilder(
                          valueListenable: _text,
                          builder: (_, value, _) => IconButton.filled(
                            key: const Key('chat-send'),
                            tooltip: context.tr('chat.send'),
                            onPressed:
                                state.sending ||
                                    state.sendError ||
                                    value.text.trim().isEmpty
                                ? null
                                : _send,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: OctoGearColors.navy,
                            ),
                            icon: state.sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
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
}
