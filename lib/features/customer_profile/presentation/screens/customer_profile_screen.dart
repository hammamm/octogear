import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../authentication/presentation/widgets/authentication_failure_text.dart';
import '../../../authentication/presentation/widgets/registration_city_field.dart';
import '../../domain/entities/update_customer_profile_command.dart';
import '../controllers/customer_profile_controller.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession ||
        session.user.role != AppUserRole.customer) {
      return const SizedBox.shrink();
    }
    return _ProfileForm(key: ValueKey(session.user.id), user: session.user);
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user, super.key});
  final AppUser user;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late AppUser _baseline;
  AppCity? _city;
  bool _allowExit = false, _leaving = false;

  bool get _dirty =>
      _name.text.trim() != _baseline.fullName ||
      _city?.id != _baseline.city?.id;

  @override
  void initState() {
    super.initState();
    _baseline = widget.user;
    _name = TextEditingController(text: widget.user.fullName);
    _city = widget.user.city;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _changed() {
    ref
        .read(customerProfileControllerProvider(widget.user.id).notifier)
        .clearError();
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(customerProfileControllerProvider(widget.user.id).notifier)
        .save(
          UpdateCustomerProfileCommand(fullName: _name.text, cityId: _city!.id),
        );
    if (!mounted || saved == null) return;
    setState(() {
      _baseline = saved;
      _name.text = saved.fullName;
      _city = saved.city;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('customer_profile.saved'))),
    );
  }

  Future<void> _back() async {
    if (_leaving ||
        ref.read(customerProfileControllerProvider(widget.user.id)).saving) {
      return;
    }
    _leaving = true;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('customer_profile.discard_title')),
          content: Text(dialogContext.tr('customer_profile.discard_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('customer_profile.keep_editing')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('customer_profile.discard')),
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
        const CustomerMoreRoute().go(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProfileControllerProvider(widget.user.id));
    final errors = state.error?.fieldErrors;
    return PopScope(
      canPop: _allowExit || (!_dirty && !state.saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListView(
        key: const Key('customer-profile'),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: state.saving ? null : _back,
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              Expanded(
                child: Text(
                  context.tr('customer_more.profile'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.tr('customer_profile.description')),
          const SizedBox(height: 20),
          Form(
            key: _form,
            child: OctoGearSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('profile-full-name'),
                    controller: _name,
                    readOnly: state.saving,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: context.tr('auth.full_name_label'),
                      errorText: errors?['full_name']?.firstOrNull,
                      errorMaxLines: 3,
                    ),
                    onChanged: (_) => _changed(),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.tr('customer_profile.name_required')
                        : value.trim().runes.length > 100
                        ? context.tr('customer_profile.name_too_long')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  RegistrationCityField(
                    key: const Key('profile-city'),
                    value: _city,
                    apiError: errors?['city_id']?.firstOrNull,
                    onChanged: state.saving
                        ? null
                        : (city) {
                            _city = city;
                            _changed();
                          },
                    validator: (city) =>
                        city == null ? context.tr('auth.city_required') : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OctoGearSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('auth.phone_label'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  widget.user.mobile,
                  key: const Key('profile-mobile'),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('customer_profile.mobile_read_only'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  authenticationFailureText(context, state.error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('profile-save'),
            onPressed: state.saving || !_dirty ? null : _save,
            icon: state.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              context.tr(
                state.error == null ? 'customer_profile.save' : 'common.retry',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
