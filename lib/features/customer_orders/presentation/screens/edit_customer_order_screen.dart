import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../general_requests/domain/entities/general_request.dart';
import '../../../general_requests/presentation/widgets/request_component_picker.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/order_changes.dart';
import '../controllers/customer_orders_providers.dart';
import '../controllers/order_management_controller.dart';
import '../widgets/order_management_actions.dart';
import '../widgets/order_widgets.dart';
import 'edit_order_vehicle_screen.dart';

class EditCustomerOrderScreen extends ConsumerWidget {
  const EditCustomerOrderScreen({required this.orderId, super.key});
  final int orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(customerOrderProvider(orderId))
      .when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: OrdersFeedback(
            title: context.tr('orders.error_title'),
            message: ordersErrorMessage(context, error),
            icon: Icons.cloud_off_outlined,
            action: context.tr('common.retry'),
            onAction: () => ref.invalidate(customerOrderProvider(orderId)),
          ),
        ),
        data: (order) =>
            _OrderEditForm(key: ValueKey(order.editToken), order: order),
      );
}

class _OrderEditForm extends ConsumerStatefulWidget {
  const _OrderEditForm({required this.order, super.key});
  final CustomerOrder order;
  @override
  ConsumerState<_OrderEditForm> createState() => _OrderEditFormState();
}

class _OrderEditFormState extends ConsumerState<_OrderEditForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _notes, _quantity;
  late bool _custom;
  RequestComponent? _component;
  OrderVehicleEdit? _vehicle;
  bool _partChanged = false,
      _dirty = false,
      _leaving = false,
      _allowExit = false;
  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _custom = order.componentId == null;
    _name = TextEditingController(text: _custom ? order.partName : '');
    _notes = TextEditingController(text: order.notes);
    _quantity = TextEditingController(text: '${order.quantity ?? 1}');
    if (order.componentId != null) {
      _component = RequestComponent(
        id: order.componentId!,
        name: order.partName ?? '',
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _dirty = true);

  Future<void> _back() async {
    if (_leaving || ref.read(orderManagementProvider(widget.order.id)).busy) {
      return;
    }
    _leaving = true;
    if (_dirty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('order_management.discard_title')),
          content: Text(dialogContext.tr('order_management.discard_hint')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('order_management.keep_editing')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('order_management.discard')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (leave != true) {
        _leaving = false;
        return;
      }
    }
    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        CustomerOrderDetailsRoute(orderId: widget.order.id).go(context);
      }
    });
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final order = widget.order;
    final changes = OrderChanges(
      description: order.isGeneral ? _notes.text.trim() : null,
      notes: order.isGeneral ? null : _notes.text.trim(),
      quantity: order.isGeneral ? null : int.parse(_quantity.text),
      vehicle: _vehicle?.values,
      componentName: _partChanged && _custom ? _name.text.trim() : null,
      componentId: _partChanged && !_custom ? _component!.id : null,
    );
    final success = await ref
        .read(orderManagementProvider(order.id).notifier)
        .submit(order, changes: changes);
    if (success && mounted) {
      setState(() {
        _dirty = false;
        _allowExit = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('order_management.saved'))),
      );
      CustomerOrderDetailsRoute(orderId: order.id).go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final state = ref.watch(orderManagementProvider(order.id));
    final enabled = order.canEdit && !state.busy && !state.needsRefresh;
    String tr(String key) => context.tr('order_management.$key');
    return PopScope(
      canPop: _allowExit || (!_dirty && !state.busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: state.busy ? null : _back,
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('edit_title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!order.canEdit) ...[
            Text(tr('unavailable')),
            TextButton(onPressed: _back, child: Text(tr('back'))),
          ] else ...[
            Text(
              tr('edit_hint'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (order.isGeneral) ...[
                    OctoGearSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('general_request.vehicle'),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _vehicle?.label ?? orderCar(order),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: enabled
                                ? () async {
                                    final result = await Navigator.of(context)
                                        .push<OrderVehicleEdit>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                EditOrderVehicleScreen(
                                                  order: order,
                                                  draft: _vehicle,
                                                ),
                                          ),
                                        );
                                    if (result != null && mounted) {
                                      setState(() {
                                        _vehicle = result;
                                        _dirty = true;
                                      });
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(tr('change_vehicle')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('part'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final custom in [false, true])
                          ChoiceChip(
                            selected: _custom == custom,
                            label: Text(
                              tr(custom ? 'custom_part' : 'catalog_part'),
                            ),
                            onSelected: enabled
                                ? (_) => setState(() {
                                    _custom = custom;
                                    _partChanged = true;
                                    _dirty = true;
                                  })
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_custom)
                      TextFormField(
                        key: const Key('order-edit-part'),
                        controller: _name,
                        enabled: enabled,
                        maxLength: 255,
                        decoration: InputDecoration(labelText: tr('part')),
                        onChanged: (_) {
                          _partChanged = true;
                          _changed();
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? tr('part_required')
                            : null,
                      )
                    else
                      FormField<RequestComponent>(
                        validator: (_) =>
                            _component == null ? tr('part_required') : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: enabled
                                  ? () async {
                                      final part =
                                          await showModalBottomSheet<
                                            RequestComponent
                                          >(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            showDragHandle: true,
                                            builder: (_) =>
                                                const RequestComponentPicker(),
                                          );
                                      if (part != null && mounted) {
                                        setState(() {
                                          _component = part;
                                          _partChanged = true;
                                          _dirty = true;
                                          field.didChange(part);
                                        });
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.search),
                              label: Text(
                                _component?.name ?? tr('choose_part'),
                              ),
                            ),
                            if (field.hasError)
                              Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ] else ...[
                    Text(
                      orderTitle(context, order),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('order-edit-quantity'),
                      controller: _quantity,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      decoration: InputDecoration(labelText: tr('quantity')),
                      onChanged: (_) => _changed(),
                      validator: (value) {
                        final quantity = int.tryParse(value ?? '');
                        return quantity == null ||
                                quantity < 1 ||
                                quantity > 2147483647
                            ? tr('quantity_invalid')
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('order-edit-notes'),
                    controller: _notes,
                    enabled: enabled,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: tr('notes'),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => _changed(),
                  ),
                  if (order.imagePaths.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        tr('photos_retained'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            OrderManagementFeedback(
              state: state,
              onRefresh: () async {
                await ref
                    .read(orderManagementProvider(order.id).notifier)
                    .refresh();
                if (context.mounted &&
                    ref.read(orderManagementProvider(order.id)).deleted) {
                  const CustomerOrdersRoute().go(context);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('order-save'),
              onPressed: enabled && _dirty ? _save : null,
              icon: state.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(tr('save')),
            ),
            TextButton(
              onPressed: state.busy ? null : _back,
              child: Text(tr('cancel')),
            ),
          ],
        ],
      ),
    );
  }
}
