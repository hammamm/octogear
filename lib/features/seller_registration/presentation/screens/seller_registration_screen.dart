import 'dart:async';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/saudi_mobile_number.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../authentication/presentation/widgets/authentication_failure_text.dart';
import '../../../authentication/presentation/widgets/registration_city_field.dart';
import '../../domain/entities/seller_application.dart';
import '../services/registration_document_picker.dart';
import '../widgets/seller_application_status.dart';
import '../controllers/seller_registration_controller.dart';
import '../widgets/seller_company_field.dart';

class SellerRegistrationScreen extends ConsumerWidget {
  const SellerRegistrationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession) return const SizedBox.shrink();
    return _SellerForm(key: ObjectKey(session), user: session.user);
  }
}

class _SellerForm extends ConsumerStatefulWidget {
  const _SellerForm({required this.user, super.key});
  final AppUser user;
  @override
  ConsumerState<_SellerForm> createState() => _SellerFormState();
}

class _SellerFormState extends ConsumerState<_SellerForm> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _name = TextEditingController(), _nickname = TextEditingController();
  final _employee = TextEditingController(),
      _registration = TextEditingController();
  final _location = TextEditingController(),
      _mobile = TextEditingController(),
      _code = TextEditingController();
  AppCity? _city;
  RegistrationDocument? _document;
  Set<int> _companyIds = {};
  int _step = 0;
  bool _editing = false, _dirty = false, _picking = false, _allowExit = false;
  String? _documentError;
  Timer? _ticker;
  SellerRegistrationController get _controller =>
      ref.read(sellerRegistrationControllerProvider(widget.user.id).notifier);

  @override
  void initState() {
    super.initState();
    _employee.text = widget.user.fullName;
    _city = widget.user.city;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _step == 2) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.load());
      unawaited(_pick(recover: true));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    for (final field in [
      _name,
      _nickname,
      _employee,
      _registration,
      _location,
      _mobile,
      _code,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _pick({bool recover = false}) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ref.read(registrationDocumentPickerProvider);
      final document = recover ? await picker.recover() : await picker.pick();
      if (!mounted || document == null) return;
      setState(() {
        _document = document;
        _documentError = null;
        _dirty = true;
      });
    } catch (_) {
      if (mounted && !recover) {
        setState(() => _documentError = 'seller.document_error');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _exit() async {
    final state = ref.read(
      sellerRegistrationControllerProvider(widget.user.id),
    );
    if (state.busy || _picking) return;
    if (_dirty && (state.application == null || _editing)) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('seller.leave_title')),
          content: Text(context.tr('seller.leave_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('seller.keep_editing')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('seller.leave')),
            ),
          ],
        ),
      );
      if (!mounted || leave != true) return;
    }
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _correct(SellerApplication application) {
    _name.text = application.name;
    _nickname.text = application.nickname;
    _employee.text = application.employeeName;
    _registration.text = application.registrationNumber;
    _location.text = application.location;
    _mobile.text = application.mobile;
    _city = application.city;
    _companyIds = application.companyIds.toSet();
    setState(() {
      _editing = true;
      _dirty = true;
      _step = 0;
    });
  }

  Future<void> _next(SellerRegistrationState state) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_step == 0 &&
        _document == null &&
        state.application?.hasDocument != true) {
      setState(() => _documentError = 'seller.document_required');
      return;
    }
    if (_step < 2) {
      _go(_step + 1);
      return;
    }
    if (_step == 2) {
      if (_editing || state.verified) {
        _go(3);
        return;
      }
      if (state.codeSent) {
        final verified = await _controller.verify(_code.text);
        if (mounted && verified) {
          _code.clear();
          _go(3);
        }
      } else {
        await _controller.sendCode(_mobile.text);
      }
      return;
    }
    final saved = await _controller.submit(
      SellerApplicationDraft(
        name: _name.text,
        nickname: _nickname.text,
        employeeName: _employee.text,
        location: _location.text,
        registrationNumber: _registration.text,
        cityId: _city!.id,
        companyIds: _companyIds.toList(),
        document: _document,
      ),
    );
    if (!mounted) return;
    if (saved) {
      setState(() {
        _dirty = false;
        _editing = false;
        _document = null;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } else if (!_editing &&
        !ref
            .read(sellerRegistrationControllerProvider(widget.user.id))
            .uncertain) {
      _code.clear();
      _go(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      sellerRegistrationControllerProvider(widget.user.id),
    );
    final busy = state.busy || _picking;
    final application = state.application;
    final showStatus =
        application != null &&
        (!_editing || application.status != SellerApplicationStatus.rejected);
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: _allowExit || (!busy && !_dirty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exit());
      },
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: busy ? null : _exit,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: const BackButtonIcon(),
                      ),
                      Expanded(
                        child: Text(
                          context.tr('seller.title'),
                          style: text.titleLarge,
                        ),
                      ),
                      const AppLanguageToggleButton(compact: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (state.loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.loadFailed)
                    OutlinedButton.icon(
                      onPressed: busy ? null : _controller.load,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.tr('seller.check_status')),
                    )
                  else if (showStatus)
                    SellerApplicationStatusView(
                      application: application,
                      onRefresh: busy ? null : _controller.load,
                      onCorrect: () => _correct(application),
                    )
                  else if (state.uncertain)
                    OctoGearSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.sync_rounded, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('seller.uncertain'),
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    await _controller.load();
                                    if (mounted) {
                                      _code.clear();
                                      _go(2);
                                    }
                                  },
                            child: Text(context.tr('seller.check_status')),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: OctoGearColors.navy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            color: OctoGearColors.yellowSoft,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr(
                              _editing ? 'seller.correct' : 'seller.hero',
                            ),
                            style: text.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.tr('seller.hero_body'),
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      label: context.tr(
                        'seller.step_count',
                        args: ['${_step + 1}', '4'],
                      ),
                      child: Row(
                        children: List.generate(
                          4,
                          (i) => Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsetsDirectional.only(
                                end: i == 3 ? 0 : 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: i <= _step
                                    ? OctoGearColors.navy
                                    : OctoGearColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'seller.step_count',
                        args: ['${_step + 1}', '4'],
                      ),
                      style: text.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('seller.step_$_step'),
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(context.tr('seller.step_${_step}_body')),
                    const SizedBox(height: 20),
                    Form(
                      key: _form,
                      child: OctoGearSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _fields(state, busy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_step == 3) ...[
                      Text(context.tr('seller.before_submit')),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      key: const Key('seller-next'),
                      onPressed: busy ? null : () => _next(state),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.tr(
                                  _step == 3
                                      ? 'seller.submit'
                                      : _step == 2 &&
                                            !_editing &&
                                            !state.verified
                                      ? (state.codeSent
                                            ? 'seller.verify'
                                            : 'seller.send_code')
                                      : 'seller.continue',
                                ),
                              ),
                      ),
                    ),
                    if (_step > 0)
                      TextButton(
                        onPressed: busy ? null : () => _go(_step - 1),
                        child: Text(context.tr('seller.previous')),
                      ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        authenticationFailureText(context, state.error),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    if (application == null && !state.codeSent && !_dirty)
                      TextButton(
                        onPressed: busy ? null : _controller.load,
                        child: Text(context.tr('seller.check_status')),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields(SellerRegistrationState state, bool busy) {
    switch (_step) {
      case 0:
        return [
          _field(
            _employee,
            'employee',
            'employee_name',
            state,
            busy,
            icon: Icons.person_outline,
          ),
          _field(
            _registration,
            'registration',
            'commercial_registration_number',
            state,
            busy,
            max: 50,
            icon: Icons.badge_outlined,
          ),
          if (_document != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _document!.bytes,
                height: 170,
                fit: BoxFit.contain,
                semanticLabel: context.tr('seller.document'),
              ),
            )
          else if (state.application?.hasDocument == true)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.task_alt),
              title: Text(context.tr('seller.document_retained')),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('seller-document'),
            onPressed: busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              context.tr(
                _document == null
                    ? 'seller.document'
                    : 'seller.replace_document',
              ),
            ),
          ),
          Text(
            context.tr('seller.document_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_documentError != null)
            Text(
              context.tr(_documentError!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (state
                  .error
                  ?.fieldErrors['commercial_registration_picture']
                  ?.firstOrNull
              case final String error)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ];
      case 1:
        return [
          _field(
            _name,
            'store_name',
            'name',
            state,
            busy,
            icon: Icons.storefront_outlined,
          ),
          _field(
            _nickname,
            'nickname',
            'nick_name',
            state,
            busy,
            icon: Icons.sell_outlined,
          ),
          RegistrationCityField(
            value: _city,
            onChanged: busy
                ? null
                : (city) => setState(() {
                    _city = city;
                    _dirty = true;
                  }),
            apiError: state.error?.fieldErrors['city_id']?.firstOrNull,
            validator: (city) =>
                city == null ? context.tr('auth.city_required') : null,
          ),
          const SizedBox(height: 20),
          _field(
            _location,
            'location',
            'url_location',
            state,
            busy,
            max: 255,
            keyboard: TextInputType.url,
            icon: Icons.location_on_outlined,
            validator: (value) => validStoreLocation(value ?? '')
                ? null
                : context.tr('seller.location_error'),
          ),
          SellerCompanyField(
            ids: _companyIds,
            onChanged: busy
                ? null
                : (ids) => setState(() {
                    _companyIds = ids;
                    _dirty = true;
                  }),
          ),
          Text(
            context.tr('seller.companies_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      case 2:
        final remaining =
            state.retryAt?.difference(DateTime.now()).inSeconds ?? 0;
        return [
          TextFormField(
            key: const Key('seller-mobile'),
            controller: _mobile,
            readOnly: _editing || state.codeSent || state.verified,
            enabled: !busy,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            decoration: InputDecoration(
              labelText: context.tr('seller.mobile'),
              hintText: '05XXXXXXXX',
              errorText: state.error?.fieldErrors['mobile']?.firstOrNull,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            onChanged: (_) {
              _dirty = true;
              _controller.changeMobile();
            },
            validator: (value) {
              final mobile = SaudiMobileNumber.tryParse(value ?? '');
              if (mobile == null) return context.tr('auth.phone_invalid');
              if (mobile.nationalNumber ==
                  SaudiMobileNumber.tryParse(
                    widget.user.mobile,
                  )?.nationalNumber) {
                return context.tr('seller.different_mobile');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(
              _editing ? 'seller.mobile_retained' : 'seller.mobile_hint',
            ),
          ),
          if (!_editing && state.codeSent && !state.verified) ...[
            const SizedBox(height: 20),
            if (state.testCode != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OctoGearColors.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(context.tr('auth.testing_otp')),
                    Text(
                      state.testCode!,
                      key: const Key('seller-test-code'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('seller-code'),
              controller: _code,
              enabled: !busy,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: context.tr('auth.otp_label'),
                errorText: state.error?.fieldErrors['otp']?.firstOrNull,
              ),
              validator: (value) => RegExp(r'^\d{4}$').hasMatch(value ?? '')
                  ? null
                  : context.tr('auth.otp_invalid'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: busy || remaining > 0
                  ? null
                  : () async {
                      _code.clear();
                      await _controller.sendCode(_mobile.text);
                    },
              child: Text(
                remaining > 0
                    ? context.tr('seller.resend_wait', args: ['$remaining'])
                    : context.tr('auth.resend_otp'),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      _code.clear();
                      _controller.changeMobile();
                    },
              child: Text(context.tr('seller.change_mobile')),
            ),
          ],
          if (!_editing && !state.codeSent && remaining > 0)
            Text(context.tr('seller.resend_wait', args: ['$remaining'])),
          if (state.verified)
            Text(
              context.tr('seller.verified'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ];
      default:
        return [
          Text(
            context.tr(
              'seller.companies_count',
              args: ['${_companyIds.length}'],
            ),
          ),
          const SizedBox(height: 16),
          for (final pair in [
            ('seller.store_name', _name.text),
            ('seller.nickname', _nickname.text),
            ('seller.employee', _employee.text),
            ('seller.registration', _registration.text),
            ('auth.city_label', _city?.name ?? ''),
            ('seller.location', _location.text),
            ('seller.mobile', _mobile.text),
          ]) ...[
            Text(
              context.tr(pair.$1),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(pair.$2, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Icon(Icons.task_alt, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(context.tr('seller.document_ready'))),
            ],
          ),
        ];
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String apiKey,
    SellerRegistrationState state,
    bool busy, {
    int max = 100,
    IconData? icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      key: ValueKey('seller-$apiKey'),
      controller: controller,
      enabled: !busy,
      keyboardType: keyboard,
      textInputAction: TextInputAction.next,
      maxLength: max,
      decoration: InputDecoration(
        labelText: context.tr('seller.$label'),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        counterText: '',
        prefixIcon: icon == null ? null : Icon(icon),
        errorText: state.error?.fieldErrors[apiKey]?.firstOrNull,
      ),
      onChanged: (_) => setState(() => _dirty = true),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? context.tr('seller.required')
              : null,
    ),
  );
}
