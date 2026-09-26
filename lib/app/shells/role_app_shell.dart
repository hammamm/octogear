import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/octogear_theme.dart';
import '../../core/widgets/app_language_toggle_button.dart';
import '../../core/widgets/octogear_brand_header.dart';
import '../../core/widgets/octogear_page_scaffold.dart';
import '../../core/widgets/octogear_surface_card.dart';
import '../../features/authentication/domain/entities/app_user.dart';
import '../../features/authentication/domain/entities/session_outcome.dart';
import '../../features/authentication/presentation/controllers/session_controller.dart';

class ProviderAppShell extends ConsumerWidget {
  const ProviderAppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _RoleAppShell(role: AppUserRole.provider);
  }
}

class _RoleAppShell extends ConsumerWidget {
  const _RoleAppShell({required this.role});

  final AppUserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(sessionControllerProvider).asData?.value;
    final user = outcome is AuthenticatedSession ? outcome.user : null;
    final isCustomer = role == AppUserRole.customer;
    final copyKey = isCustomer ? 'shell.customer' : 'shell.provider';

    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppLanguageToggleButton(compact: true),
              TextButton.icon(
                onPressed: () =>
                    ref.read(sessionControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(context.tr('common.sign_out')),
              ),
            ],
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
                      color: OctoGearColors.yellowSoft,
                      borderRadius: BorderRadius.circular(OctoGearRadii.medium),
                    ),
                    child: Icon(
                      isCustomer
                          ? Icons.directions_car_outlined
                          : Icons.storefront_outlined,
                      color: OctoGearColors.navy,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.large),
                Align(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: OctoGearSpacing.small,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OctoGearColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(OctoGearRadii.pill),
                    ),
                    child: Text(
                      context.tr('$copyKey.role_label'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: OctoGearColors.structuralGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.medium),
                Text(
                  context.tr('$copyKey.title', args: [user?.fullName ?? '']),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OctoGearSpacing.xSmall),
                Text(
                  context.tr('$copyKey.description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: OctoGearColors.structuralGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
