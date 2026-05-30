import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  runApp(const VaultSystemApp());
}

class VaultSystemApp extends StatelessWidget {
  const VaultSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Vault System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}
