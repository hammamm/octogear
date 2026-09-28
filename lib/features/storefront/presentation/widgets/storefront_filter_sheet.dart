import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/marketplace_store.dart';
import '../../domain/entities/storefront_filter_options.dart';
import '../../domain/entities/storefront_filters.dart';
import '../controllers/storefront_filter_options_controller.dart';

/// Bottom sheet for the two server-supported storefront narrowing filters.
class StorefrontFilterSheet extends ConsumerStatefulWidget {
  const StorefrontFilterSheet({required this.initialFilters, super.key});

  final StorefrontFilters initialFilters;

  @override
  ConsumerState<StorefrontFilterSheet> createState() =>
      _StorefrontFilterSheetState();
}

class _StorefrontFilterSheetState extends ConsumerState<StorefrontFilterSheet> {
  late int? _cityId = widget.initialFilters.cityId;
  late int? _companyId = widget.initialFilters.companyId;

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(storefrontFilterOptionsProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
        child: options.when(
          loading: () => const _FilterSheetLoading(),
          error: (_, _) => _FilterSheetOptionsError(
            onRetry: () => ref.invalidate(storefrontFilterOptionsProvider),
          ),
          data: (values) => _FilterSheetContent(
            options: values,
            cityId: _knownId(_cityId, values.cities),
            companyId: _knownId(_companyId, values.companies),
            onCityChanged: (value) => setState(() => _cityId = value),
            onCompanyChanged: (value) => setState(() => _companyId = value),
            onClear: () => setState(() {
              _cityId = null;
              _companyId = null;
            }),
            onApply: () => Navigator.of(context).pop(
              StorefrontFilters(
                query: widget.initialFilters.query,
                cityId: _knownId(_cityId, values.cities),
                companyId: _knownId(_companyId, values.companies),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _knownId(int? selected, List<StorefrontReference> options) {
    if (selected == null) return null;
    return options.any((option) => option.id == selected) ? selected : null;
  }
}

class _FilterSheetContent extends StatelessWidget {
  const _FilterSheetContent({
    required this.options,
    required this.cityId,
    required this.companyId,
    required this.onCityChanged,
    required this.onCompanyChanged,
    required this.onClear,
    required this.onApply,
  });

  final StorefrontFilterOptions options;
  final int? cityId;
  final int? companyId;
  final ValueChanged<int?> onCityChanged;
  final ValueChanged<int?> onCompanyChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            height: 4,
            width: 42,
            decoration: BoxDecoration(
              color: OctoGearColors.border,
              borderRadius: BorderRadius.circular(OctoGearRadii.pill),
            ),
          ),
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('storefront.filter_title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(context.tr('storefront.clear_filters')),
            ),
          ],
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        DropdownButtonFormField<int>(
          key: const Key('storefront_city_filter'),
          initialValue: cityId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('storefront.city_label'),
          ),
          items: [
            DropdownMenuItem<int>(
              child: Text(context.tr('storefront.city_all')),
            ),
            ...options.cities.map(
              (option) => DropdownMenuItem<int>(
                value: option.id,
                child: Text(option.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onCityChanged,
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        DropdownButtonFormField<int>(
          key: const Key('storefront_company_filter'),
          initialValue: companyId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('storefront.company_label'),
          ),
          items: [
            DropdownMenuItem<int>(
              child: Text(context.tr('storefront.company_all')),
            ),
            ...options.companies.map(
              (option) => DropdownMenuItem<int>(
                value: option.id,
                child: Text(option.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onCompanyChanged,
        ),
        const SizedBox(height: OctoGearSpacing.large),
        FilledButton(
          key: const Key('storefront_apply_filters_button'),
          onPressed: onApply,
          child: Text(context.tr('storefront.apply_filters')),
        ),
      ],
    );
  }
}

class _FilterSheetLoading extends StatelessWidget {
  const _FilterSheetLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: context.tr('storefront.options_loading'),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _FilterSheetOptionsError extends StatelessWidget {
  const _FilterSheetOptionsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, size: 32, color: OctoGearColors.navy),
          const SizedBox(height: OctoGearSpacing.small),
          Text(
            context.tr('storefront.options_error'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
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
