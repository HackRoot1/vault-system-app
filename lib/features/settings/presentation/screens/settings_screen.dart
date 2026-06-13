import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/download_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../files/presentation/screens/files_screen.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../../../vaults/presentation/screens/vault_list_screen.dart';
import '../../../vaults/data/repositories/vault_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.token,
    required this.userName,
    required this.userEmail,
    super.key,
  });

  final String token;
  final String userName;
  final String userEmail;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricsEnabled = false;
  bool _darkMode = true;
  String _autoLockTimer = '5 Minutes';
  final List<String> _autoLockOptions = const [
    '1 Minute',
    '5 Minutes',
    '15 Minutes',
    '30 Minutes',
    'Never',
  ];
  int _selectedNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadAutoLockPref();
  }

  Future<void> _loadAutoLockPref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('auto_lock_timer');
    if (!mounted) return;
    if (saved != null && _autoLockOptions.contains(saved)) {
      setState(() => _autoLockTimer = saved);
    }
  }

  Future<void> _saveAutoLockPref(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_lock_timer', value);
    debugPrint('SettingsScreen saved auto lock preference: $value');
  }

  Future<void> _handleLogout() async {
    await TokenStorage.clearSession();
    TokenStorage.setMasterPassword('');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  Future<void> _changeDownloadFolder() async {
    await DownloadStorage.clearDownloadDirectory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Download folder will be asked on next download.',
          style: TextStyle(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF112240),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon.',
          style: TextStyle(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF112240),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditProfilePlaceholder() => _showComingSoonSnackBar('Profile editing');

  void _showChangePasswordPlaceholder() =>
      _showComingSoonSnackBar('Change password');

  void _showLogoutAllPlaceholder() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF112240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Logout all devices requires a backend API endpoint that has not been provided yet.',
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF8899AA),
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2F4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(52.h),
      child: Container(
        color: AppColors.scaffoldBg,
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'VAULT',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.search, size: 20.sp, color: Colors.white),
                  SizedBox(width: 14.w),
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2F4A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2255EE).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 16.sp,
                      color: const Color(0xFF8899AA),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF8899AA)),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 10.sp,
              color: const Color(0xFF8899AA),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0x0AFFFFFF),
      margin: EdgeInsets.symmetric(vertical: 2.h),
    );
  }

  Widget _buildSettingsRow({
    IconData? icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0x0EFFFFFF)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20.sp, color: const Color(0xFF8899AA)),
              SizedBox(width: 14.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: titleColor ?? Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF8899AA),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F4A),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF2255EE).withOpacity(0.3),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Color(0xFF4488FF),
                  ),
                ),
              ),
              Positioned(
                bottom: 2.h,
                right: 2.w,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CC66),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.scaffoldBg,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'CLEARANCE LEVEL 5',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 9.sp,
                    color: const Color(0xFF8899AA),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditProfilePlaceholder,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2F4A),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0x20FFFFFF)),
              ),
              child: Text(
                'Edit',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF112240),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Are you sure you want to logout from this device?',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF8899AA),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF8899AA)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC3333),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleLogout();
              },
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0x0EFFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18.sp, color: const Color(0xFFCC3333)),
            SizedBox(width: 10.w),
            Text(
              'Logout This Device',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFFCC3333),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            _buildProfileCard(),
            SizedBox(height: 12.h),
            _buildSettingsRow(
              icon: Icons.alternate_email,
              title: 'Email Address',
              subtitle: widget.userEmail,
              trailing: Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: const Color(0xFF8899AA),
              ),
            ),
            SizedBox(height: 24.h),
            _buildSectionHeader(
              icon: Icons.security_outlined,
              label: 'SECURITY',
            ),
            SizedBox(height: 8.h),
            _buildSettingsRow(
              icon: Icons.lock_reset_outlined,
              title: 'Change Password',
              trailing: Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: const Color(0xFF8899AA),
              ),
              onTap: _showChangePasswordPlaceholder,
            ),
            _buildDivider(),
            _buildSettingsRow(
              icon: Icons.fingerprint_outlined,
              title: 'Enable Biometrics',
              subtitle: 'Touch ID / Face ID',
              trailing: Switch(
                value: _biometricsEnabled,
                onChanged: (value) {
                  setState(() => _biometricsEnabled = value);
                  _showComingSoonSnackBar('Biometric authentication');
                },
                activeColor: const Color(0xFF2255EE),
                activeTrackColor: const Color(0xFF2255EE).withOpacity(0.3),
                inactiveThumbColor: const Color(0xFF445566),
                inactiveTrackColor: const Color(0xFF1A2F4A),
              ),
            ),
            _buildDivider(),
            _buildSettingsRow(
              icon: Icons.timer_outlined,
              title: 'Auto-Lock Timer',
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _autoLockTimer,
                  dropdownColor: const Color(0xFF112240),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF8899AA),
                    size: 16.sp,
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF8899AA),
                  ),
                  items: _autoLockOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _autoLockTimer = value);
                    _saveAutoLockPref(value);
                  },
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _buildSettingsRow(
              icon: Icons.folder_outlined,
              title: 'Download Folder',
              subtitle: 'App managed folder',
              trailing: Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: const Color(0xFF8899AA),
              ),
              onTap: () async {
                await _changeDownloadFolder();
              },
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: _showLogoutAllPlaceholder,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1010),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFCC3333).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 18.sp, color: const Color(0xFFCC3333)),
                    SizedBox(width: 10.w),
                    Text(
                      'LOGOUT ALL DEVICES',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12.sp,
                        color: const Color(0xFFCC3333),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            _buildSectionHeader(
              icon: Icons.palette_outlined,
              label: 'APPEARANCE',
            ),
            SizedBox(height: 8.h),
            _buildSettingsRow(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  if (!value) {
                    _showComingSoonSnackBar('Light mode');
                  }
                },
                activeColor: const Color(0xFF2255EE),
                activeTrackColor: const Color(0xFF2255EE).withOpacity(0.3),
                inactiveThumbColor: const Color(0xFF445566),
                inactiveTrackColor: const Color(0xFF1A2F4A),
              ),
            ),
            _buildDivider(),
            _buildSettingsRow(
              icon: Icons.color_lens_outlined,
              title: 'Theme Color',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Vault Blue',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8899AA),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2255EE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4488FF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => _showComingSoonSnackBar('Theme customization'),
            ),
            SizedBox(height: 24.h),
            _buildSectionHeader(
              icon: Icons.info_outline,
              label: 'ABOUT',
            ),
            SizedBox(height: 8.h),
            _buildSettingsRow(
              title: 'App Version',
              titleColor: const Color(0xFF8899AA),
              trailing: Text(
                'v2.4.1 [STABLE]',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11.sp,
                  color: Colors.white,
                ),
              ),
            ),
            _buildDivider(),
            _buildSettingsRow(
              title: 'Privacy Policy',
              trailing: Icon(
                Icons.open_in_new,
                size: 16.sp,
                color: const Color(0xFF8899AA),
              ),
              onTap: () => _showComingSoonSnackBar('Privacy Policy'),
            ),
            _buildDivider(),
            _buildSettingsRow(
              title: 'Terms of Service',
              trailing: Icon(
                Icons.open_in_new,
                size: 16.sp,
                color: const Color(0xFF8899AA),
              ),
              onTap: () => _showComingSoonSnackBar('Terms of Service'),
            ),
            SizedBox(height: 32.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 24.sp,
                    color: const Color(0x33FFFFFF),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'SECURED BY VAULT DEFENSE SYSTEMS',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 9.sp,
                      color: const Color(0x33FFFFFF),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            _buildLogoutButton(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      bottomNavigationBar: VaultBottomNav(
        selectedIndex: _selectedNavIndex,
        onTabChanged: (index) => setState(() => _selectedNavIndex = index),
        onHomeTap: () => Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DashboardScreen(
              userName: widget.userName,
              token: widget.token,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        ),
        onVaultsTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                VaultListScreen(
              token: widget.token,
              userName: widget.userName,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        onFilesTap: () async {
          setState(() => _selectedNavIndex = 2);
          List<VaultListModel> vaults = [];
          try {
            vaults = await VaultRepository().getVaults(widget.token);
          } catch (_) {}
          if (!mounted) return;
          Navigator.of(context)
              .push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FilesScreen(
                    token: widget.token,
                    userName: widget.userName,
                    vaults: vaults,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              )
              .then((_) {
                if (mounted) setState(() => _selectedNavIndex = 3);
              });
        },
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
}
