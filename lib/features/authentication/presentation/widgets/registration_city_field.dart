import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/registration_cities_controller.dart';
import 'authentication_failure_text.dart';

/// Selection is independent of the current result page, so changing a search
/// or dismissing the picker cannot silently change the registration payload.
class RegistrationCityField extends FormField<AppCity> {
  RegistrationCityField({
    required this.value,
    required this.onChanged,
    this.apiError,
    super.validator,
    super.key,
  }) : super(
         initialValue: value,
         enabled: onChanged != null,
         builder: (field) =>
             (field as _RegistrationCityFieldState).buildField(),
       );

  final AppCity? value;
  final ValueChanged<AppCity>? onChanged;
  final String? apiError;

  @override
  FormFieldState<AppCity> createState() => _RegistrationCityFieldState();
}

class _RegistrationCityFieldState extends FormFieldState<AppCity> {
  @override
  RegistrationCityField get widget => super.widget as RegistrationCityField;

  @override
  void didUpdateWidget(covariant RegistrationCityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) setValue(widget.value);
  }

  Future<void> _choose() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<AppCity>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => RegistrationCityPicker(selectedId: value?.id),
    );
    if (!mounted || !widget.enabled || selected == null) return;
    didChange(selected);
    widget.onChanged!(selected);
  }

  Widget buildField() => Semantics(
    button: true,
    enabled: widget.enabled,
    child: InkWell(
      key: const Key('registration-city-field'),
      onTap: widget.enabled ? _choose : null,
      borderRadius: BorderRadius.circular(OctoGearRadii.small),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.tr('auth.city_label'),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabled: widget.enabled,
          errorText: widget.apiError ?? errorText,
          prefixIcon: const Icon(Icons.location_city_outlined),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(value?.name ?? context.tr('auth.city_required')),
      ),
    ),
  );
}

class RegistrationCityPicker extends ConsumerStatefulWidget {
  const RegistrationCityPicker({this.selectedId, super.key});
  final int? selectedId;

  @override
  ConsumerState<RegistrationCityPicker> createState() =>
      _RegistrationCityPickerState();
}

class _RegistrationCityPickerState
    extends ConsumerState<RegistrationCityPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _waitingForSearch = false;

  void _queryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query == _query) {
      setState(() => _waitingForSearch = false);
      return;
    }
    setState(() => _waitingForSearch = true);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _query = query;
        _waitingForSearch = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = registrationCitiesProvider(_query);
    final cities = _waitingForSearch
        ? const AsyncLoading<RegistrationCitiesState>()
        : ref.watch(provider);
    return FractionallySizedBox(
      heightFactor: .9,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('auth.city_label'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('registration-city-search'),
              controller: _search,
              maxLength: 100,
              onChanged: _queryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: context.tr('auth.search_cities'),
                prefixIcon: const Icon(Icons.search),
                counterText: '',
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.tr('common.clear_search'),
                        onPressed: () {
                          _search.clear();
                          _queryChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: cities.when(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(authenticationFailureText(context, error)),
                      TextButton(
                        onPressed: () => ref.read(provider.notifier).retry(),
                        child: Text(context.tr('common.retry')),
                      ),
                    ],
                  ),
                ),
                data: (data) => ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: data.page.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index < data.page.items.length) {
                      final city = data.page.items[index];
                      return ListTile(
                        key: ValueKey('registration-city-${city.id}'),
                        title: Text(city.name),
                        selected: city.id == widget.selectedId,
                        trailing: city.id == widget.selectedId
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.pop(context, city),
                      );
                    }
                    if (data.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (data.nextPageError != null) {
                      return Column(
                        children: [
                          Text(
                            authenticationFailureText(
                              context,
                              data.nextPageError,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.read(provider.notifier).loadMore(),
                            child: Text(context.tr('common.retry')),
                          ),
                        ],
                      );
                    }
                    if (data.page.items.isEmpty) {
                      return Text(
                        context.tr(
                          _query.isEmpty
                              ? 'auth.cities_empty'
                              : 'auth.cities_no_results',
                        ),
                        textAlign: TextAlign.center,
                      );
                    }
                    return data.page.hasMore
                        ? TextButton(
                            onPressed: () =>
                                ref.read(provider.notifier).loadMore(),
                            child: Text(context.tr('auth.more_cities')),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
