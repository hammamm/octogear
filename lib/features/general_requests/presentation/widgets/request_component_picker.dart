import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/general_request.dart';
import '../controllers/general_request_providers.dart';

/// Explicit pagination keeps large reference catalogs usable on a phone.
class RequestComponentPicker extends ConsumerStatefulWidget {
  const RequestComponentPicker({super.key});
  @override
  ConsumerState<RequestComponentPicker> createState() =>
      _RequestComponentPickerState();
}

class _RequestComponentPickerState
    extends ConsumerState<RequestComponentPicker> {
  final _search = TextEditingController();
  final _items = <RequestComponent>[];
  Timer? _debounce;
  int _generation = 0, _page = 0, _lastPage = 1;
  bool _loading = true, _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _queryChanged(String _) {
    _debounce?.cancel();
    _generation++;
    setState(() {
      _loading = true;
      _failed = false;
      _items.clear();
    });
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(reset: true),
    );
  }

  Future<void> _load({bool reset = false}) async {
    final generation = ++_generation;
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await ref
          .read(generalRequestRepositoryProvider)
          .components(search: _search.text.trim(), page: page);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) _items.clear();
        final ids = _items.map((item) => item.id).toSet();
        _items.addAll(result.items.where((item) => ids.add(item.id)));
        _page = result.page;
        _lastPage = result.lastPage;
        _loading = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('general_request.choose_part'),
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
              key: const Key('general-part-search'),
              controller: _search,
              maxLength: 100,
              onChanged: _queryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: context.tr('general_request.search_part'),
                prefixIcon: const Icon(Icons.search),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final item in _items)
                    ListTile(
                      key: ValueKey('catalog-part-${item.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.pop(context, item),
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_failed) ...[
                    Text(context.tr('general_request.catalog_error')),
                    TextButton(
                      onPressed: () => _load(reset: _items.isEmpty),
                      child: Text(context.tr('common.retry')),
                    ),
                  ] else if (!_loading && _items.isEmpty)
                    Text(context.tr('general_request.no_parts'))
                  else if (!_loading && _page < _lastPage)
                    TextButton(
                      onPressed: _load,
                      child: Text(context.tr('general_request.more_parts')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
