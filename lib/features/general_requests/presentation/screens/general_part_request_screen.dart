import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../customer_garage/domain/entities/customer_car.dart';
import '../../../customer_garage/presentation/controllers/customer_car_form_references_controller.dart';
import '../../../customer_garage/presentation/controllers/customer_car_names_controller.dart';
import '../../../customer_garage/presentation/controllers/customer_cars_controller.dart';
import '../../../customer_orders/presentation/controllers/customer_orders_providers.dart';
import '../../../part_requests/domain/entities/part_request.dart';
import '../../../part_requests/presentation/services/part_request_photo_picker.dart';
import '../../domain/entities/general_request.dart';
import '../controllers/general_request_providers.dart';
import '../widgets/general_request_flow_layout.dart';
import '../widgets/general_request_part_step.dart';
import '../widgets/general_request_review_step.dart';
import '../widgets/general_request_success.dart';
import '../widgets/general_request_vehicle_step.dart';
import '../widgets/request_component_picker.dart';

/// One route owns the draft; only the current step is visible.
class GeneralPartRequestScreen extends ConsumerStatefulWidget {
  const GeneralPartRequestScreen({super.key});
  @override
  ConsumerState<GeneralPartRequestScreen> createState() =>
      _GeneralPartRequestScreenState();
}

