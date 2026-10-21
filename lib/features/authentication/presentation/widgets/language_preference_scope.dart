import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/language_preference_controller.dart';

class LanguagePreferenceScope extends ConsumerStatefulWidget {
  const LanguagePreferenceScope({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<LanguagePreferenceScope> createState() =>
      _LanguagePreferenceScopeState();
}

class _LanguagePreferenceScopeState
    extends ConsumerState<LanguagePreferenceScope> {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _notice;

  @override
  void initState() {
    super.initState();
    ref.listenManual(languagePreferenceControllerProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            ref.read(languagePreferenceControllerProvider) != next) {
          return;
        }
        _notice?.close();
        _notice = null;
        if (next != LanguagePreferenceStatus.failed) return;
        _notice = ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(context.tr('app_settings.language_save_failed')),
            action: SnackBarAction(
              label: context.tr('common.retry'),
              onPressed: () => ref
                  .read(languagePreferenceControllerProvider.notifier)
                  .retry(),
            ),
          ),
        );
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
