import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: VaultSystemApp()));
}

class VaultSystemApp extends StatelessWidget {
  const VaultSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
