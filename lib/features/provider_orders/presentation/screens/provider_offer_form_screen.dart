import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/media/image_upload_policy.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../general_requests/presentation/widgets/general_request_photos.dart';
import '../../../part_requests/domain/entities/part_request.dart';
import '../../../part_requests/presentation/services/part_request_photo_picker.dart';
import '../../../provider_stores/domain/entities/provider_store.dart';
import '../../../provider_stores/presentation/controllers/provider_stores_providers.dart';
import '../../domain/entities/provider_offer.dart';
import '../controllers/provider_general_requests_providers.dart';
import '../controllers/provider_offers_providers.dart';
import '../widgets/provider_offer_widgets.dart';

class ProviderOfferFormScreen extends ConsumerWidget {
  const ProviderOfferFormScreen({
    required this.orderId,
    this.offerId,
    super.key,
  });
  final int orderId;
  final int? offerId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (offerId != null) {
      return ref
          .watch(providerOfferProvider(offerId!))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _FormError(
              error: error,
              retry: () => ref.invalidate(providerOfferProvider(offerId!)),
            ),
            data: (offer) => offer.canEdit && offer.orderId == orderId
                ? _OfferEditor(orderId: orderId, offer: offer, stores: const [])
                : _FormError(
                    error: const ApiFailure(type: ApiFailureType.forbidden),
                    retry: () =>
                        ref.invalidate(providerOfferProvider(offerId!)),
                  ),
          );
    }
    final request = ref.watch(providerGeneralRequestProvider(orderId));
    final stores = ref.watch(providerStoresProvider);
    if (request.hasError || stores.hasError) {
      return _FormError(
        error: request.error ?? stores.error!,
        retry: () {
          ref.invalidate(providerGeneralRequestProvider(orderId));
          ref.invalidate(providerStoresProvider);
        },
      );
    }
    if (request.isLoading ||
        stores.isLoading ||
        !request.hasValue ||
        !stores.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final item = request.requireValue;
    final eligible = stores.requireValue
        .where(
          (store) =>
              store.status == ProviderStoreStatus.active &&
              !item.ownOffers.any((offer) => offer.storeId == store.id),
        )
        .toList();
    if (item.status != 'pending' || eligible.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: BackButton(),
          ),
          Text(context.tr('provider_offers.no_store')),
        ],
      );
    }
    return _OfferEditor(orderId: orderId, stores: eligible);
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: BackButton(),
      ),
      ProviderOfferError(error: error, retry: retry),
    ],
  );
}

class _OfferEditor extends ConsumerStatefulWidget {
  const _OfferEditor({required this.orderId, required this.stores, this.offer});
  final int orderId;
  final List<ProviderStore> stores;
  final ProviderOffer? offer;
  @override
  ConsumerState<_OfferEditor> createState() => _OfferEditorState();
}

