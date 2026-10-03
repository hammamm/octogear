import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../customer_garage/domain/entities/customer_car_form_references.dart';
import '../../../customer_garage/domain/entities/customer_car.dart';
import '../../../part_requests/domain/entities/part_request.dart';
import 'general_request_photos.dart';

class GeneralRequestReviewStep extends StatelessWidget {
  const GeneralRequestReviewStep({
    required this.saved,
    required this.refs,
    required this.names,
    required this.partName,
    required this.disabled,
    required this.manualVehicle,
    required this.companyId,
    required this.carNameId,
    required this.colorId,
    required this.fuelTypeId,
    required this.year,
    required this.transmission,
    required this.saveToGarage,
    required this.description,
    required this.photos,
    required this.onEditStep,
    super.key,
  });
  final CustomerCar? saved;
  final CustomerCarFormReferences? refs;
  final List<CustomerCarReference>? names;
  final String partName, year, description;
  final bool disabled, manualVehicle, saveToGarage;
  final int? companyId, carNameId, colorId, fuelTypeId;
  final String? transmission;
  final List<PartRequestPhoto> photos;
  final ValueChanged<int> onEditStep;
  @override
  Widget build(BuildContext context) {
    String tr(String key) => context.tr('general_request.$key');
    String reference(List<CustomerCarReference>? items, int? id) =>
        items?.where((item) => item.id == id).firstOrNull?.name ??
        tr('selected_value');
    Widget reviewCard(
      String title,
      IconData icon,
      int step,
      bool disabled,
      List<Widget> children,
    ) => OctoGearSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
              TextButton(
                key: ValueKey('general-edit-$step'),
                onPressed: disabled ? null : () => onEditStep(step),
                child: Text(tr('edit')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('review_hint'), style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        reviewCard(tr('vehicle'), Icons.directions_car_outlined, 0, disabled, [
          Text(
            manualVehicle
                ? '${reference(refs?.companies, companyId)} ${reference(names, carNameId)} · $year'
                : '${saved?.company.name ?? ''} ${saved?.carName.name ?? ''} · ${saved?.manufacturingYear ?? ''}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            manualVehicle
                ? '${reference(refs?.colors, colorId)} · ${reference(refs?.fuelTypes, fuelTypeId)} · ${context.tr('vehicle.$transmission')}'
                : '${saved?.color.name ?? ''} · ${saved?.fuelType.name ?? ''}${saved?.transmissionType == null ? '' : ' · ${context.tr('vehicle.${saved!.transmissionType}')}'}',
          ),
          if (manualVehicle && saveToGarage) ...[
            const SizedBox(height: 8),
            Text(
              tr('will_save_vehicle'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ]),
        const SizedBox(height: 16),
        reviewCard(tr('part'), Icons.build_outlined, 1, disabled, [
          Text(partName, style: Theme.of(context).textTheme.titleSmall),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description.trim()),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            GeneralRequestPhotos(photos: photos),
          ],
        ]),
      ],
    );
  }
}
