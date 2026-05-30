import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.loginButtonBackground,
        brightness: Brightness.dark,
        surface: AppColors.cardBackground,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryText,
      ),
    );
  }
}
