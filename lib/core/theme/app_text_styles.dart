import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get title => GoogleFonts.playfairDisplay(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 3.w,
    color: AppColors.primaryText,
  );

  static TextStyle get subtitle => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  static TextStyle get fieldLabel => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  static TextStyle get fieldText =>
      TextStyle(fontSize: 13.sp, color: AppColors.primaryText);

  static TextStyle get fieldHint =>
      TextStyle(fontSize: 13.sp, color: AppColors.secondaryText);

  static TextStyle get actionText =>
      TextStyle(fontSize: 12.sp, color: AppColors.secondaryText);

  static TextStyle get buttonLabel => TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2.w,
  );

  static TextStyle get registerMuted =>
      TextStyle(fontSize: 13.sp, color: AppColors.secondaryText);

  static TextStyle get registerLink => TextStyle(
    fontSize: 13.sp,
    color: AppColors.primaryText,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get status => TextStyle(
    fontFamily: 'monospace',
    fontSize: 10.sp,
    color: AppColors.secondaryText,
    letterSpacing: 0.8.w,
  );
}
