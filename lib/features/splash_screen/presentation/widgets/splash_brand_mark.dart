import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/vault_lock_icon.dart';

class SplashBrandMark extends StatelessWidget {
  const SplashBrandMark({required this.size, super.key});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final width = size.width;
    final height = size.height;
    final titleSize = (width * 0.074).clamp(36.0, 54.0);
    final subtitleSize = (width * 0.032).clamp(15.0, 23.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: height * 0.394, child: const VaultLockIcon()),
        Positioned(
          top: height * 0.543,
          left: width * 0.06,
          right: width * 0.06,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.appName.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.vaultText,
                fontFamily: 'Times New Roman',
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 6.5,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 0,
                    color: AppColors.vaultBlack,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: height * 0.596,
          left: width * 0.08,
          right: width * 0.08,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.splashTagline.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.vaultMuted,
                fontSize: subtitleSize,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 7.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
