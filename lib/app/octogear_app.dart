import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import '../core/design_system/octogear_theme.dart';
import '../core/localization/app_locale.dart' as octogear_locale;
import '../core/localization/app_locale_controller.dart';

class OctoGearApp extends ConsumerWidget {
  const OctoGearApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<octogear_locale.AppLocale>(appLocaleProvider, (previous, next) {
      if (previous != next && context.mounted) {
        unawaited(context.setLocale(next.locale));
      }
    });

    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // This is operating-system window metadata, not visible screen copy.
      // Keeping the brand literal avoids asking EasyLocalization for a value
      // before MaterialApp has installed its localization delegates.
      title: 'OctoGear',
      theme: OctoGearTheme.lightTheme,
      locale: locale.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
