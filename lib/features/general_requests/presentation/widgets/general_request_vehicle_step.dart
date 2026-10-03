import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../customer_garage/domain/entities/customer_car_form_references.dart';
import '../../../customer_garage/domain/entities/customer_car.dart';
import '../../../customer_garage/presentation/widgets/customer_car_editor_fields.dart';
import 'general_request_feedback.dart';

/// Displays vehicle choices; the screen owns every draft value and mutation.
class GeneralRequestVehicleStep extends StatelessWidget {
  const GeneralRequestVehicleStep({
    required this.cars,
    required this.references,
    required this.names,
    required this.formKey,
    required this.manualVehicle,
    required this.savedCarId,
    required this.companyId,
    required this.carNameId,
    required this.colorId,
    required this.fuelTypeId,
    required this.yearController,
    required this.transmission,
    required this.saveToGarage,
    required this.disabled,
    required this.vehicleError,
    required this.transmissionError,
    required this.onVehicleModeChanged,
    required this.onSavedCarChanged,
    required this.onCompanyChanged,
    required this.onCarNameChanged,
    required this.onColorChanged,
    required this.onFuelTypeChanged,
    required this.onTransmissionChanged,
    required this.onSaveToGarageChanged,
    required this.onChanged,
    required this.onRetryCars,
    required this.onRetryReferences,
    required this.onRetryNames,
    super.key,
  });
  final AsyncValue<List<CustomerCar>> cars;
  final AsyncValue<CustomerCarFormReferences>? references;
  final AsyncValue<List<CustomerCarReference>>? names;
  final GlobalKey<FormState> formKey;
  final bool manualVehicle,
      saveToGarage,
      disabled,
      vehicleError,
      transmissionError;
  final int? savedCarId, companyId, carNameId, colorId, fuelTypeId;
  final TextEditingController yearController;
  final String? transmission;
  final ValueChanged<bool> onVehicleModeChanged, onSaveToGarageChanged;
  final ValueChanged<CustomerCar> onSavedCarChanged;
  final ValueChanged<int?> onCompanyChanged,
      onCarNameChanged,
      onColorChanged,
      onFuelTypeChanged;
  final ValueChanged<String?> onTransmissionChanged;
  final VoidCallback onChanged, onRetryCars, onRetryReferences, onRetryNames;

  @override
  Widget build(BuildContext context) {
    String tr(String key) => context.tr('general_request.$key');
    Widget loadError(VoidCallback retry) => Column(
      children: [
        GeneralRequestFeedback(message: tr('vehicle_load_error')),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('common.retry')),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('vehicle_hint'), style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(tr('saved_vehicle')),
              selected: !manualVehicle,
              onSelected: disabled
                  ? null
                  : (_) {
                      onVehicleModeChanged(false);
                    },
            ),
            ChoiceChip(
              key: const Key('general-new-vehicle'),
              label: Text(tr('new_vehicle')),
              selected: manualVehicle,
              onSelected: disabled
                  ? null
                  : (_) {
                      onVehicleModeChanged(true);
                    },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!manualVehicle)
          cars.when(
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => loadError(onRetryCars),
            data: (items) => items.isEmpty
                ? OctoGearSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.directions_car_outlined, size: 36),
                        const SizedBox(height: 12),
                        Text(tr('no_vehicles'), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: disabled
                              ? null
                              : () {
                                  onVehicleModeChanged(true);
                                },
                          child: Text(tr('new_vehicle')),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (final car in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Semantics(
                            selected: savedCarId == car.id,
                            child: OctoGearSurfaceCard(
                              key: ValueKey('request-car-${car.id}'),
                              onTap: disabled
                                  ? null
                                  : () {
                                      onSavedCarChanged(car);
                                    },
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    savedCarId == car.id
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: OctoGearColors.navy,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${car.company.name} ${car.carName.name}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${car.manufacturingYear} · ${car.color.name} · ${car.fuelType.name}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        if (manualVehicle)
          references!.when(
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => loadError(onRetryReferences),
            data: (values) => Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomerCarEditorFields(
                    transmissionRequired: true,
                    references: values,
                    carNames: names,
                    companyId: companyId,
                    carNameId: carNameId,
                    colorId: colorId,
                    fuelTypeId: fuelTypeId,
                    yearController: yearController,
                    transmissionType: transmission,
                    enabled: !disabled,
                    fieldErrors: {
                      if (transmissionError)
                        'transmission_type': [tr('transmission_required')],
                    },
                    onCompanyChanged: onCompanyChanged,
                    onCarNameChanged: onCarNameChanged,
                    onColorChanged: onColorChanged,
                    onFuelTypeChanged: onFuelTypeChanged,
                    onTransmissionChanged: onTransmissionChanged,
                    onTextChanged: (_) => onChanged(),
                    onRetryCarNames: onRetryNames,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    key: const Key('general-save-vehicle'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: saveToGarage,
                    onChanged: disabled
                        ? null
                        : (value) {
                            onSaveToGarageChanged(value!);
                          },
                    title: Text(tr('save_vehicle')),
                    subtitle: Text(tr('save_vehicle_hint')),
                  ),
                ],
              ),
            ),
          ),
        if (vehicleError)
          GeneralRequestFeedback(
            message: tr(manualVehicle ? 'vehicle_required' : 'choose_vehicle'),
          ),
      ],
    );
  }
}
