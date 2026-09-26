import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/octogear_theme.dart';
import '../../core/widgets/app_language_toggle_button.dart';
import '../../core/widgets/octogear_brand_header.dart';
import '../../core/widgets/octogear_surface_card.dart';
import '../routing/app_routes.dart';
import '../../features/authentication/domain/entities/app_user.dart';
import '../../features/authentication/domain/entities/session_outcome.dart';
import '../../features/authentication/presentation/controllers/session_controller.dart';

/// The persistent customer-only application shell.
///
/// Each destination owns a branch navigator through [StatefulNavigationShell].
/// That keeps a destination's future scroll position and child route stack when
/// the customer switches tabs. Feature content deliberately remains static in
/// this slice; APIs and feature controllers belong to later bounded features.
class CustomerAppShell extends StatelessWidget {
  const CustomerAppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
            colors: [Color(0xFFF9FAFC), OctoGearColors.canvas],
          ),
        ),
        child: SafeArea(bottom: false, child: navigationShell),
      ),
      bottomNavigationBar: _CustomerBottomNavigation(
        navigationShell: navigationShell,
      ),
    );
  }
}

class _CustomerBottomNavigation extends StatelessWidget {
  const _CustomerBottomNavigation({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: OctoGearColors.surface,
        border: Border(top: BorderSide(color: OctoGearColors.border)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: OctoGearColors.yellowSoft,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? OctoGearColors.navy
                  : OctoGearColors.structuralGray,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? OctoGearColors.navy
                  : OctoGearColors.structuralGray,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: context.tr('customer_shell.home.tab'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront_rounded),
              label: context.tr('customer_shell.stores.tab'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded),
              label: context.tr('customer_shell.orders.tab'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: context.tr('customer_shell.account.tab'),
            ),
          ],
        ),
      ),
    );
  }
}

enum CustomerShellDestination { home, stores, orders, account }

/// Temporary, intentional tab content for the navigation slice.
///
/// It communicates the purpose of each destination without fabricating empty
/// API data. Each route will be replaced by its bounded feature screen later.
class CustomerShellTabScreen extends ConsumerWidget {
  const CustomerShellTabScreen({required this.destination, super.key});

  final CustomerShellDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final user = session is AuthenticatedSession ? session.user : null;
    final content = _contentFor(destination);
    final title = destination == CustomerShellDestination.home
        ? context.tr(content.titleKey, args: [user?.fullName ?? ''])
        : context.tr(content.titleKey);

    return ListView(
      key: PageStorageKey<String>('customer-tab-${destination.name}'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
      children: [
        if (destination == CustomerShellDestination.home) ...[
          const OctoGearBrandHeader(compact: true, showTagline: false),
          const SizedBox(height: OctoGearSpacing.large),
        ],
        _TabHeading(
          eyebrow: context.tr(content.eyebrowKey),
          title: title,
          description: context.tr(content.descriptionKey),
        ),
        const SizedBox(height: OctoGearSpacing.large),
        _CustomerHeroCard(
          icon: content.icon,
          title: context.tr(content.heroTitleKey),
          description: context.tr(content.heroDescriptionKey),
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        if (destination == CustomerShellDestination.account && user != null)
          _CustomerProfileCard(user: user)
        else
          _PurposeCard(
            icon: content.secondaryIcon,
            title: context.tr(content.cardTitleKey),
            description: context.tr(content.cardDescriptionKey),
          ),
        if (destination == CustomerShellDestination.account) ...[
          const SizedBox(height: OctoGearSpacing.medium),
          const _CustomerGarageEntryCard(),
          const SizedBox(height: OctoGearSpacing.medium),
          _AccountSettingsCard(),
          const SizedBox(height: OctoGearSpacing.medium),
          _SignOutCard(),
        ],
      ],
    );
  }
}

class _TabHeading extends StatelessWidget {
  const _TabHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: OctoGearColors.structuralGray,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: OctoGearSpacing.xSmall),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: OctoGearSpacing.small),
        const AppLanguageToggleButton(compact: true),
      ],
    );
  }
}

