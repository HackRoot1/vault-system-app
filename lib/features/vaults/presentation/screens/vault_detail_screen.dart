import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/crypto/vault_crypto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../files/presentation/screens/files_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'vault_list_screen.dart';
import '../../data/models/vault_item_model.dart';
import '../../data/models/vault_list_model.dart';
import '../../data/repositories/vault_repository.dart';
import 'create_vault_item_screen.dart';
import 'vault_item_detail_screen.dart';
import '../widgets/vault_item_tile.dart';

class VaultDetailScreen extends StatefulWidget {
  const VaultDetailScreen({
    required this.vault,
    required this.token,
    required this.userName,
    required this.cryptoSalt,
    required this.cryptoIterations,
    super.key,
  });

  final VaultListModel vault;
  final String token;
  final String userName;
  final String cryptoSalt;
  final int cryptoIterations;

  @override
  State<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends State<VaultDetailScreen> {
  final _repository = VaultRepository();
  final TextEditingController _searchController = TextEditingController();

  List<VaultItemModel> _items = [];
  List<VaultItemModel> _filteredItems = [];
  bool _showSearchClear = false;
  bool _isDeleting = false;
  bool _isLoading = true;
  String? _errorMessage;
  SecretKey? _derivedKey;
  final Map<int, Map<String, dynamic>?> _decryptedCache = {};

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

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(
      () => _onSearchChanged(_searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getItems(widget.vault.id, widget.token);
      if (!mounted) return;
      setState(() {
        _items = items;
        _filteredItems = List.from(items);
        _isLoading = false;
      });

      if (_searchController.text.isNotEmpty) {
        _onSearchChanged(_searchController.text);
      }

      final mp = TokenStorage.getMasterPassword();
      if (mp != null && mp.isNotEmpty) {
        await _deriveAndDecryptAll(mp);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _showSearchClear = q.isNotEmpty;
      _filteredItems = q.isEmpty
          ? List.from(_items)
          : _items.where((item) {
              final payload = _decryptedCache[item.id];
              final title =
                  (payload?['title'] as String? ??
                          payload?['card_name'] as String? ??
                          item.type)
                      .toLowerCase();
              return title.contains(q) || item.type.toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _deriveAndDecryptAll(String masterPassword) async {
    try {
      final key = await VaultCrypto.deriveKey(
        masterPassword: masterPassword,
        saltHex: widget.cryptoSalt,
        iterations: widget.cryptoIterations,
      );
      if (!mounted) return;

      final cache = <int, Map<String, dynamic>?>{};
      for (final item in _items) {
        cache[item.id] = await item.decryptPayload(key);
        if (!mounted) return;
      }

      setState(() {
        _derivedKey = key;
        _decryptedCache
          ..clear()
          ..addAll(cache);
      });

      if (_searchController.text.isNotEmpty) {
        _onSearchChanged(_searchController.text);
      }
    } catch (_) {
      // Silent fail; user can manually trigger decrypt.
    }
  }

  Future<void> _promptAndDeriveKey() async {
    var masterPassword = TokenStorage.getMasterPassword();
    if (masterPassword == null || masterPassword.isEmpty) {
      masterPassword = await _showMasterPasswordDialog();
      if (!mounted) return;
      if (masterPassword == null) return;
    }
    TokenStorage.setMasterPassword(masterPassword);
    await TokenStorage.saveMasterPasswordSecure(masterPassword);
    await _deriveAndDecryptAll(masterPassword);
  }

  Future<String?> _showMasterPasswordDialog() async {
    final biometricEnabled = await TokenStorage.isBiometricEnabled();
    final biometricLabel = await TokenStorage.getBiometricLabel();
    final controller = TextEditingController();
    var obscure = true;
    var isAuthenticating = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, size: 18.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                'Master Password',
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
            children: [
              Text(
                'Enter your master password to decrypt this vault.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: TextStyle(fontSize: 13.sp, color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Master password',
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.secondaryText,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    border: InputBorder.none,
                    suffixIcon: GestureDetector(
                      onTap: () => setDialogState(() => obscure = !obscure),
                      child: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            if (biometricEnabled)
              TextButton(
                onPressed: isAuthenticating
                    ? null
                    : () async {
                        setDialogState(() => isAuthenticating = true);
                        try {
                          final authenticated =
                              await TokenStorage.authenticateBiometric(
                                reason: 'Unlock with $biometricLabel',
                              );
                          if (!authenticated) return;

                          final savedPassword =
                              await TokenStorage.getMasterPasswordSecure();
                          if (savedPassword == null || savedPassword.isEmpty) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No saved master password found.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(0xFFCC3333),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(16.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            );
                            return;
                          }

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, savedPassword);
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isAuthenticating = false);
                          }
                        }
                      },
                child: Text(
                  isAuthenticating ? 'Checking...' : biometricLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF8899AA),
                  ),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2255EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () {
                final password = controller.text;
                if (password.isEmpty) return;
                Navigator.pop(ctx, password);
              },
              child: Text(
                'Confirm',
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildItemList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18.sp, color: const Color(0xFF8899AA)),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          if (_showSearchClear)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
              child: Icon(
                Icons.close,
                size: 16.sp,
                color: const Color(0xFF8899AA),
              ),
            )
          else
            GestureDetector(
              onTap: _showFilterSheet,
              child: Icon(
                Icons.tune,
                size: 18.sp,
                color: const Color(0xFF8899AA),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) => const _ShimmerItemTile(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40.sp,
              color: const Color(0xFFCC3333),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8D8E8),
                foregroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 13.sp)),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 36.sp, color: const Color(0xFF8899AA)),
            SizedBox(height: 12.h),
            Text(
              'No items match "${_searchController.text}"',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF8899AA)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: const Color(0xFF8899AA),
            ),
            SizedBox(height: 16.h),
            Text(
              'No items yet',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Add your first encrypted item',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF8899AA)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF112240),
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
        itemCount: _filteredItems.length,
        itemBuilder: (context, i) {
          final item = _filteredItems[i];
          return GestureDetector(
            onTap: () => _navigateToDetail(item),
            child: VaultItemTile(
              item: item,
              decryptedPayload: _decryptedCache[item.id],
              onEditTap: () => _navigateToEdit(item),
              onDeleteTap: () {
                if (_isDeleting) return;
                _confirmDeleteItem(item);
              },
            ),
          );
        },
      ),
    );
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
            const Divider(color: Color(0x14FFFFFF)),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredItems.sort(
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
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredItems.sort((a, b) => a.type.compareTo(b.type));
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 18.sp,
                      color: const Color(0xFF8899AA),
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'By Type',
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
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredItems.sort(
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

  Future<void> _navigateToDetail(VaultItemModel item) async {
    final cryptoParams = await _getCryptoParamsOrRedirect();
    if (cryptoParams == null || !mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VaultItemDetailScreen(
              item: item,
              vault: widget.vault,
              token: widget.token,
              userName: widget.userName,
              cryptoSalt: cryptoParams.$1,
              cryptoIterations: cryptoParams.$2,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _confirmDeleteItem(VaultItemModel item) async {
    final typeLabel = _typeLabel(item.type);
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
              'Delete Item',
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
              'Are you sure you want to delete this item?',
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
              child: Row(
                children: [
                  Icon(
                    _typeIcon(item.type),
                    size: 16.sp,
                    color: const Color(0xFF8899AA),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
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
    await _deleteItem(item);
  }

  Future<void> _deleteItem(VaultItemModel item) async {
    setState(() => _isDeleting = true);

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
              'Deleting item...',
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF112240),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      await _repository.deleteItem(widget.vault.id, item.id, widget.token);

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
                'Item deleted successfully',
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
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _items.removeWhere((i) => i.id == item.id);
        _filteredItems.removeWhere((i) => i.id == item.id);
        _decryptedCache.remove(item.id);
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await _loadItems();
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

  Future<void> _navigateToEdit(VaultItemModel item) async {
    final salt = await TokenStorage.getCryptoSalt();
    if (!mounted) return;
    final iterations = await TokenStorage.getCryptoIterations();
    if (!mounted) return;

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
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateVaultItemScreen(
              token: widget.token,
              userName: widget.userName,
              cryptoSalt: salt,
              cryptoIterations: iterations,
              vaults: [widget.vault],
              preselectedVault: widget.vault,
              itemToEdit: item,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (mounted) await _loadItems();
  }

  String _typeLabel(String type) {
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

  IconData _typeIcon(String type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.vault.name,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              size: 20.sp,
              color: const Color(0xFF8899AA),
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: Icon(
              _derivedKey != null
                  ? Icons.lock_open_outlined
                  : Icons.lock_outline,
              size: 20.sp,
              color: _derivedKey != null
                  ? const Color(0xFF00FF88)
                  : AppColors.secondaryText,
            ),
            onPressed: _derivedKey != null
                ? () => setState(() {
                    _derivedKey = null;
                    _decryptedCache.clear();
                    if (_searchController.text.isNotEmpty) {
                      _onSearchChanged(_searchController.text);
                    }
                  })
                : _promptAndDeriveKey,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      bottomNavigationBar: VaultBottomNav(
        selectedIndex: 1,
        onTabChanged: (_) {},
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
          var vaults = <VaultListModel>[];
          try {
            vaults = await _repository.getVaults(widget.token);
          } catch (_) {}
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_items.length} item${_items.length == 1 ? '' : 's'}',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (_derivedKey == null && _items.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _promptAndDeriveKey,
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 12.sp,
                            color: AppColors.secondaryText,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Decrypt all',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11.sp,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}

class _ShimmerItemTile extends StatelessWidget {
  const _ShimmerItemTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(12.r),
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
}
