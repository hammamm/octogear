import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/create_customer_car_command.dart';
import '../../domain/entities/customer_car.dart';
import '../../domain/entities/customer_car_form_references.dart';
import '../controllers/create_customer_car_controller.dart';
import '../controllers/customer_car_form_references_controller.dart';
import '../controllers/customer_car_names_controller.dart';
import '../customer_garage_failure_message.dart';
import '../services/customer_car_gallery_picker.dart';
import '../widgets/customer_car_editor_fields.dart';
import '../widgets/customer_car_photo_picker.dart';

/// Customer-only form for creating a saved car and optional private photos.
///
/// It owns the in-progress draft so a server, timeout, or picker failure never
/// clears customer input. Network submission state stays in the Riverpod
/// controller, and all HTTP/media work stays below presentation.
class CreateCustomerCarScreen extends ConsumerStatefulWidget {
  const CreateCustomerCarScreen({super.key});

  @override
  ConsumerState<CreateCustomerCarScreen> createState() =>
      _CreateCustomerCarScreenState();
}

class _CreateCustomerCarScreenState
    extends ConsumerState<CreateCustomerCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  String? _transmissionType;

  int? _companyId;
  int? _carNameId;
  int? _colorId;
  int? _fuelTypeId;
  List<CustomerCarPhotoUpload> _photos = const [];
  String? _photoPickerError;
  late String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_recoverLostPhotos());
    });
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _markDraftChanged() {
    // A new command after an edit must not reuse an earlier uncertain request's
    // idempotency key. The controller alone reuses its stored key on Retry.
    _idempotencyKey = const Uuid().v4();
  }

  Future<void> _recoverLostPhotos() async {
    CustomerCarPhotoSelection selection;
    try {
      selection = await ref
          .read(customerCarGalleryPickerProvider)
          .recoverLostPhotos();
    } on CustomerCarGalleryPickerException {
      if (!mounted) return;
      setState(
        () => _photoPickerError = context.tr(
          'customer_garage.add.photo_picker_error',
        ),
      );
      return;
    }

    if (!mounted) return;
    _addPhotoSelection(selection);
  }

  Future<void> _pickPhotos() async {
    final remaining = customerCarPhotoLimit - _photos.length;
    if (remaining <= 0) return;

    CustomerCarPhotoSelection selection;
    try {
      selection = await ref
          .read(customerCarGalleryPickerProvider)
          .pickPhotos(limit: remaining);
    } on CustomerCarGalleryPickerException {
      if (!mounted) return;
      setState(
        () => _photoPickerError = context.tr(
          'customer_garage.add.photo_picker_error',
        ),
      );
      return;
    }

    if (!mounted) return;
    _addPhotoSelection(selection);
  }

  void _addPhotoSelection(CustomerCarPhotoSelection selection) {
    final remaining = customerCarPhotoLimit - _photos.length;
    final additions = selection.photos.take(remaining).toList(growable: false);
    if (additions.isNotEmpty) {
      setState(() {
        _markDraftChanged();
        _photos = List.unmodifiable([..._photos, ...additions]);
        _photoPickerError = null;
      });
    }

    if (selection.rejectedPhotoCount > 0 && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.tr('customer_garage.add.photos_rejected')),
          ),
        );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _markDraftChanged();
      _photos = List.unmodifiable([
        for (
          var currentIndex = 0;
          currentIndex < _photos.length;
          currentIndex++
        )
          if (currentIndex != index) _photos[currentIndex],
      ]);
    });
  }

  Future<void> _submit(
    CustomerCarFormReferences references,
    List<CustomerCarReference> names,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final companyId = _validSelectedId(_companyId, references.companies);
    final carNameId = _validSelectedId(_carNameId, names);
    final colorId = _validSelectedId(_colorId, references.colors);
    final fuelTypeId = _validSelectedId(_fuelTypeId, references.fuelTypes);
    if (companyId == null ||
        carNameId == null ||
        colorId == null ||
        fuelTypeId == null) {
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    if (year == null) return;

    await ref
        .read(createCustomerCarControllerProvider.notifier)
        .submit(
          CreateCustomerCarCommand(
            carNameId: carNameId,
            manufacturingYear: year,
            transmissionType: _transmissionType,
            colorId: colorId,
            fuelTypeId: fuelTypeId,
            pictures: _photos,
            idempotencyKey: _idempotencyKey,
          ),
        );
  }

  int? _validSelectedId(int? selectedId, List<CustomerCarReference> values) {
    if (selectedId == null) return null;
    return values.any((value) => value.id == selectedId) ? selectedId : null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreateCustomerCarState>(createCustomerCarControllerProvider, (
      previous,
      next,
    ) {
      if (next.successfulSubmissionCount >
              (previous?.successfulSubmissionCount ?? 0) &&
          mounted) {
        context.pop(true);
      }
    });

    final references = ref.watch(customerCarFormReferencesControllerProvider);
    final submission = ref.watch(createCustomerCarControllerProvider);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CreateCustomerCarHeader(onBack: () => context.pop(false)),
                const SizedBox(height: OctoGearSpacing.xLarge),
                references.when(
                  loading: () => const _ReferencesLoading(),
                  error: (error, _) => _ReferencesError(
                    message: customerGarageFailureMessage(context, error),
                    onRetry: () => ref
                        .read(
                          customerCarFormReferencesControllerProvider.notifier,
                        )
                        .retry(),
                  ),
                  data: (values) => _buildFormForReferences(
                    context,
                    references: values,
                    submission: submission,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormForReferences(
    BuildContext context, {
    required CustomerCarFormReferences references,
    required CreateCustomerCarState submission,
  }) {
    if (references.companies.isEmpty ||
        references.colors.isEmpty ||
        references.fuelTypes.isEmpty) {
      return _ReferencesError(
        message: context.tr('customer_garage.add.references_empty'),
        onRetry: () => ref
            .read(customerCarFormReferencesControllerProvider.notifier)
            .retry(),
      );
    }

    final selectedCompanyId = _validSelectedId(
      _companyId,
      references.companies,
    );
    final selectedColorId = _validSelectedId(_colorId, references.colors);
    final selectedFuelTypeId = _validSelectedId(
      _fuelTypeId,
      references.fuelTypes,
    );
    final names = selectedCompanyId == null
        ? null
        : ref.watch(customerCarNamesProvider(selectedCompanyId));
    final nameValues = names?.asData?.value;
    final selectedCarNameId = nameValues == null
        ? null
        : _validSelectedId(_carNameId, nameValues);
    final apiFailure = submission.error as ApiFailure?;
    final canSubmit =
        !submission.isSubmitting && nameValues?.isNotEmpty == true;

    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.add.title'),
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
              companyId: selectedCompanyId,
              carNameId: selectedCarNameId,
              colorId: selectedColorId,
              fuelTypeId: selectedFuelTypeId,
              yearController: _yearController,
              transmissionType: _transmissionType,
              onTransmissionChanged: (value) {
                setState(() => _transmissionType = value);
                _markDraftChanged();
              },
              enabled: !submission.isSubmitting,
              fieldErrors: apiFailure?.fieldErrors ?? const {},
              onCompanyChanged: (value) {
                setState(() {
                  _markDraftChanged();
                  _companyId = value;
                  _carNameId = null;
                });
              },
              onCarNameChanged: (value) => setState(() {
                _markDraftChanged();
                _carNameId = value;
              }),
              onColorChanged: (value) => setState(() {
                _markDraftChanged();
                _colorId = value;
              }),
              onFuelTypeChanged: (value) => setState(() {
                _markDraftChanged();
                _fuelTypeId = value;
              }),
              onTextChanged: (_) => _markDraftChanged(),
              onRetryCarNames: selectedCompanyId == null
                  ? null
                  : () => ref.invalidate(
                      customerCarNamesProvider(selectedCompanyId),
                    ),
            ),
            const SizedBox(height: OctoGearSpacing.xLarge),
            CustomerCarPhotoPicker(
              photos: _photos,
              enabled: !submission.isSubmitting,
              onAddPhotos:
                  _photos.length < customerCarPhotoLimit &&
                      !submission.isSubmitting
                  ? _pickPhotos
                  : null,
              onRemovePhoto: submission.isSubmitting ? null : _removePhoto,
              errorText: _photoPickerError ?? _pictureFieldError(apiFailure),
            ),
            if (submission.error != null &&
                apiFailure?.fieldErrors.isEmpty != false) ...[
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
                key: const Key('customer_car_retry_submission_button'),
                onPressed: submission.isSubmitting
                    ? null
                    : () => ref
                          .read(createCustomerCarControllerProvider.notifier)
                          .retry(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('customer_garage.add.retry_submission')),
              ),
            ],
            const SizedBox(height: OctoGearSpacing.large),
            FilledButton(
              key: const Key('customer_car_submit_button'),
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
                  : Text(context.tr('customer_garage.add.submit')),
            ),
          ],
        ),
      ),
    );
  }

  String? _pictureFieldError(ApiFailure? failure) {
    if (failure == null) return null;
    final directError = failure.fieldErrors['pictures']?.first;
    if (directError != null) return directError;

    for (final entry in failure.fieldErrors.entries) {
      if (entry.key.startsWith('pictures.') && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }
}

class _CreateCustomerCarHeader extends StatelessWidget {
  const _CreateCustomerCarHeader({required this.onBack});

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
            context.tr('customer_garage.add.title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: OctoGearSpacing.xSmall),
        Text(
          context.tr('customer_garage.add.description'),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: OctoGearColors.structuralGray),
        ),
      ],
    );
  }
}

class _ReferencesLoading extends StatelessWidget {
  const _ReferencesLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.tr('customer_garage.add.references_loading'),
      child: const OctoGearSurfaceCard(
        child: Center(
          child: SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class _ReferencesError extends StatelessWidget {
  const _ReferencesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OctoGearSurfaceCard(
      semanticLabel: context.tr('customer_garage.add.references_error_title'),
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
            context.tr('customer_garage.add.references_error_title'),
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
