import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/presentation/widgets/authentication_failure_text.dart';
import '../../domain/entities/seller_company.dart';
import '../controllers/seller_company_providers.dart';

class SellerCompanyField extends StatelessWidget {
  const SellerCompanyField({
    required this.ids,
    required this.onChanged,
    super.key,
  });
  final Set<int> ids;
  final ValueChanged<Set<int>>? onChanged;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const Key('seller-companies'),
    icon: const Icon(Icons.directions_car_outlined),
    onPressed: onChanged == null
        ? null
        : () async {
            final result = await showModalBottomSheet<Set<int>>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              useRootNavigator: true,
              showDragHandle: true,
              builder: (_) => _CompanyPicker(selected: ids),
            );
            if (context.mounted && result != null) onChanged?.call(result);
          },
    label: Text(
      ids.isEmpty
          ? context.tr('seller.companies')
          : context.tr('seller.companies_count', args: ['${ids.length}']),
    ),
  );
}

class _CompanyPicker extends ConsumerStatefulWidget {
  const _CompanyPicker({required this.selected});
  final Set<int> selected;
  @override
  ConsumerState<_CompanyPicker> createState() => _CompanyPickerState();
}

class _CompanyPickerState extends ConsumerState<_CompanyPicker> {
  late final _selected = {...widget.selected};
  final _search = TextEditingController();
  final _items = <SellerCompany>[];
  Timer? _debounce;
  String _query = '';
  int _page = 0, _generation = 0;
  bool _busy = false, _hasMore = true;
  Object? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(reset: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy && !reset) return;
    if (reset) {
      _items.clear();
      _page = 0;
    }
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(loadSellerCompaniesProvider)(
        _query,
        _page + 1,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _page++;
        _items.addAll(result.items);
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLocaleProvider, (_, _) => _load(reset: true));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      context.tr('seller.companies'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        labelText: context.tr('seller.search_companies'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (query) {
                        _debounce?.cancel();
                        _query = query.trim();
                        _generation++;
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () => _load(reset: true),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    for (final item in _items)
                      CheckboxListTile(
                        value: _selected.contains(item.id),
                        title: Text(item.name),
                        onChanged:
                            _selected.length >= 100 &&
                                !_selected.contains(item.id)
                            ? null
                            : (checked) => setState(() {
                                if (checked == true) {
                                  _selected.add(item.id);
                                } else {
                                  _selected.remove(item.id);
                                }
                              }),
                      ),
                    if (_busy)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (_error != null) ...[
                      Text(authenticationFailureText(context, _error)),
                      TextButton(
                        onPressed: () => _load(),
                        child: Text(context.tr('seller.retry')),
                      ),
                    ] else if (!_busy && _items.isEmpty)
                      Text(context.tr('seller.no_companies'))
                    else if (!_busy && _hasMore)
                      TextButton(
                        onPressed: () => _load(),
                        child: Text(context.tr('seller.more_companies')),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(
                    context.tr(
                      'seller.companies_done',
                      args: ['${_selected.length}'],
                    ),
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
