import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../widgets/provider_page.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final name = session is AuthenticatedSession ? session.user.fullName : '';
    return ProviderPage(
      titleKey: 'provider_portal.dashboard',
      children: [
        Text(
          context.tr('provider_portal.welcome', args: [name]),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.tr('provider_portal.dashboard_intro')),
        const SizedBox(height: 24),
        const ProviderSectionPlaceholder(
          icon: Icons.insights_rounded,
          descriptionKey: 'provider_portal.dashboard_placeholder',
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('provider_portal.shortcuts'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ProviderNavigationTile(
          key: const Key('provider-shortcut-orders'),
          titleKey: 'provider_portal.orders',
          icon: Icons.receipt_long_outlined,
          onTap: () => const ProviderOrdersRoute().go(context),
        ),
        ProviderNavigationTile(
          key: const Key('provider-shortcut-stores'),
          titleKey: 'provider_stores.title',
          icon: Icons.storefront_outlined,
          onTap: () => const ProviderStoresRoute().go(context),
        ),
      ],
    );
  }
}
