import '../../../support_chat/presentation/widgets/support_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/app_language_settings_card.dart';
import '../../../notifications/presentation/widgets/notification_entry.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../widgets/provider_page.dart';

class ProviderMoreScreen extends ConsumerWidget {
  const ProviderMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProviderPage(
    titleKey: 'provider_portal.more',
    children: [
      const SupportMenuEntry(),
      const SizedBox(height: 12),
      const AppLanguageSettingsCard(),
      const SizedBox(height: 12),
      const NotificationsMenuEntry(provider: true),
      const SizedBox(height: 12),
      ProviderNavigationTile(
        key: const Key('provider-more-stores'),
        titleKey: 'provider_stores.title',
        icon: Icons.storefront_outlined,
        onTap: () => const ProviderStoresRoute().go(context),
      ),
      ProviderNavigationTile(
        titleKey: 'provider_portal.profile',
        icon: Icons.person_outline,
        onTap: () => const ProviderProfileRoute().go(context),
      ),
      ProviderNavigationTile(
        titleKey: 'provider_portal.settings',
        icon: Icons.settings_outlined,
        onTap: () => const ProviderSettingsRoute().go(context),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: Text(context.tr('common.sign_out')),
      ),
    ],
  );
}

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ProviderPage(
    titleKey: 'provider_portal.settings',
    showBack: true,
    children: [AppLanguageSettingsCard()],
  );
}
