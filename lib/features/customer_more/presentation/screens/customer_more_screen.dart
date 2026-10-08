import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../app/shells/customer_app_shell.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../customer_notifications/presentation/widgets/notification_entry.dart';

class CustomerMoreScreen extends ConsumerWidget {
  const CustomerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final user = session is AuthenticatedSession ? session.user : null;
    return _MorePage(
      pageKey: 'customer-tab-more',
      title: context.tr('customer_more.tab'),
      children: [
        Text(context.tr('customer_more.description')),
        const SizedBox(height: 24),
        OctoGearSurfaceCard(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: OctoGearColors.yellowSoft,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: OctoGearColors.navy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(context.tr('customer_shell.account.role_label')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NotificationsMenuEntry(),
        const SizedBox(height: 12),
        _MenuEntry(
          icon: Icons.person_outline_rounded,
          title: context.tr('customer_more.profile'),
          subtitle: context.tr('customer_more.profile_description'),
          onTap: () => const CustomerProfileRoute().push<void>(context),
        ),
        const SizedBox(height: 12),
        _MenuEntry(
          icon: Icons.directions_car_outlined,
          title: context.tr('customer_garage.account_entry_title'),
          subtitle: context.tr('customer_garage.account_entry_description'),
          onTap: () => const CustomerCarsRoute().push<void>(context),
        ),
        const SizedBox(height: 12),
        _MenuEntry(
          icon: Icons.tune_rounded,
          title: context.tr('customer_more.settings'),
          subtitle: context.tr('customer_more.settings_description'),
          onTap: () => const CustomerSettingsRoute().push<void>(context),
        ),
        const SizedBox(height: 24),
        const CustomerSignOutCard(),
      ],
    );
  }
}

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _MorePage(
    pageKey: 'customer-settings',
    title: context.tr('customer_more.settings'),
    showBack: true,
    children: [
      OctoGearSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('customer_more.language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(context.tr('customer_more.language_description')),
            const SizedBox(height: 16),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppLanguageToggleButton(),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.pageKey,
    required this.title,
    required this.children,
    this.showBack = false,
  });
  final String pageKey, title;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) => ListView(
    key: PageStorageKey(pageKey),
    padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
    children: [
      Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const BackButtonIcon(),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : const CustomerMoreRoute().go(context),
            ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const AppLanguageToggleButton(compact: true),
        ],
      ),
      const SizedBox(height: 20),
      ...children,
    ],
  );
}

class _MenuEntry extends StatelessWidget {
  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    padding: EdgeInsets.zero,
    child: Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(OctoGearRadii.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: OctoGearColors.navy, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}