class _CustomerHeroCard extends StatelessWidget {
  const _CustomerHeroCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OctoGearColors.navy,
        borderRadius: BorderRadius.circular(OctoGearRadii.large),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A242C41),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: OctoGearColors.yellow,
                borderRadius: BorderRadius.circular(OctoGearRadii.medium),
              ),
              child: SizedBox(
                height: 52,
                width: 52,
                child: Icon(icon, color: OctoGearColors.navy, size: 28),
              ),
            ),
            const SizedBox(width: OctoGearSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFDDE1EA),
                    ),
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

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: OctoGearColors.surfaceMuted,
              borderRadius: BorderRadius.circular(OctoGearRadii.medium),
            ),
            child: SizedBox(
              height: 48,
              width: 48,
              child: Icon(icon, color: OctoGearColors.navy, size: 24),
            ),
          ),
          const SizedBox(width: OctoGearSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerProfileCard extends StatelessWidget {
  const _CustomerProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName.trim().substring(0, 1).toUpperCase();
    final cityName =
        user.city?.name ?? context.tr('customer_shell.account.city_missing');

    return OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('customer_shell.account.profile_title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: OctoGearColors.yellowSoft,
                foregroundColor: OctoGearColors.navy,
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: OctoGearSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('customer_shell.account.role_label'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          const Divider(),
          const SizedBox(height: OctoGearSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: OctoGearColors.structuralGray,
                size: 20,
              ),
              const SizedBox(width: OctoGearSpacing.xSmall),
              Expanded(
                child: Text(
                  '${context.tr('customer_shell.account.city_label')}: $cityName',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerGarageEntryCard extends StatelessWidget {
  const _CustomerGarageEntryCard();

  @override
  Widget build(BuildContext context) {
    final title = context.tr('customer_garage.account_entry_title');
    final description = context.tr('customer_garage.account_entry_description');

    return OctoGearSurfaceCard(
      padding: EdgeInsets.zero,
      semanticLabel: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(OctoGearRadii.large),
        onTap: () {
          const CustomerCarsRoute().push<void>(context);
        },
        child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: OctoGearColors.yellowSoft,
                  borderRadius: BorderRadius.circular(OctoGearRadii.medium),
                ),
                child: const SizedBox(
                  height: 48,
                  width: 48,
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: OctoGearColors.navy,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: OctoGearSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OctoGearSpacing.small),
              const Icon(
                Icons.arrow_forward_rounded,
                color: OctoGearColors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PurposeCard(
      icon: Icons.tune_rounded,
      title: context.tr('customer_shell.account.settings_title'),
      description: context.tr('customer_shell.account.settings_description'),
    );
  }
}

class _SignOutCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OctoGearSurfaceCard(
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            unawaited(ref.read(sessionControllerProvider.notifier).signOut());
          },
          icon: const Icon(Icons.logout_rounded),
          label: Text(context.tr('common.sign_out')),
          style: OutlinedButton.styleFrom(
            foregroundColor: OctoGearColors.error,
            side: const BorderSide(color: Color(0x33B42318)),
          ),
        ),
      ),
    );
  }
}

_CustomerTabContent _contentFor(CustomerShellDestination destination) {
  return switch (destination) {
    CustomerShellDestination.home => const _CustomerTabContent(
      eyebrowKey: 'customer_shell.home.eyebrow',
      titleKey: 'customer_shell.home.title',
      descriptionKey: 'customer_shell.home.description',
      heroTitleKey: 'customer_shell.home.hero_title',
      heroDescriptionKey: 'customer_shell.home.hero_description',
      cardTitleKey: 'customer_shell.home.card_title',
      cardDescriptionKey: 'customer_shell.home.card_description',
      icon: Icons.search_rounded,
      secondaryIcon: Icons.directions_car_outlined,
    ),
    CustomerShellDestination.stores => const _CustomerTabContent(
      eyebrowKey: 'customer_shell.stores.eyebrow',
      titleKey: 'customer_shell.stores.title',
      descriptionKey: 'customer_shell.stores.description',
      heroTitleKey: 'customer_shell.stores.hero_title',
      heroDescriptionKey: 'customer_shell.stores.hero_description',
      cardTitleKey: 'customer_shell.stores.card_title',
      cardDescriptionKey: 'customer_shell.stores.card_description',
      icon: Icons.storefront_rounded,
      secondaryIcon: Icons.location_on_outlined,
    ),
    CustomerShellDestination.orders => const _CustomerTabContent(
      eyebrowKey: 'customer_shell.orders.eyebrow',
      titleKey: 'customer_shell.orders.title',
      descriptionKey: 'customer_shell.orders.description',
      heroTitleKey: 'customer_shell.orders.hero_title',
      heroDescriptionKey: 'customer_shell.orders.hero_description',
      cardTitleKey: 'customer_shell.orders.card_title',
      cardDescriptionKey: 'customer_shell.orders.card_description',
      icon: Icons.receipt_long_rounded,
      secondaryIcon: Icons.timeline_outlined,
    ),
    CustomerShellDestination.account => const _CustomerTabContent(
      eyebrowKey: 'customer_shell.account.eyebrow',
      titleKey: 'customer_shell.account.title',
      descriptionKey: 'customer_shell.account.description',
      heroTitleKey: 'customer_shell.account.hero_title',
      heroDescriptionKey: 'customer_shell.account.hero_description',
      cardTitleKey: 'customer_shell.account.settings_title',
      cardDescriptionKey: 'customer_shell.account.settings_description',
      icon: Icons.person_rounded,
      secondaryIcon: Icons.tune_rounded,
    ),
  };
}

class _CustomerTabContent {
  const _CustomerTabContent({
    required this.eyebrowKey,
    required this.titleKey,
    required this.descriptionKey,
    required this.heroTitleKey,
    required this.heroDescriptionKey,
    required this.cardTitleKey,
    required this.cardDescriptionKey,
    required this.icon,
    required this.secondaryIcon,
  });

  final String eyebrowKey;
  final String titleKey;
  final String descriptionKey;
  final String heroTitleKey;
  final String heroDescriptionKey;
  final String cardTitleKey;
  final String cardDescriptionKey;
  final IconData icon;
  final IconData secondaryIcon;
}
