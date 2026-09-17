import 'package:flutter/material.dart';
import 'package:sahala/features/authentication/presentation/screens/login_screen.dart';
import 'package:sahala/features/authentication/presentation/screens/otp_screen.dart';
import 'package:sahala/features/home/Presentation/home.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/otp':
        return MaterialPageRoute(
          builder: (_) => const OTPScreen(),
          settings: settings,
        );
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
