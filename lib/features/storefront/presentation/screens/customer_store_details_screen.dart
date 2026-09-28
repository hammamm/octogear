import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/marketplace_store.dart';
import '../../domain/entities/storefront_store_details.dart';
import '../controllers/storefront_store_cars_controller.dart';
import '../controllers/storefront_store_details_controller.dart';
import '../storefront_failure_message.dart';
import '../widgets/storefront_store_car_card.dart';
import '../widgets/storefront_store_gallery.dart';

/// Customer-facing storefront: public store information plus its inventory.
///
/// Detail and inventory intentionally remain independent API states. A car
/// list outage must never hide a successfully loaded store identity.
class CustomerStoreDetailsScreen extends ConsumerWidget {
  const CustomerStoreDetailsScreen({required this.storeId, super.key});

  final int storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(storefrontStoreDetailsProvider(storeId));
    final inventory = ref.watch(storefrontStoreCarsControllerProvider(storeId));

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (details.asData != null &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 260) {
          unawaited(
            ref
                .read(storefrontStoreCarsControllerProvider(storeId).notifier)
                .loadNextPage(),
          );
        }
        return false;
      },
      child: RefreshIndicator(
        semanticsLabel: context.tr('storefront.details.refresh_label'),
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          key: PageStorageKey<String>('customer-store-details-$storeId'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _StoreDetailsHeader(onBack: () => context.pop()),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: OctoGearSpacing.xLarge),
                  ),
                  ..._contentSlivers(context, ref, details, inventory),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StorefrontStoreDetails> details,
    AsyncValue<StorefrontStoreCarsViewState> inventory,
  ) {
    return details.when(
      loading: () => const [SliverToBoxAdapter(child: _StoreDetailsLoading())],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: _StoreDetailsError(
            error: error,
            onRetry: () =>
                ref.invalidate(storefrontStoreDetailsProvider(storeId)),
          ),
        ),
      ],
      data: (store) => [
        SliverToBoxAdapter(child: _StoreDetailsSummary(store: store)),
        const SliverToBoxAdapter(
          child: SizedBox(height: OctoGearSpacing.xxLarge),
        ),
        SliverToBoxAdapter(
          child: _InventoryHeading(total: inventory.asData?.value.page.total),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: OctoGearSpacing.medium),
        ),
        ..._inventorySlivers(context, ref, inventory),
      ],
    );
  }

  List<Widget> _inventorySlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StorefrontStoreCarsViewState> inventory,
  ) {
    return inventory.when(
      loading: () => const [SliverToBoxAdapter(child: _InventoryLoading())],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: _InventoryError(
            error: error,
            onRetry: () => unawaited(
              ref
                  .read(storefrontStoreCarsControllerProvider(storeId).notifier)
                  .refresh(),
            ),
          ),
        ),
      ],
      data: (state) {
        if (state.page.cars.isEmpty) {
          return const [SliverToBoxAdapter(child: _InventoryEmpty())];
        }

        return [
          SliverList.separated(
            itemCount: state.page.cars.length,
            itemBuilder: (context, index) => StorefrontStoreCarCard(
              car: state.page.cars[index],
              onTap: () => CustomerStoreCarRoute(
                storeId: storeId,
                carId: state.page.cars[index].id,
              ).push<void>(context),
            ),
            separatorBuilder: (_, _) =>
                const SizedBox(height: OctoGearSpacing.medium),
          ),
          SliverToBoxAdapter(
            child: _InventoryPaginationFooter(
              state: state,
              onRetry: () => unawaited(
                ref
                    .read(
                      storefrontStoreCarsControllerProvider(storeId).notifier,
                    )
                    .loadNextPage(),
              ),
            ),
          ),
        ];
      },
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await Future.wait<void>([
        ref
            .refresh(storefrontStoreDetailsProvider(storeId).future)
            .then((_) {}),
        ref
            .read(storefrontStoreCarsControllerProvider(storeId).notifier)
            .refresh(),
      ]);
    } catch (_) {
      // Each provider owns its visible failure state. RefreshIndicator only
      // needs to finish without creating a second, unlocalized error surface.
    }
  }
}

class _StoreDetailsHeader extends StatelessWidget {
  const _StoreDetailsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const BackButtonIcon(),
            ),
            const Spacer(),
            const AppLanguageToggleButton(compact: true),
          ],
        ),
        const SizedBox(height: OctoGearSpacing.large),
        Semantics(
          header: true,
          child: Text(
            context.tr('storefront.details.title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }
}

class _StoreDetailsLoading extends StatelessWidget {
  const _StoreDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('storefront.details.loading'),
      child: const ExcludeSemantics(
        child: Column(
          children: [
            _StoreDetailsSkeleton(height: 264),
            SizedBox(height: OctoGearSpacing.large),
            _StoreDetailsSkeleton(height: 212),
          ],
        ),
      ),
    );
  }
}

class _StoreDetailsSkeleton extends StatelessWidget {
  const _StoreDetailsSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OctoGearColors.surfaceMuted,
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
      ),
    );
  }
}

