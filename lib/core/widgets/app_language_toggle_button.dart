import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/octogear_theme.dart';
import '../localization/app_locale.dart';
import '../localization/app_locale_controller.dart';

/// Shared locale action. It changes Flutter text direction immediately and the
/// API interceptor reads the same Riverpod locale for future requests.
class AppLanguageToggleButton extends ConsumerWidget {
  const AppLanguageToggleButton({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final label = locale == AppLocale.arabic
        ? context.tr('common.switch_to_english')
        : context.tr('common.switch_to_arabic');
    final compactLabel = locale == AppLocale.arabic ? 'EN' : 'ع';

    void toggleLocale() {
      unawaited(ref.read(appLocaleProvider.notifier).toggle());
    }

    return Semantics(
      button: true,
      label: label,
      child: TextButton.icon(
        onPressed: toggleLocale,
        icon: const Icon(Icons.language),
        label: Text(compact ? compactLabel : label),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: OctoGearColors.navy,
          backgroundColor: OctoGearColors.surface,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OctoGearRadii.pill),
            side: const BorderSide(color: OctoGearColors.border),
          ),
        ),
      ),
    );
  }
}
