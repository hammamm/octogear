import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_car.dart';

/// Readable vehicle facts shared by the car-details experience.
class CustomerCarInformationCard extends StatelessWidget {
  const CustomerCarInformationCard({required this.car, super.key});

  final CustomerCar car;

  @override
  Widget build(BuildContext context) {
    final year = NumberFormat(
      '0000',
      context.locale.languageCode,
    ).format(car.manufacturingYear);

    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.details.vehicle_details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('customer_garage.details.vehicle_details'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          _CustomerCarInformationRow(
            icon: Icons.factory_outlined,
            label: context.tr('customer_garage.details.company_label'),
            value: car.company.name,
          ),
          const Divider(height: OctoGearSpacing.large),
          _CustomerCarInformationRow(
            icon: Icons.directions_car_outlined,
            label: context.tr('customer_garage.add.car_name_label'),
            value: car.carName.name,
          ),
          const Divider(height: OctoGearSpacing.large),
          _CustomerCarInformationRow(
            icon: Icons.calendar_today_outlined,
            label: context.tr('customer_garage.details.year_label'),
            value: year,
            valueDirection: ui.TextDirection.ltr,
          ),
          const Divider(height: OctoGearSpacing.large),
          _CustomerCarInformationRow(
            icon: Icons.pin_outlined,
            label: context.tr('customer_garage.details.plate_label'),
            value: car.licensePlateNumber,
            valueDirection: ui.TextDirection.ltr,
          ),
          const Divider(height: OctoGearSpacing.large),
          _CustomerCarInformationRow(
            icon: Icons.palette_outlined,
            label: context.tr('customer_garage.details.color_label'),
            value: car.color.name,
          ),
          const Divider(height: OctoGearSpacing.large),
          _CustomerCarInformationRow(
            icon: Icons.local_gas_station_outlined,
            label: context.tr('customer_garage.details.fuel_type_label'),
            value: car.fuelType.name,
          ),
        ],
      ),
    );
  }
}

class _CustomerCarInformationRow extends StatelessWidget {
  const _CustomerCarInformationRow({
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
        Icon(icon, color: OctoGearColors.structuralGray, size: 21),
        const SizedBox(width: OctoGearSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Directionality(
                textDirection: valueDirection ?? Directionality.of(context),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
