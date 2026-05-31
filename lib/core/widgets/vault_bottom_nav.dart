import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VaultBottomNav extends StatelessWidget {
  const VaultBottomNav({
    required this.selectedIndex,
    required this.onTabChanged,
    this.onHomeTap,
    this.onVaultsTap,
    this.onFilesTap,
    this.onSettingsTap,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onHomeTap;
  final VoidCallback? onVaultsTap;
  final VoidCallback? onFilesTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF112240),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: onHomeTap ?? () => onTabChanged(0),
            ),
            _NavItem(
              icon: Icons.lock_outline,
              activeIcon: Icons.lock,
              label: 'Vaults',
              isSelected: selectedIndex == 1,
              onTap: onVaultsTap ?? () => onTabChanged(1),
            ),
            _NavItem(
              icon: Icons.insert_drive_file_outlined,
              activeIcon: Icons.insert_drive_file,
              label: 'Files',
              isSelected: selectedIndex == 2,
              onTap: onFilesTap ?? () => onTabChanged(2),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              isSelected: selectedIndex == 3,
              onTap: onSettingsTap ?? () => onTabChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Icon(
              isSelected ? activeIcon : icon,
              size: 22.sp,
              color: isSelected ? Colors.white : const Color(0xFF8899AA),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sourceCodePro(
                fontSize: 7.sp,
                color: isSelected ? Colors.white : const Color(0xFF8899AA),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }
}
