import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_car.dart';
import '../../domain/entities/customer_car_form_references.dart';
import '../../domain/entities/update_customer_car_command.dart';
import '../controllers/customer_car_detail_controller.dart';
import '../controllers/customer_car_form_references_controller.dart';
import '../controllers/customer_car_names_controller.dart';
import '../controllers/update_customer_car_controller.dart';
import '../customer_garage_failure_message.dart';
import '../widgets/customer_car_editor_fields.dart';

/// Edits the safe scalar fields of a saved car without duplicating the Add Car
/// form. Existing private photos remain visible on the details screen until a
/// dedicated, idempotent media-management contract is added.
class EditCustomerCarScreen extends ConsumerStatefulWidget {
  const EditCustomerCarScreen({required this.carId, super.key});

  final int carId;

  @override
  ConsumerState<EditCustomerCarScreen> createState() =>
      _EditCustomerCarScreenState();
}

class _EditCustomerCarScreenState extends ConsumerState<EditCustomerCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();

  int? _companyId;
  int? _carNameId;
  int? _colorId;
  int? _fuelTypeId;
  var _hasSeededDraft = false;
  var _isSchedulingDraftSeed = false;

  @override
  void dispose() {
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _seedDraft(CustomerCar car) {
    if (_hasSeededDraft || _isSchedulingDraftSeed) return;
    _isSchedulingDraftSeed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasSeededDraft) return;
      setState(() {
        _companyId = car.company.id;
        _carNameId = car.carName.id;
        _colorId = car.color.id;
        _fuelTypeId = car.fuelType.id;
        _yearController.text = car.manufacturingYear.toString();
        _plateController.text = car.licensePlateNumber;
        _hasSeededDraft = true;
        _isSchedulingDraftSeed = false;
      });
    });
  }

  void _markDraftChanged() {
    ref.read(updateCustomerCarControllerProvider.notifier).clearError();
  }

  int? _validSelectedId(int? selectedId, List<CustomerCarReference> values) {
    if (selectedId == null) return null;
    return values.any((value) => value.id == selectedId) ? selectedId : null;
  }

  Future<void> _submit(
    CustomerCarFormReferences references,
    List<CustomerCarReference> names,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final carNameId = _validSelectedId(_carNameId, names);
    final colorId = _validSelectedId(_colorId, references.colors);
    final fuelTypeId = _validSelectedId(_fuelTypeId, references.fuelTypes);
    final year = int.tryParse(_yearController.text.trim());
    if (carNameId == null ||
        colorId == null ||
        fuelTypeId == null ||
        year == null) {
      return;
    }

    await ref
        .read(updateCustomerCarControllerProvider.notifier)
        .submit(
          widget.carId,
          UpdateCustomerCarCommand(
            carNameId: carNameId,
            manufacturingYear: year,
            licensePlateNumber: _plateController.text.trim(),
            colorId: colorId,
            fuelTypeId: fuelTypeId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateCustomerCarState>(updateCustomerCarControllerProvider, (
      previous,
      next,
    ) {
      if (next.successfulSubmissionCount >
              (previous?.successfulSubmissionCount ?? 0) &&
          mounted) {
        context.pop(true);
      }
    });

    final car = ref.watch(customerCarDetailProvider(widget.carId));
    final references = ref.watch(customerCarFormReferencesControllerProvider);
    final submission = ref.watch(updateCustomerCarControllerProvider);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditCustomerCarHeader(onBack: () => context.pop(false)),
                const SizedBox(height: OctoGearSpacing.xLarge),
                car.when(
                  loading: () => const _EditCustomerCarLoading(),
                  error: (error, _) => _EditCustomerCarLoadError(
                    message: customerGarageFailureMessage(context, error),
                    onRetry: () =>
                        ref.invalidate(customerCarDetailProvider(widget.carId)),
                  ),
                  data: (value) {
                    _seedDraft(value);
                    if (!_hasSeededDraft) {
                      return const _EditCustomerCarLoading();
                    }
                    return references.when(
                      loading: () => const _EditCustomerCarLoading(),
                      error: (error, _) => _EditCustomerCarLoadError(
                        message: customerGarageFailureMessage(context, error),
                        onRetry: () => ref
                            .read(
                              customerCarFormReferencesControllerProvider
                                  .notifier,
                            )
                            .retry(),
                      ),
                      data: (values) => _buildForm(
                        context,
                        references: values,
                        submission: submission,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required CustomerCarFormReferences references,
    required UpdateCustomerCarState submission,
  }) {
    if (references.companies.isEmpty ||
        references.colors.isEmpty ||
        references.fuelTypes.isEmpty) {
      return _EditCustomerCarLoadError(
        message: context.tr('customer_garage.add.references_empty'),
        onRetry: () => ref
            .read(customerCarFormReferencesControllerProvider.notifier)
            .retry(),
      );
    }

    final companyId = _validSelectedId(_companyId, references.companies);
    final colorId = _validSelectedId(_colorId, references.colors);
    final fuelTypeId = _validSelectedId(_fuelTypeId, references.fuelTypes);
    final names = companyId == null
        ? null
        : ref.watch(customerCarNamesProvider(companyId));
    final nameValues = names?.asData?.value;
    final carNameId = nameValues == null
        ? null
        : _validSelectedId(_carNameId, nameValues);
    final failure = submission.error as ApiFailure?;
    final canSubmit =
        !submission.isSubmitting && nameValues?.isNotEmpty == true;

    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.edit.title'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('customer_garage.add.vehicle_details'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OctoGearSpacing.xLarge),
            CustomerCarEditorFields(
              references: references,
              carNames: names,
              companyId: companyId,
              carNameId: carNameId,
              colorId: colorId,
              fuelTypeId: fuelTypeId,
              yearController: _yearController,
              plateController: _plateController,
              enabled: !submission.isSubmitting,
              fieldErrors: failure?.fieldErrors ?? const {},
              onCompanyChanged: (value) {
                setState(() {
                  _companyId = value;
                  _carNameId = null;
                });
                _markDraftChanged();
              },
              onCarNameChanged: (value) {
                setState(() => _carNameId = value);
                _markDraftChanged();
              },
              onColorChanged: (value) {
                setState(() => _colorId = value);
                _markDraftChanged();
              },
              onFuelTypeChanged: (value) {
                setState(() => _fuelTypeId = value);
                _markDraftChanged();
              },
              onTextChanged: (_) => _markDraftChanged(),
              onRetryCarNames: companyId == null
                  ? null
                  : () => ref.invalidate(customerCarNamesProvider(companyId)),
            ),
            if (submission.error != null &&
                failure?.fieldErrors.isEmpty != false) ...[
              const SizedBox(height: OctoGearSpacing.large),
              OctoGearFeedbackBanner(
                message: customerGarageFailureMessage(
                  context,
                  submission.error!,
                ),
                tone: OctoGearFeedbackTone.error,
              ),
            ],
            if (submission.error != null &&
                isCustomerGarageRetryable(submission.error!)) ...[
              const SizedBox(height: OctoGearSpacing.medium),
              OutlinedButton.icon(
                key: const Key('customer_car_retry_update_button'),
                onPressed: submission.isSubmitting
                    ? null
                    : () => ref
                          .read(updateCustomerCarControllerProvider.notifier)
                          .retry(widget.carId),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.tr('customer_garage.edit.retry_submission'),
                ),
              ),
            ],
            const SizedBox(height: OctoGearSpacing.large),
            FilledButton(
              key: const Key('customer_car_save_changes_button'),
              onPressed: canSubmit
                  ? () => _submit(references, nameValues!)
                  : null,
              child: submission.isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(context.tr('customer_garage.edit.save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCustomerCarHeader extends StatelessWidget {
  const _EditCustomerCarHeader({required this.onBack});

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
            context.tr('customer_garage.edit.title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: OctoGearSpacing.xSmall),
        Text(
          context.tr('customer_garage.edit.description'),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: OctoGearColors.structuralGray),
        ),
      ],
    );
  }
}

class _EditCustomerCarLoading extends StatelessWidget {
  const _EditCustomerCarLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('customer_garage.details.loading'),
      child: const OctoGearSurfaceCard(
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class _EditCustomerCarLoadError extends StatelessWidget {
  const _EditCustomerCarLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.details.error_title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: OctoGearColors.error,
            size: 32,
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          Text(
            context.tr('customer_garage.details.error_title'),
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
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('common.retry')),
          ),
        ],
      ),
    );
  }
}
