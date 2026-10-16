import 'dart:async';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/saudi_mobile_number.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../authentication/presentation/widgets/authentication_failure_text.dart';
import '../../../authentication/presentation/widgets/registration_city_field.dart';
import '../../../provider_portal/presentation/widgets/provider_page.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';
import '../../../seller_registration/presentation/services/registration_document_picker.dart';
import '../../../seller_registration/presentation/widgets/seller_company_field.dart';
import '../../domain/entities/provider_store_management.dart';
import '../controllers/provider_store_management_providers.dart';
import '../widgets/store_management_widgets.dart';

class ProviderStoreFormScreen extends ConsumerWidget {
  const ProviderStoreFormScreen({this.storeId, this.requestId, super.key})
    : assert(storeId == null || requestId == null);
  final int? storeId, requestId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession ||
        session.user.role != AppUserRole.provider) {
      return const SizedBox.shrink();
    }
    Widget form({
      ProviderStoreDetails? store,
      SellerApplication? application,
    }) => _StoreForm(
      key: ValueKey((session, store?.editVersion, application?.id)),
      session: session,
      store: store,
      application: application,
    );
    Widget loading() => const ProviderPage(
      titleKey: 'store_management.edit',
      showBack: true,
      children: [Center(child: CircularProgressIndicator())],
    );
    Widget error(Object error, VoidCallback retry) => ProviderPage(
      titleKey: 'store_management.edit',
      showBack: true,
      children: [StoreLoadFailure(error: error, onRetry: retry)],
    );
    if (storeId != null) {
      return ref
          .watch(providerStoreDetailsProvider(storeId!))
          .when(
            data: (store) => store.pendingChangeRequestId == null
                ? form(store: store)
                : ProviderPage(
                    titleKey: 'store_management.edit',
                    showBack: true,
                    children: [
                      StorePendingChangeNotice(
                        requestId: store.pendingChangeRequestId!,
                      ),
                    ],
                  ),
            loading: loading,
            error: (e, _) => error(
              e,
              () => ref.invalidate(providerStoreDetailsProvider(storeId!)),
            ),
          );
    }
    if (requestId != null) {
      return ref
          .watch(providerStoreApplicationProvider(requestId!))
          .when(
            data: (application) =>
                application.status == SellerApplicationStatus.rejected &&
                    !application.isStoreChange
                ? form(application: application)
                : ProviderPage(
                    titleKey: 'store_management.application',
                    showBack: true,
                    children: [
                      StoreApplicationBadge(status: application.status),
                      const SizedBox(height: 16),
                      Text(
                        context.tr(
                          'store_management.${application.status.name}_hint',
                        ),
                      ),
                    ],
                  ),
            loading: loading,
            error: (e, _) => error(
              e,
              () =>
                  ref.invalidate(providerStoreApplicationProvider(requestId!)),
            ),
          );
    }
    return form();
  }
}

class _StoreForm extends ConsumerStatefulWidget {
  const _StoreForm({
    required this.session,
    this.store,
    this.application,
    super.key,
  });
  final AuthenticatedSession session;
  final ProviderStoreDetails? store;
  final SellerApplication? application;
  @override
  ConsumerState<_StoreForm> createState() => _StoreFormState();
}

