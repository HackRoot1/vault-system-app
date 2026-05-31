import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../vaults/presentation/screens/create_vault_item_screen.dart';
import '../../../vaults/presentation/screens/create_vault_screen.dart';
import '../../../vaults/presentation/screens/vault_list_screen.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/recent_item_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../../../vaults/data/repositories/vault_repository.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_item_tile.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.userName,
    required this.token,
    super.key,
  });

  final String userName;
  final String token;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = DashboardRepository();

  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedNavIndex = 0;
  List<VaultListModel> _recentApiVaults = [];

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
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _repository.getDashboard(widget.token);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });

      try {
        final vaults = await VaultRepository().getVaults(widget.token);
        if (!mounted) return;
        setState(() => _recentApiVaults = vaults.take(3).toList());
      } catch (_) {
        // Recent vaults are a convenience; don't fail the dashboard for them.
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _showSearchOverlay() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _SearchOverlay(items: _recentItems),
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF112240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 22.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stats?.user.name ?? widget.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          _stats?.user.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF8899AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              SizedBox(height: 12.h),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleLogout,
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      size: 18.sp,
                      color: const Color(0xFFCC3333),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFFCC3333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context);
    await TokenStorage.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(52.h),
      child: Container(
        color: const Color(0xFF0D1B2A),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    'Secure Vault',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showSearchOverlay,
                    child: Icon(Icons.search, size: 20.sp, color: Colors.white),
                  ),
                  SizedBox(width: 16.w),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showAccountSheet,
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 22.sp,
                      color: Colors.white,
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

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40.sp,
                color: const Color(0xFFCC3333),
              ),
              SizedBox(height: 12.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8D8E8),
                  foregroundColor: const Color(0xFF0D1B2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF112240),
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeBanner(userName: _stats?.user.name ?? widget.userName),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.crop_square_outlined,
                      label: 'VAULTS',
                      value: '${_stats?.totalVaults ?? 0}',
                      isLoading: _isLoading,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      icon: Icons.shield_outlined,
                      label: 'ITEMS',
                      value: '${_stats?.totalItems ?? 0}',
                      isLoading: _isLoading,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'FILES',
                      value: '${_stats?.totalFiles ?? 0}',
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            _QuickActionsSection(
              token: widget.token,
              userName: widget.userName,
              recentVaults: _recentApiVaults,
            ),
            SizedBox(height: 24.h),
            _SectionHeader(
              title: 'Recent Vaults',
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
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
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8899AA),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF8899AA),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (_recentApiVaults.isEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF112240),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No vaults yet',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8899AA),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 148.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _recentApiVaults.length,
                  itemBuilder: (context, index) {
                    final vault = _recentApiVaults[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  VaultListScreen(
                                    token: widget.token,
                                    userName: widget.userName,
                                  ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                      child: Container(
                        width: 148.w,
                        margin: EdgeInsets.only(right: 12.w),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF112240),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 20.sp,
                                  color: const Color(0xFF8899AA),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  vault.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Container(
                                      width: 6.w,
                                      height: 6.w,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00FF88),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      'Secure',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: const Color(0xFF00FF88),
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
                                size: 14.sp,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 24.h),
            const _SectionHeader(title: 'Recently Added Items'),
            SizedBox(height: 8.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF112240),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: VaultBottomNav(
        selectedIndex: _selectedNavIndex,
        onTabChanged: (i) => setState(() => _selectedNavIndex = i),
        onHomeTap: () => setState(() => _selectedNavIndex = 0),
        onVaultsTap: () {
          setState(() => _selectedNavIndex = 1);
          Navigator.of(context)
              .push(
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
              )
              .then((_) {
                if (mounted) setState(() => _selectedNavIndex = 0);
              });
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2F4A), Color(0xFF112240)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 11.sp,
                    letterSpacing: 1,
                    color: const Color(0xFF8899AA),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF88),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Vault Secured',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10.sp,
                        color: const Color(0xFF00FF88),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 22.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.token,
    required this.userName,
    required this.recentVaults,
  });

  final String token;
  final String userName;
  final List<VaultListModel> recentVaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10.sp,
              letterSpacing: 2,
              color: const Color(0xFF8899AA),
            ),
          ),
          SizedBox(height: 14.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CreateVaultScreen(token: token, userName: userName),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            ),
            child: const IgnorePointer(
              child: QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add Vault',
                isPrimary: true,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              var vaults = recentVaults;
              if (vaults.isEmpty) {
                try {
                  vaults = await VaultRepository().getVaults(token);
                } catch (_) {}
              }

              final salt = await TokenStorage.getCryptoSalt() ?? '';
              final iterations =
                  await TokenStorage.getCryptoIterations() ?? 100000;

              if (!context.mounted) return;

              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CreateVaultItemScreen(
                        token: token,
                        userName: userName,
                        cryptoSalt: salt,
                        cryptoIterations: iterations,
                        vaults: vaults,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: const IgnorePointer(
              child: QuickActionButton(
                icon: Icons.vpn_key_outlined,
                label: 'Add Item',
              ),
            ),
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
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({required this.items});

  final List<RecentItemModel> items;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items
        .where(
          (item) => item.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: const Color(0xFF112240),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 18.sp,
                    color: const Color(0xFF8899AA),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      style: TextStyle(fontSize: 13.sp, color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Search vaults, items, files...',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF8899AA),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF8899AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Text(
                        'Start typing to search...',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF8899AA),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return RecentItemTile(item: filteredItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
