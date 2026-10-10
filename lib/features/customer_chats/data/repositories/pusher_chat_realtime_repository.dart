import 'dart:async';
import 'dart:math';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../../../../core/api/api_failure.dart';
import '../../domain/entities/chat_update.dart';
import '../../domain/repositories/chat_realtime_repository.dart';
import '../data_sources/chat_realtime_data_source.dart';
import '../models/chat_realtime_dto.dart';

/// One private session connection. Timers retry failed connections, never poll chats.
class PusherChatRealtimeRepository implements ChatRealtimeRepository {
  PusherChatRealtimeRepository(this.source, {required this.userId});
  final ChatRealtimeDataSource source;
  final int userId;
  final _updates = StreamController<ChatUpdate>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  PusherChannelsClient? _client;
  Timer? _retry, _handshake;
  int _generation = 0, _attempt = 0;
  bool _disposed = false,
      _paused = false,
      _connecting = false,
      _subscribed = false;
  @override
  Stream<ChatUpdate> get updates => _updates.stream;

  void _emit(ChatUpdate update) {
    if (!_disposed) _updates.add(update);
  }

  @override
  Future<void> connect() async {
    if (_disposed || _connecting || _subscribed) return;
    _paused = false;
    _connecting = true;
    _close();
    final generation = ++_generation;
    bool current() => !_disposed && !_paused && generation == _generation;
    _emit(const ChatUpdate(ChatUpdateKind.disconnected));
    try {
      final configuration = await source.configuration();
      if (!current() || configuration == null) return;
      final client = PusherChannelsClient.websocket(
        options: PusherChannelsOptions.custom(
          uriResolver: (_) => configuration.url,
        ),
        connectionErrorHandler: (_, _, _) {
          if (current()) _scheduleRetry();
        },
        minimumReconnectDelayDuration: const Duration(seconds: 3),
      );
      _client = client;
      final channel = client.privateChannel(
        configuration.channel,
        authorizationDelegate: _AuthorizationDelegate(
          (socket, name) async {
            if (!current()) {
              throw const ApiFailure(type: ApiFailureType.unauthorized);
            }
            final auth = await source.authorize(socket, name);
            if (!current()) {
              throw const ApiFailure(type: ApiFailureType.unauthorized);
            }
            return auth;
          },
          (error, _) {
            if (!current()) return;
            if (error is ApiFailure &&
                (error.type == ApiFailureType.unauthorized ||
                    error.type == ApiFailureType.forbidden)) {
              pause();
            } else {
              _scheduleRetry();
            }
          },
        ),
      );
      _subscriptions.add(
        client.onConnectionEstablished.listen((_) {
          if (current()) channel.subscribe();
        }),
      );
      _subscriptions.add(
        client.lifecycleStream.listen((state) {
          if (current() &&
              state !=
                  PusherChannelsClientLifeCycleState.establishedConnection) {
            _subscribed = false;
            _emit(const ChatUpdate(ChatUpdateKind.disconnected));
          }
        }),
      );
      _subscriptions.add(
        channel.whenSubscriptionSucceeded().listen((_) {
          if (!current()) return;
          _handshake?.cancel();
          if (_subscribed) return;
          _subscribed = true;
          _attempt = 0;
          _emit(const ChatUpdate(ChatUpdateKind.connected));
        }),
      );
      _subscriptions.add(
        channel.bind('chat.updated').listen((event) {
          if (!current()) return;
          final update = parseChatUpdate(event.tryGetDataAsMap(), userId);
          if (update != null) _emit(update);
        }),
      );
      _subscriptions.add(
        client.pusherErrorEventStream.listen((_) {
          if (current()) _scheduleRetry();
        }),
      );
      _handshake = Timer(const Duration(seconds: 25), () {
        if (current()) _scheduleRetry();
      });
      unawaited(
        client.connect().catchError((Object _) {
          if (current()) _scheduleRetry();
        }),
      );
    } catch (error) {
      if (current() &&
          !(error is ApiFailure &&
              (error.type == ApiFailureType.unauthorized ||
                  error.type == ApiFailureType.forbidden))) {
        _scheduleRetry();
      }
    } finally {
      if (generation == _generation) _connecting = false;
    }
  }

  void _scheduleRetry() {
    if (_disposed || _paused || _retry?.isActive == true) return;
    _emit(const ChatUpdate(ChatUpdateKind.disconnected));
    _subscribed = false;
    _handshake?.cancel();
    final seconds = min(30, 1 << min(_attempt++, 5));
    _retry = Timer(
      Duration(milliseconds: seconds * 1000 + Random().nextInt(500)),
      () {
        if (!_paused && !_disposed) unawaited(connect());
      },
    );
  }

  void _close() {
    _subscribed = false;
    _retry?.cancel();
    _handshake?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _client?.dispose();
    _client = null;
  }

  @override
  void pause() {
    _paused = true;
    _connecting = false;
    ++_generation;
    _close();
    _emit(const ChatUpdate(ChatUpdateKind.disconnected));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    pause();
    _disposed = true;
    await _updates.close();
  }
}

class _AuthorizationDelegate
    implements
        EndpointAuthorizableChannelAuthorizationDelegate<
          PrivateChannelAuthorizationData
        > {
  const _AuthorizationDelegate(this.authorize, this.onAuthFailed);
  final Future<String> Function(String, String) authorize;
  @override
  final EndpointAuthFailedCallback onAuthFailed;
  @override
  Future<PrivateChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async => PrivateChannelAuthorizationData(
    authKey: await authorize(socketId, channelName),
  );
}
