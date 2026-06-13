import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? AppColors.scaffoldBg : AppColors.primaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primaryText
              : AppColors.primaryText.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10.r),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppColors.primaryText.withValues(alpha: 0.08),
                  width: 1.w,
                ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: foreground),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
