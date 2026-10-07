import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/general_request.dart';
import '../controllers/request_components_controller.dart';

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
  Timer? _debounce;
  String _query = '';
  bool _debouncing = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _queryChanged(String _) {
    _debounce?.cancel();
    setState(() => _debouncing = true);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _query = _search.text.trim();
        _debouncing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = requestComponentsProvider(_query);
    final state = ref.watch(provider);
    final current = state.asData?.value;
    final List<RequestComponent> items = _debouncing
        ? const []
        : current?.page.items ?? const [];
    final loading =
        _debouncing || state.isLoading || current?.loadingMore == true;
    final failed = !_debouncing && (state.hasError || current?.error != null);
    void retry() {
      if (current == null) {
        ref.invalidate(provider);
      } else {
        ref.read(provider.notifier).loadMore();
      }
    }

    return Padding(
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
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
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
                    for (final item in items)
                      ListTile(
                        key: ValueKey('catalog-part-${item.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.pop(context, item),
                      ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (failed) ...[
                      Text(context.tr('general_request.catalog_error')),
                      TextButton(
                        onPressed: retry,
                        child: Text(context.tr('common.retry')),
                      ),
                    ] else if (!loading && items.isEmpty)
                      Text(context.tr('general_request.no_parts'))
                    else if (!loading &&
                        current != null &&
                        current.page.page < current.page.lastPage)
                      TextButton(
                        onPressed: () => ref.read(provider.notifier).loadMore(),
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
}
