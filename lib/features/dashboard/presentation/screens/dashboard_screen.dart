import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../../../vaults/data/repositories/vault_repository.dart';
import '../../../vaults/presentation/screens/create_vault_item_screen.dart';
import '../../../vaults/presentation/screens/create_vault_screen.dart';
import '../../../vaults/presentation/screens/vault_detail_screen.dart';
import '../../../vaults/presentation/screens/vault_item_detail_screen.dart';
import '../../../vaults/presentation/screens/vault_list_screen.dart';
import '../../../files/presentation/screens/files_screen.dart';
import '../../../files/presentation/screens/upload_file_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/recent_item_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../widgets/quick_action_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.userName,
    required this.token,
    this.repository,
    super.key,
  });

  final String userName;
  final String token;
  final DashboardRepository? repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRepository _repository;

  DashboardStats? _stats;
  bool _isLoading = true;
  bool _recentLoading = true;
  String? _errorMessage;
  int _selectedNavIndex = 0;
  List<VaultListModel> _recentVaults = [];
  List<RecentItemModel> _recentItems = [];
  List<dynamic> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DashboardRepository();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _recentLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getDashboard(widget.token),
        _repository.getRecentVaults(widget.token),
        _repository.getRecentItems(widget.token),
        _repository.getRecentFiles(widget.token),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as DashboardStats;
        _recentVaults = results[1] as List<VaultListModel>;
        _recentItems = results[2] as List<RecentItemModel>;
        _recentFiles = results[3] as List<dynamic>;
        _isLoading = false;
        _recentLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _recentLoading = false;
      });
    }
  }

  void _showSearchOverlay() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) =>
          _SearchOverlay(items: _recentItems, recentFiles: _recentFiles),
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

  Future<(String, int)?> _getCryptoParamsOrRedirect() async {
    final salt = await TokenStorage.getCryptoSalt();
    if (!mounted) return null;
    if (salt == null || salt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session expired. Please log in again.',
            style: TextStyle(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFCC3333),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
      return null;
    }

    final iterations = await TokenStorage.getCryptoIterations();
    if (!mounted) return null;
    return (salt, iterations);
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: Container(
        color: AppColors.scaffoldBg,
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
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
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        icon: Icons.crop_square_outlined,
                        label: 'VAULTS',
                        value: '${_stats?.totalVaults ?? 0}',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildKpiCard(
                        icon: Icons.shield_outlined,
                        label: 'ITEMS',
                        value: '${_stats?.totalItems ?? 0}',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildKpiCard(
                        icon: Icons.insert_drive_file_outlined,
                        label: 'FILES',
                        value: '${_stats?.totalFiles ?? 0}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            _QuickActionsSection(
              token: widget.token,
              userName: widget.userName,
              recentVaults: _recentVaults,
            ),
            SizedBox(height: 24.h),
            _buildRecentVaultsSection(),
            SizedBox(height: 24.h),
            _buildRecentItemsSection(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: const Color(0xFF8899AA)),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 8.sp,
              letterSpacing: 1.2,
              color: const Color(0xFF8899AA),
            ),
          ),
          SizedBox(height: 3.h),
          if (_isLoading)
            Container(
              width: 32.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(4.r),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentVaultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Vaults',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextButton(
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
            ],
          ),
        ),
        SizedBox(height: 10.h),
        if (_recentLoading)
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 3,
              itemBuilder: (context, index) => _buildShimmerVaultCard(),
            ),
          )
        else if (_recentVaults.isEmpty)
          _buildEmptyState(
            icon: Icons.lock_outline,
            title: 'No vaults yet',
            subtitle: 'Create your first vault to get started',
            actionLabel: 'Create Vault',
            onAction: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CreateVaultScreen(
                      token: widget.token,
                      userName: widget.userName,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
          )
        else
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _recentVaults.length,
              itemBuilder: (_, index) {
                final vault = _recentVaults[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final cryptoParams = await _getCryptoParamsOrRedirect();
                    if (cryptoParams == null || !mounted) return;
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            VaultDetailScreen(
                              vault: vault,
                              token: widget.token,
                              userName: widget.userName,
                              cryptoSalt: cryptoParams.$1,
                              cryptoIterations: cryptoParams.$2,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: _buildRecentVaultCard(vault),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Recently Added Items',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        if (_recentLoading)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: List.generate(3, (_) => _buildShimmerItemTile()),
            ),
          )
        else if (_recentItems.isEmpty)
          _buildEmptyState(
            icon: Icons.vpn_key_outlined,
            title: 'No items yet',
            subtitle: 'Add your first secure item to a vault',
            actionLabel: 'Add Item',
            onAction: () async {
              var vaults = _recentVaults;
              if (vaults.isEmpty) {
                try {
                  vaults = await VaultRepository().getVaults(widget.token);
                } catch (_) {}
                if (!mounted) return;
              }
              final cryptoParams = await _getCryptoParamsOrRedirect();
              if (cryptoParams == null || !mounted) return;
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CreateVaultItemScreen(
                        token: widget.token,
                        userName: widget.userName,
                        cryptoSalt: cryptoParams.$1,
                        cryptoIterations: cryptoParams.$2,
                        vaults: vaults,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          )
        else
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentItems.length,
              itemBuilder: (_, index) {
                final item = _recentItems[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final vault = _recentVaults.firstWhere(
                      (v) => v.id == item.vaultId,
                      orElse: () => VaultListModel(
                        id: item.vaultId,
                        name: 'Vault #${item.vaultId}',
                        createdAt: '',
                        updatedAt: '',
                      ),
                    );
                    final cryptoParams = await _getCryptoParamsOrRedirect();
                    if (cryptoParams == null || !mounted) return;
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            VaultItemDetailScreen(
                              item: item.toVaultItemModel(),
                              vault: vault,
                              token: widget.token,
                              userName: widget.userName,
                              cryptoSalt: cryptoParams.$1,
                              cryptoIterations: cryptoParams.$2,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: _buildRecentItemTile(item),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentVaultCard(VaultListModel vault) {
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0x12FFFFFF)),
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
              SizedBox(height: 16.h),
              Expanded(
                child: Text(
                  vault.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 8.h),
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
              color: const Color(0x26FFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerVaultCard() {
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: 80.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: 50.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemTile(RecentItemModel item) {
    final typeLabel = _itemTypeLabel(item.type);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _itemTypeIcon(item.type),
              size: 18.sp,
              color: const Color(0xFF8899AA),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Vault #${item.vaultId} - ${_timeAgo(item.createdAt)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF8899AA),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18.sp,
            color: const Color(0xFF8899AA),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItemTile() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                width: 70.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36.sp, color: const Color(0xFF445566)),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF8899AA)),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 16.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8D8E8),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ),
          ],
        ],
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
          Navigator.of(context).pushAndRemoveUntil(
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
            (route) => false,
          );
        },
        onFilesTap: () async {
          var vaults = _recentVaults;
          if (vaults.isEmpty) {
            try {
              vaults = await VaultRepository().getVaults(widget.token);
            } catch (_) {}
          }
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
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
            (route) => false,
          );
        },
        onSettingsTap: () async {
          final email = await TokenStorage.getUserEmail() ?? '';
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  SettingsScreen(
                    token: widget.token,
                    userName: widget.userName,
                    userEmail: email,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (route) => false,
          );
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

  Future<(String, int)?> _getCryptoParamsOrRedirect(
    BuildContext context,
  ) async {
    final salt = await TokenStorage.getCryptoSalt();
    if (!context.mounted) return null;
    if (salt == null || salt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session expired. Please log in again.',
            style: TextStyle(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFCC3333),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
      return null;
    }

    final iterations = await TokenStorage.getCryptoIterations();
    if (!context.mounted) return null;
    return (salt, iterations);
  }

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
                if (!context.mounted) return;
              }

              final cryptoParams = await _getCryptoParamsOrRedirect(context);
              if (cryptoParams == null || !context.mounted) return;

              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CreateVaultItemScreen(
                        token: token,
                        userName: userName,
                        cryptoSalt: cryptoParams.$1,
                        cryptoIterations: cryptoParams.$2,
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
          QuickActionButton(
            icon: Icons.upload_file_outlined,
            label: 'Upload File',
            onTap: () => navigateToUploadFileScreen(
              context,
              token: token,
              userName: userName,
              vaults: recentVaults,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({required this.items, required this.recentFiles});

  final List<RecentItemModel> items;
  final List<dynamic> recentFiles;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items
        .where(
          (item) =>
              _itemTypeLabel(
                item.type,
              ).toLowerCase().contains(_query.toLowerCase()) ||
              'vault #${item.vaultId}'.contains(_query.toLowerCase()),
        )
        .toList();
    final recentFileCount = widget.recentFiles.length;

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
                        recentFileCount > 0
                            ? 'Start typing to search items and files...'
                            : 'Start typing to search...',
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
                        return _SearchRecentItemTile(
                          item: filteredItems[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRecentItemTile extends StatelessWidget {
  const _SearchRecentItemTile({required this.item});

  final RecentItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(
            _itemTypeIcon(item.type),
            size: 18.sp,
            color: const Color(0xFF8899AA),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _itemTypeLabel(item.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _itemTypeLabel(String type) {
  switch (type) {
    case 'login':
      return 'Login Credential';
    case 'secure_note':
      return 'Secure Note';
    case 'credit_card':
      return 'Credit Card';
    default:
      return 'Vault Item';
  }
}

IconData _itemTypeIcon(String type) {
  switch (type) {
    case 'login':
      return Icons.login_outlined;
    case 'secure_note':
      return Icons.note_outlined;
    case 'credit_card':
      return Icons.credit_card_outlined;
    default:
      return Icons.lock_outline;
  }
}

String _timeAgo(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
