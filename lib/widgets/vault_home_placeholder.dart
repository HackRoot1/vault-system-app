import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

class VaultHomePlaceholder extends StatelessWidget {
  const VaultHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.vaultNavy,
      body: Center(
        child: Text(
          AppConstants.appName,
          style: TextStyle(
            color: AppColors.vaultText,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
