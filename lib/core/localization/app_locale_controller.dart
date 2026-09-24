import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'app_locale.dart';

final appLocaleProvider = NotifierProvider<AppLocaleController, AppLocale>(
  AppLocaleController.new,
);

class AppLocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() => ref.watch(appStorageProvider).cachedLocale;

  Future<void> select(AppLocale locale) async {
    if (state == locale) return;

    state = locale;
    await ref.read(appStorageProvider).saveLocale(locale);
  }

  Future<void> toggle() => select(state.alternate);
}
