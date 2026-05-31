import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/vault_model.dart';

class RecentVaultCard extends StatelessWidget {
  const RecentVaultCard({required this.vault, super.key});

  final VaultModel vault;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.07),
          width: 1.w,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(vault.icon, size: 20.sp, color: AppColors.secondaryText),
              SizedBox(height: 24.h),
              Text(
                vault.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Last accessed: ${vault.lastAccessed}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: AppColors.statusDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    vault.status,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.statusDot,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.shield_outlined,
              size: 16.sp,
              color: AppColors.primaryText.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