class _OfferEditorState extends ConsumerState<_OfferEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _price;
  late final TextEditingController _notes;
  int? _storeId;
  List<PartRequestPhoto>? _photos;
  bool _dirty = false, _allowPop = false, _picking = false;
  String? _photoError;
  ProviderOfferActionKey get _key =>
      (orderId: widget.orderId, offerId: widget.offer?.id);
  @override
  void initState() {
    super.initState();
    final price = widget.offer?.price;
    _price = TextEditingController(
      text: price == null
          ? ''
          : '${price ~/ 100}.${(price % 100).toString().padLeft(2, '0')}',
    );
    _notes = TextEditingController(text: widget.offer?.notes ?? '');
  }

  @override
  void dispose() {
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (ref.read(providerOfferActionsProvider(_key)).busy || _picking) return;
    var leave = !_dirty;
    if (!leave) {
      leave =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.tr('provider_offers.discard')),
              content: Text(context.tr('provider_offers.discard_body')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('common.cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.tr('provider_offers.leave')),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!leave || !mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pick() async {
    if (_picking || (_photos?.length ?? 0) >= ImageUploadPolicy.maxFiles) {
      return;
    }
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final photo = await ref.read(partRequestPhotoPickerProvider).pick();
      if (mounted && photo != null) {
        setState(() {
          _photos = [...?_photos, photo];
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError = context.tr('provider_offers.photo_invalid'),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit(int storeId, String storeName) async {
    if (!_form.currentState!.validate()) return;
    final command = ProviderOfferCommand(
      orderId: widget.orderId,
      offerId: widget.offer?.id,
      storeId: storeId,
      price: providerOfferPrice(_price.text)!,
      notes: _notes.text.trim(),
      photos: _photos,
    );
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('provider_offers.review')),
        content: Text('$storeName\n${offerMoney(context, command.price)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('provider_offers.confirm')),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    final offer = await ref
        .read(providerOfferActionsProvider(_key).notifier)
        .save(command);
    if (offer != null && mounted) await _open(offer);
  }

  Future<void> _open(ProviderOffer offer) async {
    setState(() {
      _dirty = false;
      _allowPop = true;
    });
    if (widget.offer == null) {
      ProviderOfferRoute(offerId: offer.id).pushReplacement(context);
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(providerOfferActionsProvider(_key));
    final locked = action.busy || action.uncertain || _picking;
    final selected =
        widget.offer?.storeId ??
        (_storeId != null && widget.stores.any((s) => s.id == _storeId)
            ? _storeId
            : widget.stores.length == 1
            ? widget.stores.single.id
            : null);
    final name =
        widget.offer?.storeName ??
        widget.stores.where((s) => s.id == selected).firstOrNull?.name;
    final errors = action.error is ApiFailure
        ? (action.error as ApiFailure).fieldErrors
        : <String, List<String>>{};
    return PopScope(
      canPop: _allowPop || (!_dirty && !locked),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              BackButton(onPressed: _leave),
              Expanded(
                child: Text(
                  context.tr(
                    widget.offer == null
                        ? 'provider_offers.create'
                        : 'provider_offers.edit',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.tr('provider_offers.form_intro')),
          const SizedBox(height: 20),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.offer != null)
                  Text(name!)
                else
                  DropdownButtonFormField<int>(
                    key: ValueKey(selected),
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('provider_offers.store'),
                      errorText: errors['store_id']?.firstOrNull,
                    ),
                    items: [
                      for (final store in widget.stores)
                        DropdownMenuItem(
                          value: store.id,
                          child: Text(
                            store.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: locked
                        ? null
                        : (value) => setState(() {
                            _storeId = value;
                            _dirty = true;
                          }),
                    validator: (value) => value == null
                        ? context.tr('provider_offers.choose_store')
                        : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('provider-offer-price'),
                  controller: _price,
                  enabled: !locked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('provider_offers.price'),
                    errorText: errors['price']?.firstOrNull,
                  ),
                  validator: (text) => providerOfferPrice(text ?? '') == null
                      ? context.tr('provider_offers.price_invalid')
                      : null,
                  onChanged: (_) => setState(() => _dirty = true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('provider-offer-notes'),
                  controller: _notes,
                  enabled: !locked,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: context.tr('provider_offers.notes'),
                    errorText: errors['notes']?.firstOrNull,
                  ),
                  onChanged: (_) => setState(() => _dirty = true),
                ),
                const SizedBox(height: 16),
                Text(context.tr('provider_offers.photos_hint')),
                if (_photos == null &&
                    (widget.offer?.imagePaths.isNotEmpty ?? false)) ...[
                  Text(
                    context.tr(
                      'provider_offers.keep_photos',
                      args: ['${widget.offer!.imagePaths.length}'],
                    ),
                  ),
                  TextButton(
                    onPressed: locked
                        ? null
                        : () => setState(() {
                            _photos = [];
                            _dirty = true;
                          }),
                    child: Text(context.tr('provider_offers.clear_photos')),
                  ),
                ],
                GeneralRequestPhotos(
                  photos: _photos ?? const [],
                  onRemove: locked
                      ? null
                      : (index) => setState(() {
                          _photos!.removeAt(index);
                          _dirty = true;
                        }),
                ),
                OutlinedButton.icon(
                  onPressed:
                      locked ||
                          (_photos?.length ?? 0) >= ImageUploadPolicy.maxFiles
                      ? null
                      : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    context.tr(
                      _photos == null &&
                              (widget.offer?.imagePaths.isNotEmpty ?? false)
                          ? 'provider_offers.replace_photos'
                          : 'provider_offers.add_photo',
                    ),
                  ),
                ),
                if (_photoError != null) Text(_photoError!),
                for (final entry in errors.entries)
                  if (entry.key.startsWith('images'))
                    Text(entry.value.join('\n')),
                if (action.error != null && !action.uncertain)
                  Text(offerFailure(context, action.error!)),
                if (action.uncertain) ...[
                  Text(context.tr('provider_offers.uncertain')),
                  OutlinedButton(
                    onPressed: action.busy
                        ? null
                        : () async {
                            final offer = await ref
                                .read(
                                  providerOfferActionsProvider(_key).notifier,
                                )
                                .check();
                            if (offer != null && mounted) await _open(offer);
                          },
                    child: Text(context.tr('provider_offers.check')),
                  ),
                ],
                if (action.busy || _picking) const LinearProgressIndicator(),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('provider-offer-submit'),
                  onPressed: locked
                      ? null
                      : () {
                          if (_form.currentState!.validate() &&
                              selected != null) {
                            _submit(selected, name!);
                          }
                        },
                  child: Text(
                    context.tr(
                      widget.offer == null
                          ? 'provider_offers.submit'
                          : 'provider_offers.save',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