class _StoreDetailsError extends StatelessWidget {
  const _StoreDetailsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('storefront.details.error_title'),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFF0EF),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              height: 56,
              width: 56,
              child: Icon(
                Icons.storefront_outlined,
                color: OctoGearColors.error,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Text(
            context.tr('storefront.details.error_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            storefrontFailureMessage(context, error),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: OctoGearSpacing.large),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ),
          const SizedBox(height: OctoGearSpacing.small),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => const CustomerStoresRoute().go(context),
              child: Text(context.tr('storefront.details.back_to_stores')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreDetailsSummary extends StatelessWidget {
  const _StoreDetailsSummary({required this.store});

  final StorefrontStoreDetails store;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toLanguageTag();
    final integerFormat = NumberFormat.decimalPattern(locale);
    final ratingFormat = NumberFormat('0.0', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StorefrontStoreGallery(store: store),
        const SizedBox(height: OctoGearSpacing.large),
        Text(
          store.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (store.name.isNotEmpty && store.name != store.displayName)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Text(
              store.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: OctoGearColors.structuralGray,
              ),
            ),
          ),
        const SizedBox(height: OctoGearSpacing.medium),
        _StoreLocation(cityName: store.city?.name),
        const SizedBox(height: OctoGearSpacing.large),
        Row(
          children: [
            if (store.averageRating != null)
              Expanded(
                child: _StoreStat(
                  icon: Icons.star_rounded,
                  iconColor: OctoGearColors.yellow,
                  label: context.tr('storefront.details.rating_label'),
                  value: ratingFormat.format(store.averageRating),
                ),
              ),
            if (store.averageRating != null)
              const SizedBox(width: OctoGearSpacing.small),
            Expanded(
              child: _StoreStat(
                icon: Icons.handshake_outlined,
                label: context.tr('storefront.details.sales_label'),
                value: integerFormat.format(store.soldQuantity),
              ),
            ),
          ],
        ),
        const SizedBox(height: OctoGearSpacing.large),
        _SupportedCompanies(companies: store.companies),
      ],
    );
  }
}

class _StoreLocation extends StatelessWidget {
  const _StoreLocation({required this.cityName});

  final String? cityName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: OctoGearColors.structuralGray,
          size: 20,
        ),
        const SizedBox(width: OctoGearSpacing.xSmall),
        Expanded(
          child: Text(
            cityName ?? context.tr('storefront.city_unavailable'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _StoreStat extends StatelessWidget {
  const _StoreStat({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = OctoGearColors.navy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OctoGearColors.surfaceMuted,
        borderRadius: BorderRadius.circular(OctoGearRadii.small),
        border: Border.all(color: OctoGearColors.border),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: OctoGearSpacing.xSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportedCompanies extends StatelessWidget {
  const _SupportedCompanies({required this.companies});

  final List<StorefrontReference> companies;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('storefront.details.companies_title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          if (companies.isEmpty)
            Text(
              context.tr('storefront.details.companies_empty'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: OctoGearSpacing.xSmall,
              runSpacing: OctoGearSpacing.xSmall,
              children: [
                for (final company in companies)
                  Chip(
                    avatar: const Icon(Icons.directions_car_outlined, size: 18),
                    label: Text(company.name),
                    side: const BorderSide(color: OctoGearColors.border),
                    backgroundColor: OctoGearColors.yellowSoft,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InventoryHeading extends StatelessWidget {
  const _InventoryHeading({this.total});

  final int? total;

  @override
  Widget build(BuildContext context) {
    final totalLabel = total == null
        ? null
        : NumberFormat.decimalPattern(
            context.locale.toLanguageTag(),
          ).format(total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.tr('storefront.details.inventory_title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: OctoGearSpacing.xSmall),
        Text(
          totalLabel == null
              ? context.tr('storefront.details.inventory_description')
              : context.tr(
                  'storefront.details.inventory_count_description',
                  args: [totalLabel],
                ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _InventoryLoading extends StatelessWidget {
  const _InventoryLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('storefront.details.inventory_loading'),
      child: const ExcludeSemantics(
        child: Column(
          children: [
            _StoreDetailsSkeleton(height: 144),
            SizedBox(height: OctoGearSpacing.medium),
            _StoreDetailsSkeleton(height: 144),
          ],
        ),
      ),
    );
  }
}

class _InventoryEmpty extends StatelessWidget {
  const _InventoryEmpty();

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      child: Column(
        children: [
          const Icon(
            Icons.directions_car_outlined,
            color: OctoGearColors.navy,
            size: 42,
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Text(
            context.tr('storefront.details.inventory_empty_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            context.tr('storefront.details.inventory_empty_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InventoryError extends StatelessWidget {
  const _InventoryError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: OctoGearColors.error,
            size: 42,
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Text(
            context.tr('storefront.details.inventory_error_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            storefrontFailureMessage(context, error),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: OctoGearSpacing.large),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryPaginationFooter extends StatelessWidget {
  const _InventoryPaginationFooter({
    required this.state,
    required this.onRetry,
  });

  final StorefrontStoreCarsViewState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsetsDirectional.only(top: OctoGearSpacing.large),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.nextPageError == null) {
      return const SizedBox(height: OctoGearSpacing.small);
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: OctoGearSpacing.large),
      child: OctoGearSurfaceCard(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          children: [
            Text(
              context.tr('storefront.details.load_more_error'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: OctoGearSpacing.small),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
