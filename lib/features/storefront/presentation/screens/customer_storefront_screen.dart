import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/storefront_filters.dart';
import '../controllers/storefront_controller.dart';
import '../storefront_failure_message.dart';
import '../widgets/storefront_filter_sheet.dart';
import '../widgets/storefront_store_card.dart';

/// Customer discovery of active spare-parts stores.
///
/// Search is deliberately debounced, pagination is guarded by the provider,
/// and a late response cannot replace newer filters.
class CustomerStorefrontScreen extends ConsumerStatefulWidget {
  const CustomerStorefrontScreen({super.key});

  @override
  ConsumerState<CustomerStorefrontScreen> createState() =>
      _CustomerStorefrontScreenState();
}

class _CustomerStorefrontScreenState
    extends ConsumerState<CustomerStorefrontScreen> {
  final _searchController = TextEditingController();
  StorefrontFilters _filters = const StorefrontFilters.empty();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(storefrontControllerProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 260) {
          unawaited(
            ref.read(storefrontControllerProvider.notifier).loadNextPage(),
          );
        }
        return false;
      },
      child: RefreshIndicator(
        semanticsLabel: context.tr('storefront.refresh_label'),
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const PageStorageKey<String>('customer-storefront'),
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _StorefrontHeader(
                      searchController: _searchController,
                      filters: _filters,
                      onSearchChanged: _onSearchChanged,
                      onSearchSubmitted: _applySearchImmediately,
                      onOpenFilters: _openFilters,
                      onClearFilters: _clearFilters,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: OctoGearSpacing.large),
                  ),
                  ..._resultSlivers(context, results),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _resultSlivers(
    BuildContext context,
    AsyncValue<StorefrontViewState> results,
  ) {
    return results.when(
      loading: () => const [SliverToBoxAdapter(child: _StorefrontLoading())],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: _StorefrontError(
            message: storefrontFailureMessage(context, error),
            onRetry: _refresh,
          ),
        ),
      ],
      data: (value) {
        if (value.page.stores.isEmpty) {
          return [
            SliverToBoxAdapter(child: _StorefrontEmpty(filters: value.filters)),
          ];
        }

        return [
          SliverList.separated(
            itemCount: value.page.stores.length,
            itemBuilder: (context, index) {
              final store = value.page.stores[index];
              return StorefrontStoreCard(
                store: store,
                onTap: () => _openStoreDetails(store.id),
              );
            },
            separatorBuilder: (_, _) =>
                const SizedBox(height: OctoGearSpacing.medium),
          ),
          SliverToBoxAdapter(
            child: _StorefrontPaginationFooter(
              state: value,
              onRetry: () => ref
                  .read(storefrontControllerProvider.notifier)
                  .loadNextPage(),
            ),
          ),
        ];
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() => _filters = _filters.copyWith(query: value));
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(
        ref.read(storefrontControllerProvider.notifier).applyFilters(_filters),
      );
    });
  }

  void _applySearchImmediately(String _) {
    _searchDebounce?.cancel();
    setState(() => _filters = _filters.copyWith(query: _searchController.text));
    unawaited(
      ref.read(storefrontControllerProvider.notifier).applyFilters(_filters),
    );
  }

  Future<void> _openFilters() async {
    _searchDebounce?.cancel();
    final selected = await showModalBottomSheet<StorefrontFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => StorefrontFilterSheet(initialFilters: _filters),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _filters = selected;
      _searchController.value = TextEditingValue(
        text: selected.query,
        selection: TextSelection.collapsed(offset: selected.query.length),
      );
    });
    await ref
        .read(storefrontControllerProvider.notifier)
        .applyFilters(selected);
  }

  Future<void> _clearFilters() async {
    _searchDebounce?.cancel();
    setState(() {
      _filters = const StorefrontFilters.empty();
      _searchController.clear();
    });
    await ref
        .read(storefrontControllerProvider.notifier)
        .applyFilters(_filters);
  }

  Future<void> _refresh() async {
    try {
      await ref.read(storefrontControllerProvider.notifier).refresh();
    } catch (_) {
      // The controller keeps a clear inline error state; RefreshIndicator must
      // finish cleanly instead of producing a second error surface.
    }
  }

  Future<void> _openStoreDetails(int storeId) async {
    await CustomerStoreDetailsRoute(storeId: storeId).push<void>(context);
  }
}

