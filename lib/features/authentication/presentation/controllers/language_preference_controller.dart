import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../domain/entities/session_outcome.dart';
import 'language_preference_providers.dart';
import 'session_controller.dart';

enum LanguagePreferenceStatus { idle, saving, failed }

final languagePreferenceControllerProvider =
    NotifierProvider<LanguagePreferenceController, LanguagePreferenceStatus>(
      LanguagePreferenceController.new,
    );

class LanguagePreferenceController extends Notifier<LanguagePreferenceStatus> {
  String? _token;
  int? _userId;
  int _generation = 0;
  bool _running = false;
  bool _adopting = false;
  AppLocale? _pending;

  @override
  LanguagePreferenceStatus build() {
    ref.listen(sessionControllerProvider, (_, _) => _sessionChanged());
    ref.listen(appLocaleProvider, (previous, next) {
      if (previous != next && !_adopting) _queue(next);
    });
    scheduleMicrotask(() {
      if (ref.mounted) _sessionChanged();
    });
    return LanguagePreferenceStatus.idle;
  }

  void _sessionChanged() {
    final session = ref.read(sessionControllerProvider).asData?.value;
    final token = ref.read(sessionStorageProvider).cachedAccessToken;
    if (session is! AuthenticatedSession || token == null) {
      _generation++;
      _token = null;
      _userId = null;
      _pending = null;
      _running = false;
      state = LanguagePreferenceStatus.idle;
      return;
    }
    if (_token == token && _userId == session.user.id) return;
    _generation++;
    _token = token;
    _userId = session.user.id;
    _pending = null;
    _running = false;
    state = LanguagePreferenceStatus.idle;
    final saved = session.user.preferredLanguage;
    if (saved == null) {
      _queue(ref.read(appLocaleProvider));
    } else {
      _adopting = true;
      // Selection changes state synchronously; the awaited work is local storage.
      unawaited(
        ref
            .read(appLocaleProvider.notifier)
            .select(AppLocale.fromCode(saved))
            .catchError((Object _) {
              // A local cache failure must not discard a valid account preference.
            }),
      );
      _adopting = false;
    }
  }

  bool _current(int generation, String token) =>
      ref.mounted &&
      generation == _generation &&
      token == ref.read(sessionStorageProvider).cachedAccessToken;

  void _queue(AppLocale locale) {
    final token = _token;
    if (token == null || !_current(_generation, token)) return;
    _pending = locale;
    if (!_running) unawaited(_save(_generation, token));
  }

  Future<void> _save(int generation, String token) async {
    _running = true;
    while (_current(generation, token) && _pending != null) {
      final language = _pending!;
      _pending = null;
      state = LanguagePreferenceStatus.saving;
      try {
        await ref.read(saveLanguagePreferenceUseCaseProvider)(
          language: language.code,
          sessionToken: token,
        );
        if (!_current(generation, token)) return;
        state = LanguagePreferenceStatus.idle;
      } catch (_) {
        if (!_current(generation, token)) return;
        state = _pending == null
            ? LanguagePreferenceStatus.failed
            : LanguagePreferenceStatus.saving;
      }
    }
    if (_current(generation, token)) _running = false;
  }

  void retry() => _queue(ref.read(appLocaleProvider));
}
