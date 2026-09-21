import 'package:flutter/material.dart';
import 'package:sahala/core/routing/app_router.dart';
import 'package:sahala/core/routing/app_routes.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:sahala/core/service/firebase_messaging_service.dart';
import 'package:sahala/core/service/local_storage_service.dart';
import 'package:sahala/core/theme/app_theme.dart';
import 'package:sahala/dependency_injection.dart';
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
  setup();

  await sl<LocalStorageService>().initialize();
  await sl<FirebaseMessagingService>().initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _routeObserver = AppRouteObserver();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorObservers: [_routeObserver],
      // initialRoute: AppRoutes.login.path,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
