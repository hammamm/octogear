import 'package:flutter/material.dart';
import 'package:sahala/app/octogear_app.dart';
import 'package:sahala/core/localization/app_locale.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:sahala/core/storage/app_storage.dart';
import 'package:sahala/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Required for locale-aware patterns (e.g. AppDateFormat.dayName's
  // "EEEE") used via String.formattedDate/toDate - package:intl throws
  // LocaleDataException otherwise.
  await initializeDateFormatting('en');
  await initializeDateFormatting('ar');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppLogger.initialize();
  AppLogger.installErrorHandlers();

  final octoGearStorage = AppStorage();
  await octoGearStorage.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: AppLocale.arabic.locale,
      startLocale: octoGearStorage.cachedLocale.locale,
      saveLocale: false,
      child: ProviderScope(
        overrides: [appStorageProvider.overrideWithValue(octoGearStorage)],
        child: const OctoGearApp(),
      ),
    ),
  );
}
