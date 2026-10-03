import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/configuration/app_configuration.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../controllers/authentication_flow_controller.dart';

/// Local debug convenience only. The real verification field stays unchanged.
class TestingOtpBanner extends ConsumerWidget {
  const TestingOtpBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(
      authenticationFlowProvider.select((state) => state.testOtp),
    );
    final environment = ref.watch(appConfigurationProvider).environment;
    if (!kDebugMode ||
        environment != AppEnvironment.development ||
        code == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: OctoGearSpacing.medium),
      child: Container(
        key: const Key('testing-otp-banner'),
        padding: const EdgeInsets.all(OctoGearSpacing.medium),
        decoration: BoxDecoration(
          color: OctoGearColors.yellowSoft,
          borderRadius: BorderRadius.circular(OctoGearRadii.small),
        ),
        child: Column(
          children: [
            Text(
              context.tr('auth.testing_otp'),
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              code,
              textDirection: ui.TextDirection.ltr,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 6,
                color: OctoGearColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
