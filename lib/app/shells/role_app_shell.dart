import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/octogear_theme.dart';

/// Independent provider branches preserve their navigation stacks on tab changes.
class ProviderAppShell extends StatelessWidget {
  const ProviderAppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: OctoGearColors.canvas,
        child: SafeArea(bottom: false, child: navigationShell),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        backgroundColor: OctoGearColors.surface,
        indicatorColor: OctoGearColors.yellowSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            key: const Key('provider-nav-dashboard'),
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: context.tr('provider_portal.dashboard'),
          ),
          NavigationDestination(
            key: const Key('provider-nav-orders'),
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: context.tr('provider_portal.orders'),
          ),
          NavigationDestination(
            key: const Key('provider-nav-chats'),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: context.tr('customer_chats.tab'),
          ),
          NavigationDestination(
            key: const Key('provider-nav-more'),
            icon: const Icon(Icons.more_horiz_rounded),
            label: context.tr('provider_portal.more'),
          ),
        ],
      ),
    );
  }
}