class _StoreFormState extends ConsumerState<_StoreForm> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final Map<String, TextEditingController> _text;
  late final String _requestKey = const Uuid().v4();
  late Set<int> _companies;
  late List<ProviderStorePicture> _retained;
  final _photos = <RegistrationDocument>[];
  AppCity? _city;
  RegistrationDocument? _document;
  bool _dirty = false, _allowExit = false, _leaving = false, _picking = false;
  String? _imageError;
  String get _formId =>
      'provider-${widget.session.user.id}:${widget.store?.store.id ?? 0}:${widget.application?.id ?? 0}';
  ProviderStoreWriteController get _controller =>
      ref.read(providerStoreWriteProvider(_formId).notifier);
  String get _title => widget.store != null
      ? 'edit'
      : widget.application != null
      ? 'correct'
      : 'add';
  String? get _existingDocument =>
      widget.store?.documentPath ??
      (widget.application?.hasDocument == true
          ? '/api/media/store-requests/${widget.application!.id}/registration'
          : null);
  bool get _sameSession =>
      mounted &&
      identical(
        ref.read(sessionControllerProvider).asData?.value,
        widget.session,
      );

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    final a = widget.application;
    _text = {
      'change_reason': TextEditingController(),
      'name': TextEditingController(text: s?.store.name ?? a?.name),
      'nick_name': TextEditingController(text: s?.nickname ?? a?.nickname),
      'employee_name': TextEditingController(
        text: s?.employeeName ?? a?.employeeName,
      ),
      'mobile': TextEditingController(text: s?.store.mobile ?? a?.mobile),
      'url_location': TextEditingController(
        text: s?.store.location ?? a?.location,
      ),
      'commercial_registration_number': TextEditingController(
        text: s?.registrationNumber ?? a?.registrationNumber,
      ),
    };
    _city = s?.city ?? a?.city ?? widget.session.user.city;
    _companies = {...?s?.companyIds, ...?a?.companyIds};
    _retained = [...?s?.pictures];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_recover());
    });
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    _controller.clearError();
    setState(() => _dirty = true);
  }

  Future<void> _recover() async {
    setState(() => _picking = true);
    try {
      final image = await ref
          .read(registrationDocumentPickerProvider)
          .recover();
      if (!mounted || !_sameSession || image == null) return;
      bool? document = true;
      if (widget.store != null) {
        document = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.tr('store_management.recovered')),
            content: Image.memory(
              image.bytes,
              height: 160,
              fit: BoxFit.contain,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('store_management.document')),
              ),
              if (_retained.length + _photos.length < 5)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(ctx.tr('store_management.photos')),
                ),
            ],
          ),
        );
      }
      if (!_sameSession || document == null) return;
      setState(() {
        if (document!) {
          _document = image;
        } else {
          _photos.add(image);
        }
        _dirty = true;
      });
    } catch (_) {
      if (mounted) setState(() => _imageError = 'store_management.image_error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pick({required bool document}) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final image = await ref.read(registrationDocumentPickerProvider).pick();
      if (!mounted || !_sameSession || image == null) return;
      setState(() {
        if (document) {
          _document = image;
        } else if (_retained.length + _photos.length < 5) {
          _photos.add(image);
        }
      });
      _changed();
    } catch (_) {
      if (mounted) setState(() => _imageError = 'store_management.image_error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  ProviderStoreDraft _draft() => ProviderStoreDraft(
    mobile: _text['mobile']!.text,
    changeReason: _text['change_reason']!.text.trim(),
    baseVersion: widget.store?.editVersion ?? '',
    details: SellerApplicationDraft(
      name: _text['name']!.text.trim(),
      nickname: _text['nick_name']!.text.trim(),
      employeeName: _text['employee_name']!.text.trim(),
      location: _text['url_location']!.text.trim(),
      registrationNumber: _text['commercial_registration_number']!.text.trim(),
      cityId: _city?.id ?? 0,
      companyIds: _companies.toList()..sort(),
      document: _document,
    ),
    retainedPictureIds: _retained.map((p) => p.id).toList(),
    pictures: List.unmodifiable(_photos),
  );
  Future<void> _save() async {
    final valid = _form.currentState?.validate() ?? false;
    if (_document == null &&
        _existingDocument == null &&
        widget.store == null) {
      setState(() => _imageError = 'store_management.document_required');
      return;
    }
    if (!valid) return;
    FocusScope.of(context).unfocus();
    final id = await _controller.save(
      _draft(),
      storeId: widget.store?.store.id,
      application: widget.application,
      requestKey: _requestKey,
    );
    if (!_sameSession) return;
    if (id != null) {
      _finish(id, saved: true);
    } else {
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _reconcile() async {
    final id = await _controller.reconcile(
      storeId: widget.store?.store.id,
      applicationId: widget.application?.id,
      mobile: _draft().normalizedMobile ?? '',
      requestKey: _requestKey,
    );
    if (_sameSession && id != null) _finish(id, saved: false);
  }

  void _finish(int id, {required bool saved}) {
    final router = GoRouter.of(context);
    final formPath = widget.store != null
        ? '/provider/more/stores/${widget.store!.store.id}/edit'
        : widget.application != null
        ? '/provider/more/stores/applications/${widget.application!.id}/edit'
        : '/provider/more/stores/add';
    setState(() {
      _dirty = false;
      _allowExit = true;
    });
    if (router.routeInformationProvider.value.uri.path != formPath) return;
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              widget.store != null
                  ? 'store_management.change_submitted'
                  : 'store_management.submitted',
            ),
          ),
        ),
      );
    }
    // Navigate before the refreshed application changes from rejected to pending
    // and removes this editor. Waiting for a frame can discard the completion.
    ProviderStoreApplicationRoute(requestId: id).go(context);
  }

  Future<void> _back() async {
    if (_leaving ||
        _picking ||
        ref.read(providerStoreWriteProvider(_formId)).busy) {
      return;
    }
    _leaving = true;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('customer_profile.discard_title')),
          content: Text(ctx.tr('customer_profile.discard_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('customer_profile.keep_editing')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('customer_profile.discard')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (discard != true) {
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
        const ProviderStoresRoute().go(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerStoreWriteProvider(_formId));
    final locked = state.busy || state.uncertain || _picking;
    final errors = state.error?.fieldErrors ?? const <String, List<String>>{};
    Widget field(
      String name,
      String label, {
      int max = 100,
      bool readOnly = false,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: Key('store-field-$name'),
        controller: _text[name],
        readOnly: locked || readOnly,
        maxLength: max,
        minLines: name == 'change_reason' ? 3 : 1,
        maxLines: name == 'change_reason' ? 5 : 1,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        textDirection: ['mobile', 'url_location'].contains(name)
            ? TextDirection.ltr
            : null,
        decoration: InputDecoration(
          labelText: context.tr(label),
          errorText: errors[name]?.firstOrNull,
          errorMaxLines: 4,
        ),
        onChanged: (_) => _changed(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.tr('store_management.required');
          }
          if (name == 'change_reason' && value.trim().runes.length < 10) {
            return context.tr('store_management.reason_min');
          }
          if (name == 'url_location' && !validStoreLocation(value)) {
            return context.tr('store_management.location_error');
          }
          if (name == 'mobile') {
            final parsed = SaudiMobileNumber.tryParse(value);
            if (parsed == null) {
              return context.tr('store_management.mobile_error');
            }
            if (widget.store == null &&
                widget.application == null &&
                '+966${parsed.nationalNumber}' == widget.session.user.mobile) {
              return context.tr('store_management.mobile_different');
            }
          }
          return null;
        },
      ),
    );
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: OctoGearSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(title),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
    return PopScope(
      canPop: _allowExit || (!_dirty && !state.busy && !_picking),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            controller: _scroll,
            key: const Key('provider-store-form'),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: state.busy || _picking ? null : _back,
                    icon: const BackButtonIcon(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                  ),
                  Expanded(
                    child: Text(
                      context.tr('store_management.$_title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const AppLanguageToggleButton(compact: true),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.tr(
                  widget.store == null
                      ? 'store_management.approval_hint'
                      : 'store_management.change_hint',
                ),
              ),
              const SizedBox(height: 20),
              if (widget.application?.rejectionReason != null)
                StoreInformation(
                  label: 'store_management.reason',
                  value: widget.application!.rejectionReason!,
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      state.error?.statusCode == 409
                          ? context.tr('store_management.conflict')
                          : authenticationFailureText(context, state.error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (state.uncertain)
                section('store_management.check_title', [
                  Text(context.tr('store_management.uncertain')),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('store-check-status'),
                    onPressed: state.busy ? null : _reconcile,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('seller.check_status')),
                  ),
                ]),
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.store != null)
                      section('store_management.change_reason', [
                        field(
                          'change_reason',
                          'store_management.reason_label',
                          max: 1000,
                          keyboard: TextInputType.multiline,
                        ),
                      ]),
                    section('store_management.basic', [
                      field('name', 'store_management.name'),
                      field('nick_name', 'store_management.nickname'),
                      field('employee_name', 'store_management.employee'),
                      field(
                        'mobile',
                        'provider_stores.phone',
                        max: 15,
                        keyboard: TextInputType.phone,
                        readOnly:
                            widget.application != null || widget.store != null,
                      ),
                      if (widget.application != null || widget.store != null)
                        Text(
                          context.tr(
                            widget.store != null
                                ? 'store_management.mobile_locked'
                                : 'store_management.application_mobile_locked',
                          ),
                        ),
                    ]),
                    section('store_management.location_brands', [
                      RegistrationCityField(
                        key: const Key('store-city'),
                        value: _city,
                        apiError: errors['city_id']?.firstOrNull,
                        onChanged: locked
                            ? null
                            : (city) {
                                _city = city;
                                _changed();
                              },
                        validator: (city) => city == null
                            ? context.tr('auth.city_required')
                            : null,
                      ),
                      const SizedBox(height: 20),
                      field(
                        'url_location',
                        'provider_stores.location',
                        max: 255,
                        keyboard: TextInputType.url,
                      ),
                      SellerCompanyField(
                        ids: _companies,
                        onChanged: locked
                            ? null
                            : (ids) {
                                _companies = ids;
                                _changed();
                              },
                      ),
                      for (final e in errors.entries.where(
                        (e) => e.key.startsWith('company_ids'),
                      ))
                        Text(
                          e.value.join('\n'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ]),
                    section('store_management.registration_section', [
                      field(
                        'commercial_registration_number',
                        'store_management.registration',
                        max: 50,
                      ),
                      if (_document != null)
                        Image.memory(
                          _document!.bytes,
                          height: 170,
                          fit: BoxFit.contain,
                        )
                      else if (_existingDocument != null)
                        StorePrivateImage(
                          path: _existingDocument!,
                          label: 'store_management.document',
                        ),
                      const SizedBox(height: 12),
                      Text(context.tr('store_management.image_hint')),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('store-document'),
                        onPressed: locked ? null : () => _pick(document: true),
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          context.tr('store_management.choose_document'),
                        ),
                      ),
                      if (_document != null)
                        TextButton(
                          onPressed: locked
                              ? null
                              : () {
                                  setState(() => _document = null);
                                  _changed();
                                },
                          child: Text(
                            context.tr('store_management.undo_document'),
                          ),
                        ),
                      for (final e in errors.entries.where(
                        (e) =>
                            e.key.startsWith('commercial_registration_picture'),
                      ))
                        Text(
                          e.value.join('\n'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ]),
                    if (widget.store != null)
                      section('store_management.photos', [
                        Text(context.tr('store_management.photos_hint')),
                        const SizedBox(height: 16),
                        for (final picture in _retained) ...[
                          StorePrivateImage(
                            path: picture.path,
                            label: 'store_management.photos',
                          ),
                          TextButton.icon(
                            onPressed: locked
                                ? null
                                : () {
                                    _retained.remove(picture);
                                    _changed();
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(
                              context.tr('store_management.remove_photo'),
                            ),
                          ),
                        ],
                        for (final photo in _photos) ...[
                          Image.memory(
                            photo.bytes,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          TextButton.icon(
                            onPressed: locked
                                ? null
                                : () {
                                    _photos.remove(photo);
                                    _changed();
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(
                              context.tr('store_management.remove_photo'),
                            ),
                          ),
                        ],
                        OutlinedButton.icon(
                          key: const Key('store-add-photo'),
                          onPressed:
                              locked || _retained.length + _photos.length >= 5
                              ? null
                              : () => _pick(document: false),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(context.tr('store_management.add_photo')),
                        ),
                        for (final e in errors.entries.where(
                          (e) =>
                              e.key.startsWith('pictures') ||
                              e.key.startsWith('retained_picture_ids'),
                        ))
                          Text(
                            e.value.join('\n'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ]),
                  ],
                ),
              ),
              if (_imageError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    context.tr(_imageError!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                key: const Key('store-save'),
                onPressed: locked || (widget.store != null && !_dirty)
                    ? null
                    : _save,
                icon: state.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  context.tr(
                    widget.store == null
                        ? 'store_management.submit'
                        : 'store_management.submit_change',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
