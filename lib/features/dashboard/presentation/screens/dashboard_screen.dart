import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/recent_item_model.dart';
import '../../data/models/vault_model.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_item_tile.dart';
import '../widgets/recent_vault_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.userName,
    required this.token,
    super.key,
  });

  final String userName;
  final String token;

  final DashboardStats _stats = const DashboardStats(
    totalVaults: 12,
    totalItems: 84,
    totalFiles: 256,
  );

  final List<VaultModel> _recentVaults = const [
    VaultModel(
      name: 'Personal',
      lastAccessed: '2m ago',
      status: 'Secure',
      icon: Icons.person_outline,
    ),
    VaultModel(
      name: 'Work',
      lastAccessed: '1h ago',
      status: 'Secure',
      icon: Icons.work_outline,
    ),
    VaultModel(
      name: 'Backups',
      lastAccessed: '3h ago',
      status: 'Secure',
      icon: Icons.backup_outlined,
    ),
  ];

  final List<RecentItemModel> _recentItems = const [
    RecentItemModel(
      title: 'GitHub Credentials',
      subtitle: 'Modified: 15 mins ago • Vault: Personal',
      icon: Icons.login_outlined,
    ),
    RecentItemModel(
      title: 'Tax_2023.pdf',
      subtitle: 'Added: 2 hours ago • Vault: Secure Backups',
      icon: Icons.picture_as_pdf_outlined,
    ),
    RecentItemModel(
      title: 'API_KEY_PRODUCTION',
      subtitle: 'Added: 5 hours ago • Vault: Work',
      icon: Icons.key_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const _DashboardAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BlurredBanner(),
                    StatCard(
                      icon: Icons.crop_square_outlined,
                      label: 'TOTAL VAULTS',
                      value: _stats.totalVaults.toString(),
                    ),
                    StatCard(
                      icon: Icons.shield_outlined,
                      label: 'TOTAL ITEMS',
                      value: _stats.totalItems.toString(),
                    ),
                    StatCard(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'TOTAL FILES',
                      value: _stats.totalFiles.toString(),
                    ),
                    SizedBox(height: 20.h),
                    const _QuickActionsSection(),
                    SizedBox(height: 24.h),
                    _SectionHeader(
                      title: 'Recent Vaults',
                      trailing: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryText,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 160.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _recentVaults.length,
                        itemBuilder: (context, index) {
                          return RecentVaultCard(vault: _recentVaults[index]);
                        },
                      ),
                    ),
                    SizedBox(height: 28.h),
                    const _SectionHeader(title: 'Recently Added Items'),
                    SizedBox(height: 8.h),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentItems.length,
                        itemBuilder: (context, index) {
                          return RecentItemTile(item: _recentItems[index]);
                        },
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar();

  void _showAccountActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: AppColors.primaryText,
                size: 20.sp,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await TokenStorage.clearSession();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: Row(
        children: [
          SizedBox(width: 12.w),
          Icon(
            Icons.shield_outlined,
            size: 18.sp,
            color: AppColors.primaryText,
          ),
          SizedBox(width: 6.w),
          Text(
            'Secure Vault',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: AppColors.primaryText, size: 20.sp),
          ),
          IconButton(
            onPressed: () => _showAccountActions(context),
            icon: Icon(
              Icons.account_circle_outlined,
              color: AppColors.primaryText,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}

class _BlurredBanner extends StatelessWidget {
  const _BlurredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primaryText.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.06),
          width: 1.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.r, sigmaY: 10.r),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10.sp,
              letterSpacing: 2.w,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: 14.h),
          const QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Add Vault',
            isPrimary: true,
          ),
          const QuickActionButton(
            icon: Icons.vpn_key_outlined,
            label: 'Add Item',
          ),
          const QuickActionButton(
            icon: Icons.upload_file_outlined,
            label: 'Upload File',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
