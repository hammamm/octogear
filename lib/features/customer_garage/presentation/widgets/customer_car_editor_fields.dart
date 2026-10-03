import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../../core/widgets/octogear_searchable_select_field.dart';
import '../../domain/entities/customer_car.dart';
import '../../domain/entities/customer_car_form_references.dart';
import '../customer_garage_failure_message.dart';

/// Vehicle fields shared by Add Car, Edit Car and general part requests.
///
/// Photo selection stays outside this widget because new local images and
/// existing private server images have different lifecycle and retry rules.
/// The parent owns its draft, allowing validation and request failures to
/// preserve every value a customer entered.
class CustomerCarEditorFields extends StatelessWidget {
  const CustomerCarEditorFields({
    required this.references,
    required this.carNames,
    required this.companyId,
    required this.carNameId,
    required this.colorId,
    required this.fuelTypeId,
    required this.yearController,
    required this.transmissionType,
    required this.onTransmissionChanged,
    required this.enabled,
    required this.fieldErrors,
    required this.onCompanyChanged,
    required this.onCarNameChanged,
    required this.onColorChanged,
    required this.onFuelTypeChanged,
    required this.onTextChanged,
    this.onRetryCarNames,
    this.transmissionRequired = false,
    super.key,
  });

  final CustomerCarFormReferences references;
  final AsyncValue<List<CustomerCarReference>>? carNames;
  final int? companyId;
  final int? carNameId;
  final int? colorId;
  final int? fuelTypeId;
  final TextEditingController yearController;
  final String? transmissionType;
  final ValueChanged<String?> onTransmissionChanged;
  final bool enabled;
  final Map<String, List<String>> fieldErrors;
  final ValueChanged<int?> onCompanyChanged;
  final ValueChanged<int?> onCarNameChanged;
  final ValueChanged<int?> onColorChanged;
  final ValueChanged<int?> onFuelTypeChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback? onRetryCarNames;
  final bool transmissionRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OctoGearSearchableSelectField<int>(
          key: const Key('customer_car_company_field'),
          value: companyId,
          label: context.tr('customer_garage.add.company_label'),
          hint: context.tr('customer_garage.add.company_hint'),
          searchHint: context.tr('customer_garage.add.company_search'),
          noResultsText: context.tr('customer_garage.add.company_no_results'),
          icon: Icons.factory_outlined,
          apiError: _fieldError('company_id'),
          options: [
            for (final item in references.companies)
              OctoGearSelectOption(value: item.id, label: item.name),
          ],
          onChanged: enabled ? onCompanyChanged : null,
          validator: (value) => _isValid(value, references.companies)
              ? null
              : context.tr('customer_garage.add.company_required'),
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        _CustomerCarNameField(
          key: ValueKey<int?>(companyId),
          names: carNames,
          selectedCarNameId: carNameId,
          enabled: enabled,
          apiError: _fieldError('car_name_id'),
          onChanged: onCarNameChanged,
          onRetry: onRetryCarNames,
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        TextFormField(
          key: const Key('customer_car_year_field'),
          controller: yearController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textDirection: ui.TextDirection.ltr,
          textInputAction: TextInputAction.next,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onTextChanged,
          decoration: InputDecoration(
            labelText: context.tr('customer_garage.add.year_label'),
            hintText: context.tr('customer_garage.add.year_hint'),
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            counterText: '',
            errorText: _fieldError('manufacturing_year'),
          ),
          validator: (value) => _validateYear(context, value),
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        DropdownButtonFormField<String>(
          key: const Key('customer_car_transmission_field'),
          initialValue: transmissionType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('vehicle.transmission'),
            hintText: context.tr(
              transmissionRequired
                  ? 'vehicle.transmission_required_hint'
                  : 'vehicle.transmission_hint',
            ),
            prefixIcon: const Icon(Icons.settings_outlined),
            errorText: _fieldError('transmission_type'),
          ),
          items: [
            for (final value in ['manual', 'automatic', 'unknown'])
              DropdownMenuItem(
                value: value,
                child: Text(context.tr('vehicle.$value')),
              ),
          ],
          onChanged: enabled ? onTransmissionChanged : null,
          validator: (value) => transmissionRequired && value == null
              ? context.tr('vehicle.transmission_required')
              : null,
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        DropdownButtonFormField<int>(
          key: const Key('customer_car_color_field'),
          initialValue: colorId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('customer_garage.add.color_label'),
            hintText: context.tr('customer_garage.add.color_hint'),
            prefixIcon: const Icon(Icons.palette_outlined),
            errorText: _fieldError('color_id'),
          ),
          items: _referenceItems(references.colors),
          onChanged: enabled ? onColorChanged : null,
          validator: (value) => _isValid(value, references.colors)
              ? null
              : context.tr('customer_garage.add.color_required'),
        ),
        const SizedBox(height: OctoGearSpacing.medium),
        DropdownButtonFormField<int>(
          key: const Key('customer_car_fuel_type_field'),
          initialValue: fuelTypeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('customer_garage.add.fuel_type_label'),
            hintText: context.tr('customer_garage.add.fuel_type_hint'),
            prefixIcon: const Icon(Icons.local_gas_station_outlined),
            errorText: _fieldError('fuel_type'),
          ),
          items: _referenceItems(references.fuelTypes),
          onChanged: enabled ? onFuelTypeChanged : null,
          validator: (value) => _isValid(value, references.fuelTypes)
              ? null
              : context.tr('customer_garage.add.fuel_type_required'),
        ),
      ],
    );
  }

  String? _fieldError(String name) => fieldErrors[name]?.first;

  static bool _isValid(int? selectedId, List<CustomerCarReference> values) {
    return selectedId != null && values.any((value) => value.id == selectedId);
  }

  static List<DropdownMenuItem<int>> _referenceItems(
    List<CustomerCarReference> values,
  ) {
    return values
        .map(
          (value) => DropdownMenuItem(value: value.id, child: Text(value.name)),
        )
        .toList(growable: false);
  }

  static String? _validateYear(BuildContext context, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return context.tr('customer_garage.add.year_required');

    final year = int.tryParse(text);
    final currentYear = DateTime.now().year;
    if (year == null || year < 1970 || year > currentYear) {
      return context.tr(
        'customer_garage.add.year_invalid',
        args: ['$currentYear'],
      );
    }
    return null;
  }
}

