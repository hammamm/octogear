import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/storefront_car_catalog.dart';

class StorefrontComponentCard extends StatelessWidget {
  const StorefrontComponentCard({required this.part, super.key});
  final StorefrontCarComponent part;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toLanguageTag();
    final numbers = NumberFormat.decimalPattern(locale);
    final price = NumberFormat.currency(
      locale: locale,
      name: part.currency,
      symbol: context.locale.languageCode == 'en'
          ? '${context.tr('storefront.car.sar')}\u00a0'
          : context.tr('storefront.car.sar'),
      decimalDigits: 2,
    ).format(part.priceMinor / part.priceScale);
    final warranty = switch (part.warrantyMonths) {
      null => context.tr('storefront.car.warranty_unspecified'),
      0 => context.tr('storefront.car.no_warranty'),
      final months => context.tr(
        'storefront.car.warranty_months',
        args: [numbers.format(months)],
      ),
    };
    return OctoGearSurfaceCard(
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(10),
                decoration: BoxDecoration(
                  color: OctoGearColors.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: OctoGearColors.navy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.component.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (part.section != null)
                      Text(
                        part.section!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: OctoGearColors.structuralGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(price, style: Theme.of(context).textTheme.titleLarge),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: part.inStock
                      ? const Color(0xFFEDF9F2)
                      : OctoGearColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    part.inStock
                        ? context.tr(
                            'storefront.car.in_stock',
                            args: [numbers.format(part.stockQuantity)],
                          )
                        : context.tr('storefront.car.out_of_stock'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: part.inStock
                          ? OctoGearColors.success
                          : OctoGearColors.structuralGray,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: 8),
            child: Divider(),
          ),
          if (part.partNumber != null) ...[
            Text(
              context.tr('storefront.car.part_number'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              part.partNumber!,
              textDirection: ui.TextDirection.ltr,
              textAlign: Directionality.of(context) == ui.TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 19,
                color: OctoGearColors.structuralGray,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(warranty)),
            ],
          ),
          if (part.description != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              key: PageStorageKey('part-description-${part.id}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsetsDirectional.only(bottom: 8),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                context.tr('storefront.car.description'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  part.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
