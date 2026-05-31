import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/crypto/vault_crypto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/vault_item_model.dart';
import '../../data/models/vault_list_model.dart';
import '../../data/repositories/vault_repository.dart';
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

  List<VaultItemModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _derivedKey;

  @override
  void initState() {
    super.initState();
    _loadItems();
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
        _isLoading = false;
      });

      final masterPassword = TokenStorage.getMasterPassword();
      if (masterPassword != null && masterPassword.isNotEmpty) {
        _deriveKey(masterPassword);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _deriveKey(String masterPassword) {
    final key = VaultCrypto.deriveKey(
      masterPassword: masterPassword,
      saltHex: widget.cryptoSalt,
      iterations: widget.cryptoIterations,
    );
    if (mounted) setState(() => _derivedKey = key);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                onPressed: _loadItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.loginButtonBackground,
                  foregroundColor: AppColors.loginButtonText,
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

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 16.h),
            Text(
              'No items yet',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Add your first encrypted item',
              style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final salt = await TokenStorage.getCryptoSalt() ?? '';
              final iterations =
                  await TokenStorage.getCryptoIterations() ?? 100000;
              if (!context.mounted) return;

              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      VaultItemDetailScreen(
                        item: item,
                        vault: widget.vault,
                        token: widget.token,
                        userName: widget.userName,
                        cryptoSalt: salt,
                        cryptoIterations: iterations,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: VaultItemTile(item: item, decryptionKey: _derivedKey),
          );
        },
      ),
    );
  }

  Future<void> _promptAndDeriveKey() async {
    var masterPassword = TokenStorage.getMasterPassword();
    if (masterPassword == null || masterPassword.isEmpty) {
      masterPassword = await _showMasterPasswordDialog();
      if (masterPassword == null) return;
      TokenStorage.setMasterPassword(masterPassword);
    }
    _deriveKey(masterPassword);
  }

  Future<String?> _showMasterPasswordDialog() async {
    final controller = TextEditingController();
    var obscure = true;

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
              _derivedKey != null
                  ? Icons.lock_open_outlined
                  : Icons.lock_outline,
              size: 20.sp,
              color: _derivedKey != null
                  ? const Color(0xFF00FF88)
                  : AppColors.secondaryText,
            ),
            onPressed: _derivedKey != null
                ? () => setState(() => _derivedKey = null)
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
