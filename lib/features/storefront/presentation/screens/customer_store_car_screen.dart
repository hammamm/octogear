import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/storefront_car_catalog.dart';
import '../controllers/storefront_car_catalog_providers.dart';
import '../storefront_failure_message.dart';
import '../widgets/storefront_car_gallery.dart';
import '../widgets/storefront_component_card.dart';

class CustomerStoreCarScreen extends ConsumerWidget {
  const CustomerStoreCarScreen({
    required this.storeId,
    required this.carId,
    super.key,
  });
  final int storeId;
  final int carId;
  StorefrontCarKey get carKey => (storeId: storeId, carId: carId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(storefrontCarDetailsProvider(carKey));
    final parts = ref.watch(storefrontCarComponentsProvider(carKey));
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await Future.wait([
            ref.refresh(storefrontCarDetailsProvider(carKey).future),
            ref.refresh(storefrontCarComponentsProvider(carKey).future),
          ]);
        } catch (_) {
          /* Errors belong to their visible provider states. */
        }
      },
      child: CustomScrollView(
        key: PageStorageKey('store-car-$storeId-$carId'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : CustomerStoreDetailsRoute(
                                storeId: storeId,
                              ).go(context),
                        icon: const BackButtonIcon(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('storefront.car.title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AppLanguageToggleButton(compact: true),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ...detail.when(
                  skipLoadingOnRefresh: false,
                  loading: () => [
                    const SliverToBoxAdapter(child: _CatalogLoading()),
                  ],
                  error: (error, _) => [
                    SliverToBoxAdapter(
                      child: _CatalogError(
                        error: error,
                        onRetry: () => ref.invalidate(
                          storefrontCarDetailsProvider(carKey),
                        ),
                      ),
                    ),
                  ],
                  data: (details) => [
                    SliverToBoxAdapter(child: _CarSummary(details: details)),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          context.tr('storefront.car.parts_title'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: 4,
                          bottom: 16,
                        ),
                        child: Text(
                          context.tr('storefront.car.parts_subtitle'),
                        ),
                      ),
                    ),
                    ..._partsSlivers(context, ref, parts),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _partsSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StorefrontComponentsState> parts,
  ) => parts.when(
    skipLoadingOnRefresh: false,
    loading: () => [
      const SliverToBoxAdapter(child: _CatalogLoading(compact: true)),
    ],
    error: (error, _) => [
      SliverToBoxAdapter(
        child: _CatalogError(
          error: error,
          onRetry: () =>
              ref.invalidate(storefrontCarComponentsProvider(carKey)),
        ),
      ),
    ],
    data: (state) {
      if (state.page.components.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: OctoGearSurfaceCard(
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('storefront.car.empty_title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('storefront.car.empty_description'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ];
      }
      return [
        SliverList.separated(
          itemCount: state.page.components.length,
          itemBuilder: (_, index) => StorefrontComponentCard(
            key: ValueKey(state.page.components[index].id),
            part: state.page.components[index],
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(
                    'storefront.car.showing_count',
                    args: [
                      NumberFormat.decimalPattern(
                        context.locale.toLanguageTag(),
                      ).format(state.page.components.length),
                      NumberFormat.decimalPattern(
                        context.locale.toLanguageTag(),
                      ).format(state.page.total),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.nextPageError != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: 12,
                    ),
                    child: Text(
                      storefrontFailureMessage(context, state.nextPageError!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (state.page.hasNextPage) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isLoadingMore
                        ? null
                        : () => unawaited(
                            ref
                                .read(
                                  storefrontCarComponentsProvider(
                                    carKey,
                                  ).notifier,
                                )
                                .loadNextPage(),
                          ),
                    icon: state.isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(
                      context.tr(
                        state.nextPageError != null
                            ? 'common.retry'
                            : state.isLoadingMore
                            ? 'storefront.car.loading'
                            : 'storefront.car.load_more',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    },
  );
}

class _CarSummary extends StatelessWidget {
  const _CarSummary({required this.details});
  final StorefrontCarDetails details;

  @override
  Widget build(BuildContext context) {
    final car = details.car;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StorefrontCarGallery(car: car),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 18,
              color: OctoGearColors.structuralGray,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(details.store.name)),
          ],
        ),
        const SizedBox(height: 12),
        if (details.company != null)
          Text(
            details.company!.name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: OctoGearColors.structuralGray,
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              car.carName.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: OctoGearColors.yellowSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  NumberFormat(
                    '0',
                    context.locale.toLanguageTag(),
                  ).format(car.manufacturingYear),
                  textDirection: ui.TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OctoGearSurfaceCard(
          padding: const EdgeInsetsDirectional.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in [
                  (
                    Icons.palette_outlined,
                    'storefront.car.color',
                    car.color.name,
                  ),
                  (
                    Icons.local_gas_station_outlined,
                    'storefront.car.fuel',
                    car.fuelType.name,
                  ),
                ])
                  SizedBox(
                    width:
                        constraints.maxWidth < 240 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.4
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.$1,
                          size: 22,
                          color: OctoGearColors.structuralGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(item.$2),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                item.$3,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (details.sections.isNotEmpty) ...[
          const SizedBox(height: 12),
          OctoGearSurfaceCard(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: ExpansionTile(
              key: PageStorageKey('car-condition-${car.id}'),
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                context.tr('storefront.car.condition_report'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                for (final section in details.sections)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(section.name)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            context.tr(
                              'storefront.car.condition_${section.condition.name}',
                            ),
                            style: TextStyle(
                              color: switch (section.condition) {
                                StorefrontSectionCondition.okay =>
                                  OctoGearColors.success,
                                StorefrontSectionCondition.damaged =>
                                  OctoGearColors.error,
                                StorefrontSectionCondition.unknown =>
                                  OctoGearColors.structuralGray,
                              },
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: context.tr('storefront.car.loading'),
    child: ExcludeSemantics(
      child: Column(
        children: [
          Container(
            height: compact ? 140 : 230,
            decoration: BoxDecoration(
              color: OctoGearColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    ),
  );
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final missing =
        error is ApiFailure &&
        (error as ApiFailure).type == ApiFailureType.notFound;
    return OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            missing ? Icons.search_off_rounded : Icons.cloud_off_outlined,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              missing
                  ? 'storefront.car.unavailable'
                  : 'storefront.car.error_title',
            ),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            missing
                ? context.tr('storefront.car.unavailable_description')
                : storefrontFailureMessage(context, error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!missing)
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          if (missing)
            FilledButton(
              onPressed: () => const CustomerStoresRoute().go(context),
              child: Text(context.tr('storefront.details.back_to_stores')),
            ),
        ],
      ),
    );
  }
}
