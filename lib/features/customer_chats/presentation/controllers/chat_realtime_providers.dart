import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/configuration/app_configuration.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/chat_realtime_data_source.dart';
import '../../data/repositories/pusher_chat_realtime_repository.dart';
import '../../domain/entities/chat_update.dart';
import '../../domain/repositories/chat_realtime_repository.dart';

final chatRealtimeRepositoryProvider =
    Provider.autoDispose<ChatRealtimeRepository>((ref) {
      final session = ref.watch(sessionControllerProvider).asData?.value;
      if (session is! AuthenticatedSession) {
        throw StateError('Realtime requires a session');
      }
      final repository = PusherChatRealtimeRepository(
        ChatRealtimeDataSource(
          ref.watch(apiClientProvider),
          allowInsecure:
              ref.watch(appConfigurationProvider).environment ==
              AppEnvironment.development,
        ),
        userId: session.user.id,
      );
      ref.onDispose(() => unawaited(repository.dispose()));
      return repository;
    });

final chatRealtimeUpdatesProvider = StreamProvider.autoDispose<ChatUpdate>((
  ref,
) {
  final session = ref.watch(sessionControllerProvider).asData?.value;
  if (session is! AuthenticatedSession) return const Stream.empty();
  final repository = ref.watch(chatRealtimeRepositoryProvider);
  final lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.resumed) {
        unawaited(repository.connect());
      } else if (state != AppLifecycleState.inactive) {
        repository.pause();
      }
    },
  );
  ref.onDispose(lifecycle.dispose);
  if (WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
    unawaited(repository.connect());
  }
  return repository.updates;
});

final chatRealtimeConnectedProvider = Provider.autoDispose<bool>((ref) {
  final update = ref.watch(chatRealtimeUpdatesProvider).asData?.value;
  return update != null && update.kind != ChatUpdateKind.disconnected;
});