class _StorefrontHeader extends StatelessWidget {
  const _StorefrontHeader({
    required this.searchController,
    required this.filters,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onOpenFilters,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final StorefrontFilters filters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('storefront.title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: OctoGearSpacing.xSmall),
                  Text(
                    context.tr('storefront.description'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: OctoGearColors.structuralGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: OctoGearSpacing.small),
            const AppLanguageToggleButton(compact: true),
          ],
        ),
        const SizedBox(height: OctoGearSpacing.large),
        TextField(
          key: const Key('storefront_search_field'),
          controller: searchController,
          maxLength: 100,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
          decoration: InputDecoration(
            labelText: context.tr('storefront.search_label'),
            hintText: context.tr('storefront.search_hint'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            counterText: '',
          ),
        ),
        const SizedBox(height: OctoGearSpacing.small),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('storefront_open_filters_button'),
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune_rounded),
                label: Text(context.tr('storefront.filter')),
              ),
            ),
            if (filters.hasActiveFilters) ...[
              const SizedBox(width: OctoGearSpacing.small),
              TextButton(
                onPressed: onClearFilters,
                child: Text(
                  context.tr(
                    'storefront.filters_active',
                    args: ['${filters.activeFilterCount}'],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StorefrontLoading extends StatelessWidget {
  const _StorefrontLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('storefront.loading'),
      child: const ExcludeSemantics(
        child: Column(
          children: [
            _StorefrontSkeleton(),
            SizedBox(height: OctoGearSpacing.medium),
            _StorefrontSkeleton(),
            SizedBox(height: OctoGearSpacing.medium),
            _StorefrontSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _StorefrontSkeleton extends StatelessWidget {
  const _StorefrontSkeleton();

  @override
  Widget build(BuildContext context) {
    return const OctoGearSurfaceCard(
      padding: EdgeInsetsDirectional.all(16),
      child: Row(
        children: [
          _StorefrontSkeletonBlock(height: 88, width: 88),
          SizedBox(width: OctoGearSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StorefrontSkeletonBlock(height: 18, width: 164),
                SizedBox(height: OctoGearSpacing.small),
                _StorefrontSkeletonBlock(height: 14, width: 116),
                SizedBox(height: OctoGearSpacing.small),
                _StorefrontSkeletonBlock(height: 14, width: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorefrontSkeletonBlock extends StatelessWidget {
  const _StorefrontSkeletonBlock({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: OctoGearColors.surfaceMuted,
        borderRadius: BorderRadius.circular(OctoGearRadii.small),
      ),
    );
  }
}

class _StorefrontEmpty extends StatelessWidget {
  const _StorefrontEmpty({required this.filters});

  final StorefrontFilters filters;

  @override
  Widget build(BuildContext context) {
    final descriptionKey = filters.hasActiveFilters
        ? 'storefront.empty_description'
        : 'storefront.empty_unfiltered_description';
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('storefront.empty_title'),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: OctoGearColors.yellowSoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              height: 72,
              width: 72,
              child: Icon(
                Icons.storefront_outlined,
                size: 36,
                color: OctoGearColors.navy,
              ),
            ),
          ),
          const SizedBox(height: OctoGearSpacing.large),
          Text(
            context.tr('storefront.empty_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            context.tr(descriptionKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StorefrontError extends StatelessWidget {
  const _StorefrontError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('storefront.error_title'),
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
                Icons.cloud_off_outlined,
                color: OctoGearColors.error,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Text(
            context.tr('storefront.error_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.xSmall),
          Text(
            message,
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

class _StorefrontPaginationFooter extends StatelessWidget {
  const _StorefrontPaginationFooter({
    required this.state,
    required this.onRetry,
  });

  final StorefrontViewState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsetsDirectional.only(top: OctoGearSpacing.large),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.nextPageError != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: OctoGearSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OctoGearFeedbackBanner(
              tone: OctoGearFeedbackTone.error,
              message: context.tr('storefront.load_more_error'),
            ),
            const SizedBox(height: OctoGearSpacing.small),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: OctoGearSpacing.medium);
  }
}
