import 'dart:async';

import '../../domain/entities/push_notification.dart';
import '../../domain/repositories/push_repository.dart';

/// Serializes device registration across token rotation, locale and session
/// changes. Receiving a push never fetches the notification inbox.
class PushDeliveryController {
  PushDeliveryController(this.repository);
  final PushRepository repository;
  final _received = StreamController<PushNotification>.broadcast();
  final _opened = StreamController<PushNotification>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Set<String> _seen = {}, _tapped = {};
  Future<void> _pending = Future.value();
  int _generation = 0;
  int? _userId;
  String? _sessionKey;
  String _locale = 'ar';
  String? _registration;
  bool _disposed = false;
  bool _allowInitial = true;
  PushNotification? _initial;
  Stream<PushNotification> get received => _received.stream;
  Stream<PushNotification> get opened => _opened.stream;

  void initialize() {
    _subscriptions.add(
      repository.foreground.listen(
        (event) => _accept(event, false),
        onError: (Object _) {},
      ),
    );
    _subscriptions.add(
      repository.opened.listen(
        (event) => _accept(event, true),
        onError: (Object _) {},
      ),
    );
    _subscriptions.add(
      repository.tokenChanges.listen((_) => sync(), onError: (Object _) {}),
    );
    unawaited(_loadInitial());
  }

  Future<void> _loadInitial() async {
    try {
      final event = await repository.initialNotification();
      if (_disposed || !_allowInitial) return;
      _initial = event;
      _drainInitial();
    } catch (_) {
      /* A push must never prevent startup. */
    }
  }

  void bind({
    required int? userId,
    required String? sessionKey,
    required String locale,
  }) {
    final changed = _userId != userId || _sessionKey != sessionKey;
    final languageChanged = _locale != locale;
    if (changed) {
      _generation++;
      _registration = null;
      _seen.clear();
      _tapped.clear();
    }
    _userId = userId;
    _sessionKey = sessionKey;
    _locale = locale;
    _drainInitial();
    if (userId != null && (changed || languageChanged)) {
      unawaited(sync(requestPermission: true));
    }
  }

  void discardInitial() {
    _allowInitial = false;
    _initial = null;
  }

  void _drainInitial() {
    if (_userId == null || _initial == null) return;
    final event = _initial!;
    _initial = null;
    _accept(event, true);
  }

  void _accept(PushNotification event, bool tapped) {
    if (_disposed || _userId == null || event.recipientId != _userId) return;
    final seen = tapped ? _tapped : _seen;
    if (!seen.add(event.item.id)) return;
    if (seen.length > 256) seen.remove(seen.first);
    (tapped ? _opened : _received).add(event);
  }

  Future<void> sync({bool requestPermission = false}) {
    final generation = _generation;
    final locale = _locale;
    bool current() =>
        !_disposed &&
        generation == _generation &&
        _userId != null &&
        _sessionKey != null;
    _pending = _pending.then((_) async {
      if (!current()) return;
      try {
        final allowed = await repository
            .permission(request: requestPermission)
            .timeout(const Duration(seconds: 15));
        if (!current()) return;
        if (!allowed) {
          if (_registration == 'disabled') return;
          await repository.unregister();
          if (current()) _registration = 'disabled';
          return;
        }
        final token = await repository.token().timeout(
          const Duration(seconds: 15),
        );
        if (!current() || token == null || token.isEmpty) return;
        final registration = '$token|$locale';
        if (_registration == registration) return;
        await repository.register(token, locale);
        if (current()) _registration = registration;
      } catch (_) {
        // Retry on the next resume, token rotation, locale change or explicit
        // settings action. Never create a polling timer or block the inbox.
      }
    });
    return _pending;
  }

  Future<void> prepareSignOut() async {
    _generation++;
    _userId = null;
    _sessionKey = null;
    _registration = null;
    discardInitial();
    await _pending;
    try {
      await repository.unregister();
    } catch (_) {}
    // Best effort token invalidation in addition to server revocation. Offline
    // devices cannot guarantee cancellation of notifications already in flight.
    try {
      await repository.deleteToken().timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _received.close();
    await _opened.close();
  }
}
