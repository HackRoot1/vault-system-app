import 'package:flutter/material.dart';

import '../features/login_screen/presentation/screens/login_screen.dart';
import '../features/splash_screen/presentation/screens/splash_screen.dart';
import '../widgets/vault_home_placeholder.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => switch (settings.name) {
        splash => const SplashScreen(),
        login => const LoginScreen(),
        home => const VaultHomePlaceholder(),
        _ => const SplashScreen(),
      },
    );
  }
}
