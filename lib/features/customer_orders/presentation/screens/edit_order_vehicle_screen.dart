import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customer_garage/presentation/controllers/customer_car_form_references_controller.dart';
import '../../../customer_garage/presentation/controllers/customer_car_names_controller.dart';
import '../../../customer_garage/presentation/widgets/customer_car_editor_fields.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/order_changes.dart';
import '../widgets/order_widgets.dart';

class OrderVehicleEdit {
  const OrderVehicleEdit(this.values, this.label, this.companyId);
  final OrderVehicleChanges values;
  final String label;
  final int companyId;
}

/// An isolated draft: Back discards this step without changing the request or garage.
class EditOrderVehicleScreen extends ConsumerStatefulWidget {
  const EditOrderVehicleScreen({required this.order, this.draft, super.key});
  final CustomerOrder order;
  final OrderVehicleEdit? draft;
  @override
  ConsumerState<EditOrderVehicleScreen> createState() =>
      _EditOrderVehicleState();
}

class _EditOrderVehicleState extends ConsumerState<EditOrderVehicleScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _year;
  int? _company, _car, _color, _fuel;
  String? _transmission;
  @override
  void initState() {
    super.initState();
    final draft = widget.draft?.values;
    final order = widget.order;
    _company = widget.draft?.companyId ?? order.vehicleIds.companyId;
    _car = draft?.carNameId ?? order.vehicleIds.carNameId;
    _color = draft?.colorId ?? order.vehicleIds.colorId;
    _fuel = draft?.fuelTypeId ?? order.vehicleIds.fuelTypeId;
    _transmission = draft?.transmission ?? order.transmissionType;
    _year = TextEditingController(
      text: (draft?.year ?? order.manufacturingYear)?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final references = ref.watch(customerCarFormReferencesControllerProvider);
    final names = _company == null
        ? null
        : ref.watch(customerCarNamesProvider(_company!));
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('order_management.vehicle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(context.tr('order_management.vehicle_hint')),
            const SizedBox(height: 20),
            ...references.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (error, _) => [
                OrdersFeedback(
                  title: context.tr('orders.error_title'),
                  message: ordersErrorMessage(context, error),
                  icon: Icons.cloud_off_outlined,
                  action: context.tr('common.retry'),
                  onAction: () => ref.invalidate(
                    customerCarFormReferencesControllerProvider,
                  ),
                ),
              ],
              data: (refs) => [
                Form(
                  key: _form,
                  child: CustomerCarEditorFields(
                    references: refs,
                    carNames: names,
                    companyId: refs.companies.any((item) => item.id == _company)
                        ? _company
                        : null,
                    carNameId: _car,
                    colorId: refs.colors.any((item) => item.id == _color)
                        ? _color
                        : null,
                    fuelTypeId: refs.fuelTypes.any((item) => item.id == _fuel)
                        ? _fuel
                        : null,
                    yearController: _year,
                    transmissionType: _transmission,
                    onTransmissionChanged: (value) =>
                        setState(() => _transmission = value),
                    enabled: true,
                    fieldErrors: const {},
                    transmissionRequired: true,
                    onCompanyChanged: (value) => setState(() {
                      _company = value;
                      _car = null;
                    }),
                    onCarNameChanged: (value) => setState(() => _car = value),
                    onColorChanged: (value) => setState(() => _color = value),
                    onFuelTypeChanged: (value) => setState(() => _fuel = value),
                    onTextChanged: (_) {},
                    onRetryCarNames: () =>
                        ref.invalidate(customerCarNamesProvider(_company!)),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    final selected = names?.asData?.value
                        .where((item) => item.id == _car)
                        .firstOrNull;
                    if (selected == null) return;
                    Navigator.pop(
                      context,
                      OrderVehicleEdit(
                        OrderVehicleChanges(
                          carNameId: _car!,
                          year: int.parse(_year.text),
                          transmission: _transmission!,
                          colorId: _color!,
                          fuelTypeId: _fuel!,
                        ),
                        '${selected.name} · ${_year.text}',
                        _company!,
                      ),
                    );
                  },
                  child: Text(context.tr('order_management.use_vehicle')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
