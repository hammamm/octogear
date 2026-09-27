import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_car.dart';

/// Read-only saved-car summary shown in the customer's personal garage.
class CustomerCarCard extends StatelessWidget {
  const CustomerCarCard({required this.car, this.onTap, super.key});

  final CustomerCar car;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // A manufacturing year is an identifier, not a quantity. It must remain
    // four digits without a thousands separator in both supported languages.
    final year = NumberFormat(
      '0000',
      context.locale.languageCode,
    ).format(car.manufacturingYear);

    return OctoGearSurfaceCard(
      semanticLabel: car.carName.name,
      padding: const EdgeInsetsDirectional.all(20),
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(OctoGearRadii.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomerCarImage(car: car),
                const SizedBox(width: OctoGearSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          car.carName.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        car.company.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      _CarDetailLine(
                        icon: Icons.calendar_today_outlined,
                        label: context.tr('customer_garage.cars.year_label'),
                        value: year,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: OctoGearColors.structuralGray,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: OctoGearSpacing.medium),
            const Divider(),
            const SizedBox(height: OctoGearSpacing.medium),
            _CarDetailLine(
              icon: Icons.palette_outlined,
              label: context.tr('customer_garage.cars.color_label'),
              value: car.color.name,
            ),
            const SizedBox(height: OctoGearSpacing.small),
            _CarDetailLine(
              icon: Icons.local_gas_station_outlined,
              label: context.tr('customer_garage.cars.fuel_type_label'),
              value: car.fuelType.name,
            ),
            const SizedBox(height: OctoGearSpacing.small),
            _CarDetailLine(
              icon: Icons.pin_outlined,
              label: context.tr('customer_garage.cars.plate_label'),
              value: car.licensePlateNumber,
              valueDirection: ui.TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCarImage extends StatelessWidget {
  const _CustomerCarImage({required this.car});

  final CustomerCar car;

  @override
  Widget build(BuildContext context) {
    final picture = car.pictures.isEmpty ? null : car.pictures.first;
    final pixelSize = (88 * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox(
      height: 88,
      width: 88,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OctoGearRadii.small),
        child: picture == null
            ? const _CarImageFallback()
            : AuthenticatedNetworkImage(
                apiPath: picture.url,
                semanticLabel: context.tr(
                  'customer_garage.cars.photo_semantics',
                ),
                cacheWidth: pixelSize,
                cacheHeight: pixelSize,
                errorBuilder: (_, _, _) => const _CarImageFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _CarImageFallback(isLoading: true);
                },
              ),
      ),
    );
  }
}

class _CarImageFallback extends StatelessWidget {
  const _CarImageFallback({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ColoredBox(
        color: OctoGearColors.yellowSoft,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(
                  Icons.directions_car_outlined,
                  size: 38,
                  color: OctoGearColors.navy,
                ),
        ),
      ),
    );
  }
}

class _CarDetailLine extends StatelessWidget {
  const _CarDetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.valueDirection,
  });

  final IconData icon;
  final String label;
  final String value;
  final ui.TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: OctoGearColors.structuralGray),
        const SizedBox(width: OctoGearSpacing.small),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Directionality(
                    textDirection: valueDirection ?? Directionality.of(context),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