class _GeneralPartRequestScreenState
    extends ConsumerState<GeneralPartRequestScreen> {
  final _draftId = const Uuid().v4();
  String _requestId = const Uuid().v4();
  final _vehicleForm = GlobalKey<FormState>();
  final _partForm = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _year = TextEditingController();
  final _customName = TextEditingController();
  final _description = TextEditingController();
  final _photos = <PartRequestPhoto>[];
  int _step = 0;
  bool _manualVehicle = false, _customPart = false, _saveToGarage = false;
  bool _dirty = false, _picking = false, _photoError = false;
  bool _allowExit = false, _exitDialog = false;
  bool _vehicleError = false, _partError = false, _transmissionError = false;
  CustomerCar? _savedCar;
  int? _companyId, _carNameId, _colorId, _fuelTypeId;
  String? _transmission;
  RequestComponent? _component;

  GeneralRequestState get _state =>
      ref.read(generalRequestControllerProvider(_draftId));
  @override
  void initState() {
    super.initState();
    unawaited(_pickPhoto(recover: true));
  }

  @override
  void dispose() {
    _year.dispose();
    _customName.dispose();
    _description.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    _dirty = true;
    _requestId = const Uuid().v4();
    ref.read(generalRequestControllerProvider(_draftId).notifier).clearError();
    setState(() {
      _vehicleError = false;
      _partError = false;
      _transmissionError = false;
    });
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _back() async {
    if (_state.submitting || _picking) return;
    if (_step > 0 && !_state.locked) {
      _goTo(_step - 1);
      return;
    }
    await _leave();
  }

  Future<void> _leave() async {
    if (_state.submitting || _picking || _exitDialog) return;
    if (_dirty && _state.orderId == null) {
      _exitDialog = true;
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('part_request.leave_title')),
          content: Text(
            dialogContext.tr(
              _state.retryCommand != null
                  ? 'part_request.leave_uncertain'
                  : 'part_request.leave_draft',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('part_request.stay')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('part_request.leave')),
            ),
          ],
        ),
      );
      _exitDialog = false;
      if (leave != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        const CustomerHomeRoute().go(context);
      }
    });
  }

  Future<void> _pickPhoto({bool recover = false}) async {
    if (_picking || _photos.length >= 5 || _state.locked) return;
    setState(() {
      _picking = true;
      _photoError = false;
    });
    try {
      final picker = ref.read(partRequestPhotoPickerProvider);
      final photo = await (recover ? picker.recover() : picker.pick());
      if (!mounted) return;
      if (photo != null && !_state.locked) {
        _photos.add(photo);
        _changed();
      }
    } catch (_) {
      if (mounted) setState(() => _photoError = true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _choosePart() async {
    final part = await showModalBottomSheet<RequestComponent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const RequestComponentPicker(),
    );
    if (part != null && mounted) {
      _component = part;
      _changed();
    }
  }

  void _next() {
    if (_state.locked || _picking) return;
    if (_step == 0) {
      if (_manualVehicle) {
        final valid = _vehicleForm.currentState?.validate() ?? false;
        final names = _companyId == null
            ? null
            : ref.read(customerCarNamesProvider(_companyId!)).asData?.value;
        final available = names?.any((item) => item.id == _carNameId) ?? false;
        setState(() {
          _transmissionError = _transmission == null;
          _vehicleError = !available;
        });
        if (!valid || !available || _transmission == null) return;
      } else if (_savedCar == null) {
        setState(() => _vehicleError = true);
        return;
      }
    } else if (_step == 1) {
      final valid = _partForm.currentState?.validate() ?? false;
      setState(() => _partError = !_customPart && _component == null);
      if (!valid || _partError) return;
    }
    _goTo(_step + 1);
  }

  Future<void> _submit() async {
    if (_state.submitting || _state.orderId != null || _picking) return;
    final command =
        _state.retryCommand ??
        GeneralRequestCommand(
          vehicle: _manualVehicle
              ? NewRequestVehicle(
                  carNameId: _carNameId!,
                  year: int.parse(_year.text),
                  transmission: _transmission!,
                  colorId: _colorId!,
                  fuelTypeId: _fuelTypeId!,
                  saveToGarage: _saveToGarage,
                )
              : SavedRequestVehicle(_savedCar!.id),
          componentId: _customPart ? null : _component!.id,
          componentName: _customPart ? _customName.text.trim() : null,
          description: _description.text.trim(),
          photos: _photos,
          idempotencyKey: _requestId,
        );
    await ref
        .read(generalRequestControllerProvider(_draftId).notifier)
        .submit(command);
    if (!mounted) return;
    if (_state.orderId != null) {
      ref.invalidate(customerOrdersProvider);
      if (command.vehicle case NewRequestVehicle(saveToGarage: true)) {
        ref.invalidate(customerCarsControllerProvider);
      }
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generalRequestControllerProvider(_draftId));
    // Keep localized references alive while moving between steps.
    final cars = ref.watch(customerCarsControllerProvider);
    final references = _manualVehicle
        ? ref.watch(customerCarFormReferencesControllerProvider)
        : null;
    final names = _companyId == null
        ? null
        : ref.watch(customerCarNamesProvider(_companyId!));
    final localizedPart = _component == null
        ? null
        : ref
              .watch(localizedRequestComponentProvider(_component!))
              .asData
              ?.value;
    final partName = _customPart
        ? _customName.text.trim()
        : localizedPart?.name ?? _component?.name ?? '';
    final saved =
        cars.asData?.value
            .where((car) => car.id == _savedCar?.id)
            .firstOrNull ??
        _savedCar;
    final disabled = state.locked || _picking;
    return PopScope(
      canPop:
          _allowExit ||
          (!_dirty && _step == 0 && !state.submitting && !_picking),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: GeneralRequestFlowLayout(
        state: state,
        step: _step,
        picking: _picking,
        scrollController: _scroll,
        onBack: _back,
        onNext: _next,
        onSubmit: _submit,
        onCancel: _leave,
        content: state.orderId != null
            ? GeneralRequestSuccess(
                orderId: state.orderId!,
                onDone: _leave,
                onViewRequest: () => CustomerOrderDetailsRoute(
                  orderId: state.orderId!,
                ).go(context),
              )
            : switch (_step) {
                0 => GeneralRequestVehicleStep(
                  cars: cars,
                  references: references,
                  names: names,
                  formKey: _vehicleForm,
                  manualVehicle: _manualVehicle,
                  savedCarId: _savedCar?.id,
                  companyId: _companyId,
                  carNameId: _carNameId,
                  colorId: _colorId,
                  fuelTypeId: _fuelTypeId,
                  yearController: _year,
                  transmission: _transmission,
                  saveToGarage: _saveToGarage,
                  disabled: disabled,
                  vehicleError: _vehicleError,
                  transmissionError: _transmissionError,
                  onVehicleModeChanged: (value) {
                    _manualVehicle = value;
                    _changed();
                  },
                  onSavedCarChanged: (car) {
                    _savedCar = car;
                    _changed();
                  },
                  onCompanyChanged: (id) {
                    _companyId = id;
                    _carNameId = null;
                    _changed();
                  },
                  onCarNameChanged: (id) {
                    _carNameId = id;
                    _changed();
                  },
                  onColorChanged: (id) {
                    _colorId = id;
                    _changed();
                  },
                  onFuelTypeChanged: (id) {
                    _fuelTypeId = id;
                    _changed();
                  },
                  onTransmissionChanged: (value) {
                    _transmission = value;
                    _changed();
                  },
                  onSaveToGarageChanged: (value) {
                    _saveToGarage = value;
                    _changed();
                  },
                  onChanged: _changed,
                  onRetryCars: () =>
                      ref.invalidate(customerCarsControllerProvider),
                  onRetryReferences: () => ref.invalidate(
                    customerCarFormReferencesControllerProvider,
                  ),
                  onRetryNames: () =>
                      ref.invalidate(customerCarNamesProvider(_companyId!)),
                ),
                1 => GeneralRequestPartStep(
                  formKey: _partForm,
                  partName: partName,
                  customPart: _customPart,
                  disabled: disabled,
                  partError: _partError,
                  picking: _picking,
                  photoError: _photoError,
                  nameController: _customName,
                  descriptionController: _description,
                  photos: _photos,
                  onPartModeChanged: (value) {
                    _customPart = value;
                    _changed();
                  },
                  onChoosePart: _choosePart,
                  onChanged: _changed,
                  onAddPhoto: _pickPhoto,
                  onRemovePhoto: (index) {
                    _photos.removeAt(index);
                    _changed();
                  },
                ),
                _ => GeneralRequestReviewStep(
                  saved: saved,
                  refs: references?.asData?.value,
                  names: names?.asData?.value,
                  partName: partName,
                  disabled: disabled,
                  manualVehicle: _manualVehicle,
                  companyId: _companyId,
                  carNameId: _carNameId,
                  colorId: _colorId,
                  fuelTypeId: _fuelTypeId,
                  year: _year.text,
                  transmission: _transmission,
                  saveToGarage: _saveToGarage,
                  description: _description.text,
                  photos: _photos,
                  onEditStep: _goTo,
                ),
              },
      ),
    );
  }
}
