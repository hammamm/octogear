import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_brand_header.dart';
import '../../../../core/widgets/octogear_page_scaffold.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/session_outcome.dart';
import '../controllers/session_controller.dart';
import '../widgets/authentication_failure_text.dart';

class SessionUnavailableScreen extends ConsumerWidget {
  const SessionUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(sessionControllerProvider).asData?.value;
    final failure = outcome is UnavailableSession
        ? outcome.failure
        : const ApiFailure.unexpected();
    final isForbidden = failure.type == ApiFailureType.forbidden;

    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppLanguageToggleButton(),
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          const OctoGearBrandHeader(compact: true),
          const SizedBox(height: 56),
          OctoGearSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    height: 64,
                    width: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isForbidden
                          ? OctoGearColors.yellowSoft
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(OctoGearRadii.medium),
                    ),
                    child: Icon(
                      isForbidden
                          ? Icons.lock_outline_rounded
                          : Icons.cloud_off_outlined,
                      color: OctoGearColors.navy,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.large),
                Text(
                  isForbidden
                      ? context.tr('session.forbidden_title')
                      : context.tr('session.unavailable_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OctoGearSpacing.xSmall),
                Text(
                  authenticationFailureText(context, failure),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: OctoGearColors.structuralGray,
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.large),
                FilledButton(
                  onPressed: () =>
                      ref.read(sessionControllerProvider.notifier).retry(),
                  child: Text(context.tr('common.retry')),
                ),
                const SizedBox(height: OctoGearSpacing.small),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(sessionControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.tr('common.sign_out')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
