import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class VaultLoginButton extends StatelessWidget {
  const VaultLoginButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.verified_user_outlined,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.loginButtonBackground,
          foregroundColor: AppColors.loginButtonText,
          disabledBackgroundColor: AppColors.loginButtonBackground,
          disabledForegroundColor: AppColors.loginButtonText,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.buttonLabel),
            SizedBox(width: 8.w),
            Icon(icon, size: 18.sp),
          ],
        ),
      ),
    );
  }
}
