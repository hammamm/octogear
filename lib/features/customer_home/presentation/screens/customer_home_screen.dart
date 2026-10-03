import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../widgets/home_promotions.dart';

/// Entry point for general requests; live offer summaries remain a later slice.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final name = session is AuthenticatedSession
        ? session.user.fullName.trim().split(RegExp(r'\s+')).first
        : '';
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: const PageStorageKey('customer-tab-home'),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 42,
                    height: 42,
                    semanticLabel: context.tr('app.name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      name.isEmpty ? 'home.welcome' : 'home.greeting',
                      args: name.isEmpty ? [] : [name],
                    ),
                    style: text.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                const AppLanguageToggleButton(compact: true),
              ],
            ),
            const SizedBox(height: 16),
            const HomePromotions(),
            const SizedBox(height: 8),
            const _RequestPanel(),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                context.tr('home.offers_title'),
                style: text.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            OctoGearSurfaceCard(
              key: const ValueKey('home-view-requests'),
              padding: const EdgeInsetsDirectional.all(OctoGearSpacing.medium),
              onTap: () => const CustomerOrdersRoute().go(context),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 24,
                    color: OctoGearColors.navy,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('home.view_requests'),
                          style: text.labelLarge?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('home.offers_description'),
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: OctoGearColors.navy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestPanel extends StatelessWidget {
  const _RequestPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const ValueKey('home-request-panel'),
      decoration: BoxDecoration(
        color: OctoGearColors.navy,
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(OctoGearSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.tr('home.request_title'),
                style: text.titleMedium?.copyWith(
                  color: OctoGearColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('home.request_availability'),
              style: text.bodyMedium?.copyWith(color: OctoGearColors.surface),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const ValueKey('home-request-part'),
                onPressed: () =>
                    const GeneralPartRequestRoute().push<void>(context),
                style: FilledButton.styleFrom(
                  backgroundColor: OctoGearColors.yellow,
                  foregroundColor: OctoGearColors.navy,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: text.labelLarge?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OctoGearRadii.small),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  context.tr('home.request_action'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
