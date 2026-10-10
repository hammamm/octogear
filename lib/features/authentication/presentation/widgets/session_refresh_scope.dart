import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session_outcome.dart';
import '../controllers/session_controller.dart';

/// Recheck server-side role changes when an authenticated app is reopened.
/// Startup restoration handles cold launches; this handles background/resume.
class SessionRefreshScope extends ConsumerStatefulWidget {
  const SessionRefreshScope({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<SessionRefreshScope> createState() =>
      _SessionRefreshScopeState();
}

class _SessionRefreshScopeState extends ConsumerState<SessionRefreshScope> {
  late final AppLifecycleListener _lifecycle;
  bool _refreshing = false;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (_refreshing ||
        ref.read(sessionControllerProvider).asData?.value
            is! AuthenticatedSession) {
      return;
    }
    _refreshing = true;
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .refreshProfile(roleChangesOnly: true);
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
