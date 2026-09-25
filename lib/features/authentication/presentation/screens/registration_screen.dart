import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_brand_header.dart';
import '../../../../core/widgets/octogear_page_scaffold.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/authentication_flow_controller.dart';
import '../controllers/registration_cities_controller.dart';
import '../controllers/registration_controller.dart';
import '../controllers/session_controller.dart';
import '../widgets/authentication_failure_text.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  AppCity? _selectedCity;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final temporaryToken = ref
        .read(authenticationFlowProvider)
        .temporaryRegistrationToken;
    final city = _selectedCity;
    if (temporaryToken == null || city == null) return;

    await ref
        .read(registrationControllerProvider.notifier)
        .register(
          temporaryRegistrationToken: temporaryToken,
          fullName: _fullNameController.text,
          cityId: city.id,
        );
  }

  Future<void> _completeRegistration() async {
    ref.read(authenticationFlowProvider.notifier).clear();
    await ref.read(sessionControllerProvider.notifier).retry();
    if (!mounted) return;
    const SessionLoadingRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RegistrationState>(registrationControllerProvider, (
      previous,
      next,
    ) {
      if (next.successfulSubmissionCount >
              (previous?.successfulSubmissionCount ?? 0) &&
          mounted) {
        unawaited(_completeRegistration());
      }
    });

    final cities = ref.watch(registrationCitiesProvider);
    final registration = ref.watch(registrationControllerProvider);
    final apiFailure = registration.error as ApiFailure?;

    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
                icon: const BackButtonIcon(),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          const OctoGearBrandHeader(compact: true),
          const SizedBox(height: OctoGearSpacing.xLarge),
          OctoGearSurfaceCard(
            semanticLabel: context.tr('auth.registration_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('auth.registration_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OctoGearSpacing.xSmall),
                Text(
                  context.tr('auth.registration_description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: OctoGearColors.structuralGray,
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.xLarge),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: context.tr('auth.full_name_label'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          counterText: '',
                          errorText:
                              apiFailure?.fieldErrors['full_name']?.first,
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true
                            ? context.tr('auth.full_name_required')
                            : null,
                      ),
                      const SizedBox(height: OctoGearSpacing.medium),
                      cities.when(
                        loading: () => const _CitiesLoading(),
                        error: (error, _) => _CitiesError(
                          message: authenticationFailureText(context, error),
                          onRetry: () => ref
                              .read(registrationCitiesProvider.notifier)
                              .retry(),
                        ),
                        data: (values) {
                          if (values.isEmpty) {
                            return _CitiesError(
                              message: context.tr('auth.cities_empty'),
                              onRetry: () => ref
                                  .read(registrationCitiesProvider.notifier)
                                  .retry(),
                            );
                          }
                          return DropdownButtonFormField<AppCity>(
                            initialValue: _selectedCity,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.tr('auth.city_label'),
                              prefixIcon: const Icon(
                                Icons.location_city_outlined,
                              ),
                              errorText:
                                  apiFailure?.fieldErrors['city_id']?.first,
                            ),
                            items: values
                                .map(
                                  (city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: registration.isSubmitting
                                ? null
                                : (city) =>
                                      setState(() => _selectedCity = city),
                            validator: (city) => city == null
                                ? context.tr('auth.city_required')
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (registration.error != null &&
                    apiFailure?.fieldErrors.isEmpty != false) ...[
                  const SizedBox(height: OctoGearSpacing.medium),
                  OctoGearFeedbackBanner(
                    message: authenticationFailureText(
                      context,
                      registration.error,
                    ),
                    tone: OctoGearFeedbackTone.error,
                  ),
                ],
                const SizedBox(height: OctoGearSpacing.large),
                FilledButton(
                  onPressed: registration.isSubmitting || cities.isLoading
                      ? null
                      : _register,
                  child: registration.isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(context.tr('auth.complete_registration')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitiesLoading extends StatelessWidget {
  const _CitiesLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: OctoGearColors.surfaceMuted,
        borderRadius: BorderRadius.circular(OctoGearRadii.small),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OctoGearSpacing.small),
          Expanded(
            child: Text(
              context.tr('auth.cities_loading'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CitiesError extends StatelessWidget {
  const _CitiesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OctoGearFeedbackBanner(
          message: message,
          tone: OctoGearFeedbackTone.error,
        ),
        const SizedBox(height: OctoGearSpacing.xSmall),
        TextButton(onPressed: onRetry, child: Text(context.tr('common.retry'))),
      ],
    );
  }
}