class _CustomerCarNameField extends StatelessWidget {
  const _CustomerCarNameField({
    required this.names,
    required this.selectedCarNameId,
    required this.enabled,
    required this.apiError,
    required this.onChanged,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<CustomerCarReference>>? names;
  final int? selectedCarNameId;
  final bool enabled;
  final String? apiError;
  final ValueChanged<int?> onChanged;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (names == null) {
      return _DisabledCustomerCarNameField(
        message: context.tr('customer_garage.add.car_name_before_company'),
      );
    }

    return names!.when(
      loading: () => _DisabledCustomerCarNameField(
        message: context.tr('customer_garage.add.car_names_loading'),
        isLoading: true,
      ),
      error: (error, _) => _CustomerCarNameLoadError(
        message: customerGarageFailureMessage(context, error),
        onRetry: onRetry,
      ),
      data: (values) {
        if (values.isEmpty) {
          return _CustomerCarNameLoadError(
            message: context.tr('customer_garage.add.car_names_empty'),
            onRetry: onRetry,
          );
        }

        final selectedId = values.any((value) => value.id == selectedCarNameId)
            ? selectedCarNameId
            : null;
        return OctoGearSearchableSelectField<int>(
          key: const Key('customer_car_name_field'),
          value: selectedId,
          label: context.tr('customer_garage.add.car_name_label'),
          hint: context.tr('customer_garage.add.car_name_hint'),
          searchHint: context.tr('customer_garage.add.car_name_search'),
          noResultsText: context.tr('customer_garage.add.car_name_no_results'),
          icon: Icons.directions_car_outlined,
          apiError: apiError,
          options: [
            for (final item in values)
              OctoGearSelectOption(value: item.id, label: item.name),
          ],
          onChanged: enabled ? onChanged : null,
          validator: (value) => values.any((item) => item.id == value)
              ? null
              : context.tr('customer_garage.add.car_name_required'),
        );
      },
    );
  }
}

class _DisabledCustomerCarNameField extends StatelessWidget {
  const _DisabledCustomerCarNameField({
    required this.message,
    this.isLoading = false,
  });

  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: context.tr('customer_garage.add.car_name_label'),
        prefixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.directions_car_outlined),
        enabled: false,
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _CustomerCarNameLoadError extends StatelessWidget {
  const _CustomerCarNameLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OctoGearFeedbackBanner(
          message: message,
          tone: OctoGearFeedbackTone.error,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: OctoGearSpacing.xSmall),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('common.retry')),
          ),
        ],
      ],
    );
  }
}
