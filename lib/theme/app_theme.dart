import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.vaultNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.vaultText,
        surface: AppColors.vaultNavy,
        error: Color(0xFFFFB4AB),
      ),
      fontFamily: 'Times New Roman',
    );
  }
}
