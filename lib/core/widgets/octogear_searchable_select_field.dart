import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../design_system/octogear_theme.dart';

/// A labeled value in a searchable, single-selection field.
class OctoGearSelectOption<T> {
  const OctoGearSelectOption({required this.value, required this.label});
  final T value;
  final String label;
}

/// Uses the same validation and decoration as other form controls. Search is
/// local to the complete option list supplied by the owning feature.
class OctoGearSearchableSelectField<T> extends FormField<T> {
  OctoGearSearchableSelectField({
    required this.value,
    required this.options,
    required this.label,
    required this.hint,
    required this.searchHint,
    required this.noResultsText,
    required this.icon,
    required this.onChanged,
    this.apiError,
    super.validator,
    super.key,
  }) : super(
         initialValue: value,
         enabled: onChanged != null,
         builder: (field) =>
             (field as _SearchableSelectFieldState<T>)._buildField(),
       );

  final T? value;
  final List<OctoGearSelectOption<T>> options;
  final String label, hint, searchHint, noResultsText;
  final IconData icon;
  final String? apiError;
  final ValueChanged<T?>? onChanged;

  @override
  FormFieldState<T> createState() => _SearchableSelectFieldState<T>();
}

class _SearchableSelectFieldState<T> extends FormFieldState<T> {
  @override
  OctoGearSearchableSelectField<T> get widget =>
      super.widget as OctoGearSearchableSelectField<T>;

  @override
  void didUpdateWidget(covariant OctoGearSearchableSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reference refreshes and parent-driven resets must also update validation.
    if (oldWidget.value != widget.value) setValue(widget.value);
  }

  Future<void> _choose() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SearchableOptionsSheet<T>(
        options: widget.options,
        selectedValue: value,
        title: widget.label,
        searchHint: widget.searchHint,
        noResultsText: widget.noResultsText,
      ),
    );
    if (!mounted || !widget.enabled || selected == null || selected == value) {
      return;
    }
    if (!widget.options.any((option) => option.value == selected)) return;
    didChange(selected);
    widget.onChanged!(selected);
  }

  Widget _buildField() {
    final selected = widget.options
        .where((option) => option.value == value)
        .firstOrNull;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: InkWell(
        onTap: widget.enabled ? _choose : null,
        borderRadius: BorderRadius.circular(OctoGearRadii.small),
        child: InputDecorator(
          isEmpty: selected == null,
          decoration: InputDecoration(
            labelText: widget.label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            enabled: widget.enabled,
            errorText: widget.apiError ?? errorText,
            errorMaxLines: 3,
            prefixIcon: Icon(widget.icon),
            suffixIcon: const Icon(Icons.search_rounded),
          ),
          child: Text(
            selected?.label ?? widget.hint,
            style: selected == null
                ? Theme.of(context).inputDecorationTheme.hintStyle
                : null,
          ),
        ),
      ),
    );
  }
}

class _SearchableOptionsSheet<T> extends StatefulWidget {
  const _SearchableOptionsSheet({
    required this.options,
    required this.selectedValue,
    required this.title,
    required this.searchHint,
    required this.noResultsText,
  });
  final List<OctoGearSelectOption<T>> options;
  final T? selectedValue;
  final String title, searchHint, noResultsText;
  @override
  State<_SearchableOptionsSheet<T>> createState() =>
      _SearchableOptionsSheetState<T>();
}

class _SearchableOptionsSheetState<T>
    extends State<_SearchableOptionsSheet<T>> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Ignore case, Arabic vowel marks and common alef variants when matching.
  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي');

  @override
  Widget build(BuildContext context) {
    final query = _normalize(_search.text);
    final options = widget.options
        .where((option) => _normalize(option.label).contains(query))
        .toList();
    return FractionallySizedBox(
      heightFactor: MediaQuery.viewInsetsOf(context).bottom > 0 ? 1 : .85,
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
                    widget.title,
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
              key: const Key('searchable-select-query'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_search.clear),
                        tooltip: context.tr('common.clear_search'),
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: options.isEmpty
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            widget.noResultsText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return ListTile(
                          title: Text(option.label),
                          selected: option.value == widget.selectedValue,
                          trailing: option.value == widget.selectedValue
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.pop(context, option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
