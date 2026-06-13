import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../files/presentation/screens/files_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../data/models/vault_list_model.dart';
import '../../data/repositories/vault_repository.dart';
import 'create_vault_screen.dart';
import '../widgets/vault_list_tile.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({
    required this.token,
    required this.userName,
    super.key,
  });

  final String token;
  final String userName;

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> {
  final _repository = VaultRepository();
  final _searchController = TextEditingController();

  List<VaultListModel> _allVaults = [];
  List<VaultListModel> _filteredVaults = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;
  bool _showSearchClear = false;

  @override
  void initState() {
    super.initState();
    _loadVaults();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _showSearchClear = q.isNotEmpty;
      _filteredVaults = q.isEmpty
          ? List.from(_allVaults)
          : _allVaults
                .where((vault) => vault.name.toLowerCase().contains(q))
                .toList();
    });
  }

  Future<void> _loadVaults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vaults = await _repository.getVaults(widget.token);
      if (!mounted) return;
      setState(() {
        _allVaults = vaults;
        _filteredVaults = List.from(vaults);
        _isLoading = false;
      });
      _onSearchChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(52.h),
      child: Container(
        color: AppColors.scaffoldBg,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Personal Vault',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: Colors.white, size: 22.sp),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18.sp, color: AppColors.secondaryText),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search vault items...',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          if (_showSearchClear)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
              child: Icon(
                Icons.close,
                size: 16.sp,
                color: AppColors.secondaryText,
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showFilterSheet,
              child: Icon(
                Icons.tune,
                size: 18.sp,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) => const _ShimmerTile(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
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
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadVaults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.loginButtonBackground,
                  foregroundColor: AppColors.loginButtonText,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
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

    if (_filteredVaults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 36.sp,
                color: AppColors.secondaryText,
              ),
              SizedBox(height: 12.h),
              Text(
                'No vaults match "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allVaults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_open_outlined,
              size: 48.sp,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 16.h),
            Text(
              'No vaults yet',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Tap the + button to create your first vault',
              style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _loadVaults,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
        itemCount: _filteredVaults.length,
        itemBuilder: (context, index) {
          final vault = _filteredVaults[index];
          return VaultListTile(
            vault: vault,
            token: widget.token,
            userName: widget.userName,
            onCopy: () => _copyVaultName(vault),
            onToggleFavorite: () => _toggleFavorite(vault),
            onMoreTap: () => _showVaultOptions(vault),
          );
        },
      ),
    );
  }

  void _copyVaultName(VaultListModel vault) {
    Clipboard.setData(ClipboardData(text: vault.name));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vault name copied',
          style: TextStyle(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A6B3A),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(VaultListModel vault) {
    setState(() => vault.isFavorited = !vault.isFavorited);
  }

  Future<void> _navigateToEdit(VaultListModel vault) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateVaultScreen(
              token: widget.token,
              userName: widget.userName,
              vaultToEdit: vault,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (mounted) await _loadVaults();
  }

  void _showVaultOptions(VaultListModel vault) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 16.h),
              Text(
                vault.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Created ${_formatDate(vault.createdAt)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 16.h),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              _OptionRow(
                icon: Icons.edit_outlined,
                label: 'Edit Vault',
                color: AppColors.secondaryText,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEdit(vault);
                },
              ),
              _OptionRow(
                icon: Icons.copy_outlined,
                label: 'Copy Name',
                color: AppColors.secondaryText,
                onTap: () {
                  Navigator.pop(context);
                  _copyVaultName(vault);
                },
              ),
              _OptionRow(
                icon: Icons.delete_outline,
                label: 'Delete Vault',
                color: const Color(0xFFCC3333),
                onTap: () {
                  if (_isDeleting) return;
                  Navigator.pop(context);
                  _confirmDelete(vault);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(VaultListModel vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF112240),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 20.sp,
              color: const Color(0xFFCC3333),
            ),
            SizedBox(width: 8.w),
            Text(
              'Delete Vault',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete:',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF8899AA)),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Text(
                vault.name,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'This will permanently delete the vault and all its contents. '
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFFCC3333),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF8899AA)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCC3333),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteVault(vault);
  }

  Future<void> _deleteVault(VaultListModel vault) async {
    setState(() => _isDeleting = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 14.w,
                height: 14.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Deleting vault...',
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF112240),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }

    try {
      await _repository.deleteVault(vault.id, widget.token);
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '"${vault.name}" deleted successfully',
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A6B3A),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _allVaults.removeWhere((v) => v.id == vault.id);
        _filteredVaults.removeWhere((v) => v.id == vault.id);
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await _loadVaults();
      if (!mounted) return;
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  e.message,
                  style: TextStyle(fontSize: 13.sp, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFCC3333),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF112240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Divider(color: const Color(0x14FFFFFF)),
            SizedBox(height: 8.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredVaults.sort(
                    (a, b) => DateTime.parse(
                      b.createdAt,
                    ).compareTo(DateTime.parse(a.createdAt)),
                  );
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 18.sp,
                      color: const Color(0xFF8899AA),
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'Most Recent',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredVaults.sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 18.sp,
                      color: const Color(0xFF8899AA),
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'Alphabetical',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredVaults.sort(
                    (a, b) => DateTime.parse(
                      a.createdAt,
                    ).compareTo(DateTime.parse(b.createdAt)),
                  );
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 18.sp,
                      color: const Color(0xFF8899AA),
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'Oldest First',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      bottomNavigationBar: VaultBottomNav(
        selectedIndex: 1,
        onTabChanged: (i) {},
        onHomeTap: () {
          Navigator.of(context).pushAndRemoveUntil(
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
          );
        },
        onVaultsTap: () => setState(() {}),
        onFilesTap: () async {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FilesScreen(
                    token: widget.token,
                    userName: widget.userName,
                    vaults: _allVaults,
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
          if (!context.mounted) return;
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
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 120.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shimmerBox(20.w, 20.w),
              SizedBox(width: 8.w),
              _shimmerBox(20.w, 20.w),
              SizedBox(width: 8.w),
              _shimmerBox(20.w, 20.w),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
