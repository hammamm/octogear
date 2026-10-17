import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/customer_chats/presentation/controllers/chat_activity_controller.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/octogear_theme.dart';

/// Independent provider branches preserve their navigation stacks on tab changes.
class ProviderAppShell extends ConsumerWidget {
  const ProviderAppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            icon: Badge(
              isLabelVisible:
                  navigationShell.currentIndex != 2 &&
                  ref.watch(chatActivityProvider),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
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
