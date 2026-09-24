import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/octogear_theme.dart';
import '../core/localization/app_locale.dart' as octogear_locale;
import '../core/localization/app_locale_controller.dart';
import '../core/service/app_logger.dart';

class OctoGearApp extends ConsumerWidget {
  const OctoGearApp({super.key});

  static final _routeObserver = AppRouteObserver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<octogear_locale.AppLocale>(appLocaleProvider, (previous, next) {
      if (previous != next && context.mounted) {
        unawaited(context.setLocale(next.locale));
      }
    });

    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app.name'.tr(),
      theme: OctoGearTheme.lightTheme,
      locale: locale.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      navigatorObservers: [_routeObserver],
      // Authentication owns the real startup decision. Until that bounded
      // feature is committed, the shared root must stay feature-neutral.
      home: const _FoundationScreen(),
    );
  }
}

class _FoundationScreen extends ConsumerWidget {
  const _FoundationScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final nextLanguageLabel = locale == octogear_locale.AppLocale.arabic
        ? 'common.switch_to_english'.tr()
        : 'common.switch_to_arabic'.tr();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(appLocaleProvider.notifier).toggle(),
                  icon: const Icon(Icons.language),
                  label: Text(nextLanguageLabel),
                ),
              ),
              const Spacer(),
              Semantics(
                header: true,
                child: Text(
                  'app.name'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: OctoGearColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'foundation.ready_title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'foundation.ready_description'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OctoGearColors.structuralGray,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
