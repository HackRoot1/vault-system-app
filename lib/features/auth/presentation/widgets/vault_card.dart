import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class VaultCard extends StatelessWidget {
  const VaultCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      width: (screenWidth * 0.88).clamp(0, 420.w),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            blurRadius: 24.r,
            color: Colors.black38,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: child,
    );
  }
}
