import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../storefront/domain/entities/storefront_car_catalog.dart';
import '../../../storefront/presentation/controllers/storefront_car_catalog_providers.dart';
import '../../domain/entities/part_request.dart';
import '../controllers/part_request_providers.dart';
import '../services/part_request_photo_picker.dart';

class RequestPartScreen extends ConsumerStatefulWidget {
  const RequestPartScreen({required this.requestKey, super.key});
  final PartRequestKey requestKey;
  @override
  ConsumerState<RequestPartScreen> createState() => _RequestPartScreenState();
}

class _RequestPartScreenState extends ConsumerState<RequestPartScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  PartRequestPhoto? _photo;
  bool _picking = false;
  bool _photoError = false;
  bool _allowExit = false;
  String _requestId = const Uuid().v4();

  StorefrontCarKey get _carKey =>
      (storeId: widget.requestKey.storeId, carId: widget.requestKey.carId);
  bool get _dirty =>
      _quantity.text != '1' || _notes.text.isNotEmpty || _photo != null;

  @override
  void initState() {
    super.initState();
    unawaited(_pickPhoto(recover: true));
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _changed() {
    _requestId = const Uuid().v4();
    ref
        .read(partRequestControllerProvider(widget.requestKey).notifier)
        .clearError();
    setState(() {});
  }

  Future<void> _pickPhoto({bool recover = false}) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _photoError = false;
    });
    try {
      final picker = ref.read(partRequestPhotoPickerProvider);
      final photo = await (recover ? picker.recover() : picker.pick());
      if (!mounted) return;
      if (photo != null &&
          !ref.read(partRequestControllerProvider(widget.requestKey)).locked) {
        _photo = photo;
        _changed();
      }
    } catch (_) {
      if (mounted) setState(() => _photoError = true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _leave() async {
    final state = ref.read(partRequestControllerProvider(widget.requestKey));
    if (state.submitting || _picking) return;
    if (state.receipt == null && (_dirty || state.retryCommand != null)) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('part_request.leave_title')),
          content: Text(
            dialogContext.tr(
              state.retryCommand != null
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
      if (leave != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        CustomerStoreCarRoute(
          storeId: widget.requestKey.storeId,
          carId: widget.requestKey.carId,
        ).go(context);
      }
    });
  }

  Future<void> _send(StorefrontCarComponent? part) async {
    final current = ref.read(partRequestControllerProvider(widget.requestKey));
    if (current.submitting || current.receipt != null || _picking) return;
    PartRequestCommand? command = current.retryCommand;
    if (command == null) {
      if (part == null || !part.inStock) return;
      if (!(_form.currentState?.validate() ?? false)) {
        final formContext = _form.currentContext;
        if (formContext != null) {
          await Scrollable.ensureVisible(
            formContext,
            duration: const Duration(milliseconds: 250),
          );
        }
        return;
      }
      command = PartRequestCommand(
        componentId: part.id,
        quantity: int.parse(_quantity.text),
        notes: _notes.text.trim(),
        photo: _photo,
        idempotencyKey: _requestId,
      );
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(partRequestControllerProvider(widget.requestKey).notifier)
        .submit(command);
    if (!mounted) return;
    final result = ref.read(partRequestControllerProvider(widget.requestKey));
    if (result.receipt != null) {
      ref.invalidate(storefrontCarComponentsProvider(_carKey));
    } else if (result.error?.fieldErrors.containsKey(
          'store_car_component_id',
        ) ??
        false) {
      ref.invalidate(requestComponentProvider(widget.requestKey));
    }
  }

  String? _fieldError(PartRequestState state, String key) =>
      state.error?.fieldErrors[key]?.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partRequestControllerProvider(widget.requestKey));
    final part = ref.watch(requestComponentProvider(widget.requestKey));
    final details = ref.watch(storefrontCarDetailsProvider(_carKey));
    final disabled = state.locked || _picking;
    final currentPart = part.asData?.value;
    final car = details.asData?.value;
    return PopScope(
      canPop:
          _allowExit ||
          (!state.submitting &&
              !_picking &&
              state.retryCommand == null &&
              (!_dirty || state.receipt != null)),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: state.submitting || _picking ? null : _leave,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
              ),
              Expanded(
                child: Text(
                  context.tr('part_request.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: 20),
          if (state.receipt != null)
            _success(state.receipt!)
          else ...[
            if (currentPart != null && car != null) ...[
              _summary(currentPart, car),
              const SizedBox(height: 16),
              _formFields(currentPart, state, disabled),
            ] else if (part.hasError || details.hasError)
              _loadError(part.error ?? details.error)
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: context.tr('part_request.loading'),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (state.error != null) ...[
              Semantics(
                liveRegion: true,
                child: OctoGearSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: OctoGearColors.error,
                      ),
                      const SizedBox(height: 8),
                      Text(_failureMessage(state), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (currentPart != null && car != null ||
                state.retryCommand != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: OctoGearColors.structuralGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('part_request.no_charge'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('send-part-request'),
                onPressed:
                    state.submitting ||
                        _picking ||
                        state.error?.statusCode == 409 ||
                        (state.retryCommand == null &&
                            !(currentPart?.inStock ?? false))
                    ? null
                    : () => _send(currentPart),
                icon: state.submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  context.tr(
                    state.submitting
                        ? 'part_request.sending'
                        : state.retryCommand != null
                        ? 'part_request.retry'
                        : 'part_request.send',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _summary(StorefrontCarComponent part, StorefrontCarDetails details) {
    final locale = context.locale.toLanguageTag();
    final price = NumberFormat.currency(
      locale: locale,
      symbol: context.tr('storefront.car.sar'),
      decimalDigits: 2,
    ).format(part.priceMinor / part.priceScale);
    return OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OctoGearColors.yellowSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.build_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.component.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (part.section != null)
                      Text(
                        part.section!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${details.car.carName.name} · ${NumberFormat('0', locale).format(details.car.manufacturingYear)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(details.store.name)),
            ],
          ),
          if (part.partNumber != null) ...[
            const SizedBox(height: 12),
            Text(
              context.tr('storefront.car.part_number'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              part.partNumber!,
              textDirection: ui.TextDirection.ltr,
              textAlign: Directionality.of(context) == ui.TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
            ),
          ],
          const Divider(height: 28),
          Text(
            context.tr('part_request.listed_price', args: [price]),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('part_request.price_explanation'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  Widget _formFields(
      StorefrontCarComponent part,
      PartRequestState state,
      bool disabled,
      ) {
    final count = int.tryParse(_quantity.text) ?? 0;

    final priceFormatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: context.tr('storefront.car.sar'),
      decimalDigits: 2,
    );

    final unitPrice = part.priceMinor / part.priceScale;
    final totalPrice = unitPrice * count;

    final unitPriceText = priceFormatter.format(unitPrice);
    final totalPriceText = priceFormatter.format(totalPrice);

    return Form(
      key: _form,
      child: OctoGearSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('part_request.details'),
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 20),

            // Price summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OctoGearColors.yellowSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                         context.tr('part_request.price_per_item'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        unitPriceText,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('part_request.quantity'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '× $count',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        totalPriceText,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              context.tr('part_request.quantity'),
              style: Theme.of(context).textTheme.labelLarge,
            ),

            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  tooltip: context.tr('part_request.decrease'),
                  onPressed: disabled || count <= 1
                      ? null
                      : () {
                    _quantity.text = '${count - 1}';
                    _changed();
                  },
                  icon: const Icon(Icons.remove_rounded),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: TextFormField(
                    key: const ValueKey('request-quantity'),
                    controller: _quantity,
                    enabled: !disabled && part.inStock,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textDirection: ui.TextDirection.ltr,
                    inputFormatters: [
                      TextInputFormatter.withFunction((old, value) {
                        final normalized = value.text.replaceAllMapped(
                          RegExp('[٠-٩۰-۹]'),
                              (match) {
                            final code = match[0]!.codeUnitAt(0);

                            return '${code >= 0x6f0 ? code - 0x6f0 : code - 0x660}';
                          },
                        );

                        return value.copyWith(text: normalized);
                      }),

                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      semanticCounterText:
                      context.tr('part_request.quantity'),
                      errorMaxLines: 3,
                      errorText: _fieldError(state, 'quantity'),
                    ),
                    onChanged: (_) => _changed(),
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');

                      if (quantity == null ||
                          quantity < 1 ||
                          quantity > part.stockQuantity) {
                        return context.tr(
                          'part_request.quantity_error',
                          args: ['${part.stockQuantity}'],
                        );
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 8),

                IconButton.filledTonal(
                  tooltip: context.tr('part_request.increase'),
                  onPressed: disabled || count >= part.stockQuantity
                      ? null
                      : () {
                    _quantity.text = '${count + 1}';
                    _changed();
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              context.tr(
                part.inStock
                    ? 'part_request.available'
                    : 'part_request.out_of_stock',
                args: part.inStock
                    ? [
                  NumberFormat.decimalPattern(
                    context.locale.toLanguageTag(),
                  ).format(part.stockQuantity),
                ]
                    : [],
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 24),

            TextFormField(
              key: const ValueKey('request-notes'),
              controller: _notes,
              enabled: !disabled,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('part_request.notes'),
                hintText: context.tr('part_request.notes_hint'),
                alignLabelWithHint: true,
                errorMaxLines: 3,
                errorText: _fieldError(state, 'notes'),
              ),
              onChanged: (_) => _changed(),
              validator: (value) =>
              (value?.runes.length ?? 0) > 1000
                  ? context.tr('part_request.notes_error')
                  : null,
            ),

            const SizedBox(height: 16),

            Text(
              context.tr('part_request.photo'),
              style: Theme.of(context).textTheme.labelLarge,
            ),

            const SizedBox(height: 6),

            Text(
              context.tr('part_request.photo_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),

            if (_photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photo!.bytes,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel:
                  context.tr('part_request.photo_preview'),
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 100,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],

            OutlinedButton.icon(
              onPressed: disabled ? null : () => _pickPhoto(),
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
              ),
              label: Text(
                context.tr(
                  _picking
                      ? 'part_request.photo_loading'
                      : _photo == null
                      ? 'part_request.add_photo'
                      : 'part_request.replace_photo',
                ),
              ),
            ),

            if (_photo != null)
              TextButton(
                onPressed: disabled
                    ? null
                    : () {
                  _photo = null;
                  _photoError = false;
                  _changed();
                },
                child: Text(
                  context.tr('part_request.remove_photo'),
                ),
              ),

            if (_photoError ||
                _fieldError(state, 'customer_image') != null)
              Text(
                _fieldError(state, 'customer_image') ??
                    context.tr('part_request.photo_error'),
                style: const TextStyle(
                  color: OctoGearColors.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _failureMessage(PartRequestState state) {
    if (state.error?.statusCode == 409) {
      return context.tr('part_request.conflict');
    }
    if (state.retryCommand != null) return context.tr('part_request.uncertain');
    final componentError = _fieldError(state, 'store_car_component_id');
    if (componentError != null) return componentError;
    return context.tr(switch (state.error?.type) {
      ApiFailureType.validation => 'part_request.validation_error',
      ApiFailureType.rateLimited => 'part_request.rate_limit',
      ApiFailureType.unauthorized ||
      ApiFailureType.forbidden => 'part_request.access_error',
      ApiFailureType.notFound => 'part_request.unavailable',
      _ => 'part_request.send_error',
    });
  }

  Widget _loadError(Object? error) => OctoGearSurfaceCard(
    child: Column(
      children: [
        const Icon(Icons.inventory_2_outlined, size: 40),
        const SizedBox(height: 12),
        Text(
          context.tr(
            error is ApiFailure && error.type == ApiFailureType.notFound
                ? 'part_request.unavailable'
                : 'part_request.load_error',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            ref.invalidate(requestComponentProvider(widget.requestKey));
            ref.invalidate(storefrontCarDetailsProvider(_carKey));
          },
          child: Text(context.tr('common.retry')),
        ),
      ],
    ),
  );

  Widget _success(PartRequestReceipt receipt) => Semantics(
    liveRegion: true,
    child: OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: OctoGearColors.success,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('part_request.success_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('part_request.success_message'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('part_request.reference', args: ['${receipt.id}']),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _leave,
            child: Text(context.tr('part_request.done')),
          ),
        ],
      ),
    ),
  );
}
