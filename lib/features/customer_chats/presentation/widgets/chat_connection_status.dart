import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../controllers/chat_realtime_providers.dart';

class ChatConnectionStatus extends ConsumerWidget {
  const ChatConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(sessionControllerProvider).asData?.value
        is! AuthenticatedSession) {
      return const SizedBox.shrink();
    }
    return _ReconnectIndicator(
      connected: ref.watch(chatRealtimeConnectedProvider),
    );
  }
}

class _ReconnectIndicator extends StatefulWidget {
  const _ReconnectIndicator({required this.connected});
  final bool connected;

  @override
  State<_ReconnectIndicator> createState() => _ReconnectIndicatorState();
}

class _ReconnectIndicatorState extends State<_ReconnectIndicator> {
  Timer? _delay;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(_ReconnectIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connected != widget.connected) _update();
  }

  void _update() {
    _delay?.cancel();
    _visible = false;
    if (!widget.connected) {
      // Initial connection and brief app switches should not show an outage.
      _delay = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || widget.connected) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Tooltip(
        message: context.tr('chat.reconnecting'),
        child: Icon(
          Icons.sync,
          size: 18,
          semanticLabel: context.tr('chat.reconnecting'),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
