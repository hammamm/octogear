import 'package:flutter/material.dart';
import 'package:sahala/core/routing/app_router.dart';
import 'package:sahala/core/routing/app_routes.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:sahala/core/service/firebase_messaging_service.dart';
import 'package:sahala/core/theme/app_theme.dart';
import 'package:sahala/dependency_injection.dart';
import 'package:sahala/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppLogger.initialize();
  AppLogger.installErrorHandlers();
  setup();

  await sl<FirebaseMessagingService>().initialize();

  runApp(const ProviderScope(child: MyApp()));
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
      navigatorObservers: [_routeObserver],
      // initialRoute: AppRoutes.login.path,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
