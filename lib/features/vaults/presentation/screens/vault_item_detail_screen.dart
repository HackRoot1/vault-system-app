import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class VaultItemDetailScreen extends StatefulWidget {
  const VaultItemDetailScreen({
    required this.item,
    required this.vault,
    required this.token,
    required this.userName,
    required this.cryptoSalt,
    required this.cryptoIterations,
    super.key,
  });

  final VaultItemModel item;
  final VaultListModel vault;
  final String token;
  final String userName;
  final String cryptoSalt;
  final int cryptoIterations;

  @override
  State<VaultItemDetailScreen> createState() => _VaultItemDetailScreenState();
}

class _VaultItemDetailScreenState extends State<VaultItemDetailScreen> {
  final _repository = VaultRepository();

  VaultItemModel? _freshItem;
  bool _isLoading = true;
  String? _errorMessage;
  SecretKey? _derivedKey;
  Map<String, dynamic>? _decryptedPayload;
  bool _isDecrypting = false;
  bool _showSecret = false;
  bool _showCvv = false;

  @override
  void initState() {
    super.initState();
    _freshItem = widget.item;
    _loadItem();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final masterPassword = TokenStorage.getMasterPassword();
      if (masterPassword != null && masterPassword.isNotEmpty) {
        await _deriveAndDecrypt(masterPassword);
      }
    });
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await _repository.getItem(
        widget.vault.id,
        widget.item.id,
        widget.token,
      );
      if (!mounted) return;
      setState(() {
        _freshItem = item;
        _isLoading = false;
      });
      if (_derivedKey != null) await _decryptPayload();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _deriveAndDecrypt(String masterPassword) async {
    setState(() => _isDecrypting = true);
    try {
      final key = await VaultCrypto.deriveKey(
        masterPassword: masterPassword,
        saltHex: widget.cryptoSalt,
        iterations: widget.cryptoIterations,
      );
      if (!mounted) return;

      final item = _freshItem ?? widget.item;
      final payload = await item.decryptPayload(key);
      if (!mounted) return;

      setState(() {
        _derivedKey = key;
        _decryptedPayload = payload;
        _isDecrypting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isDecrypting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Decryption failed. Check your master password.',
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
      }
    }
  }

  Future<void> _decryptPayload() async {
    if (_derivedKey == null) return;
    final payload = await (_freshItem ?? widget.item).decryptPayload(
      _derivedKey!,
    );
    if (!mounted) return;
    setState(() => _decryptedPayload = payload);
  }

  String _typeLabel(String type) {
    return switch (type) {
      'login' => 'Login Credential',
      'secure_note' => 'Secure Note',
      'credit_card' => 'Credit Card',
      _ => 'Vault Item',
    };
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'login' => Icons.login_outlined,
      'secure_note' => Icons.note_outlined,
      'credit_card' => Icons.credit_card_outlined,
      _ => Icons.lock_outline,
    };
  }

  Widget _buildBody() {
    if (_isLoading && _freshItem == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (_errorMessage != null && _freshItem == null) {
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
                onPressed: _loadItem,
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

    final item = _freshItem ?? widget.item;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildInfoCard(item),
            SizedBox(height: 16.h),
            if (_decryptedPayload == null) _buildDecryptBanner(),
            if (_decryptedPayload == null) SizedBox(height: 16.h),
            if (_decryptedPayload != null) _buildDecryptedDetails(item.type),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(VaultItemModel item) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _typeIcon(item.type),
              size: 22.sp,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(item.type),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Vault: ${widget.vault.name}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Added ${_formatDate(item.createdAt)}',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 10.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF00FF88).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 5.w,
                  height: 5.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF88),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'AES-256',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 8.sp,
                    color: const Color(0xFF00FF88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecryptBanner() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _promptAndDecrypt,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2255EE).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF2255EE).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDecrypting)
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2255EE),
                ),
              )
            else
              Icon(
                Icons.lock_open_outlined,
                size: 16.sp,
                color: const Color(0xFF4477FF),
              ),
            SizedBox(width: 10.w),
            Text(
              _isDecrypting ? 'Decrypting...' : 'Tap to decrypt this item',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF4477FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecryptedDetails(String type) {
    return switch (type) {
      'login' => _buildLoginDetail(),
      'secure_note' => _buildSecureNoteDetail(),
      'credit_card' => _buildCreditCardDetail(),
      _ => _buildRawDetail(),
    };
  }

  Widget _buildDetailField({
    required String label,
    required String value,
    bool obscure = false,
    bool showToggle = false,
    bool isToggled = false,
    VoidCallback? onToggle,
    bool copyable = true,
  }) {
    final displayValue = obscure && !isToggled
        ? List.filled(min(value.length, 16), '*').join()
        : value;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 10.sp,
              color: AppColors.secondaryText,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showToggle)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      isToggled
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              if (copyable) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$label copied',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
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
                  },
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 16.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginDetail() {
    final payload = _decryptedPayload!;
    return Column(
      children: [
        _buildDetailField(label: 'TITLE', value: payload['title'] ?? ''),
        _buildDetailField(label: 'USERNAME', value: payload['username'] ?? ''),
        _buildDetailField(
          label: 'SECRET',
          value: payload['secret'] ?? '',
          obscure: true,
          showToggle: true,
          isToggled: _showSecret,
          onToggle: () => setState(() => _showSecret = !_showSecret),
        ),
        if ((payload['notes'] as String? ?? '').isNotEmpty)
          _buildDetailField(
            label: 'NOTES',
            value: payload['notes'] ?? '',
            copyable: false,
          ),
      ],
    );
  }

  Widget _buildSecureNoteDetail() {
    final payload = _decryptedPayload!;
    return Column(
      children: [
        _buildDetailField(label: 'TITLE', value: payload['title'] ?? ''),
        _buildDetailField(
          label: 'CONTENT',
          value: payload['content'] ?? '',
          copyable: false,
        ),
      ],
    );
  }

  Widget _buildCreditCardDetail() {
    final payload = _decryptedPayload!;
    return Column(
      children: [
        _buildDetailField(
          label: 'CARD NAME',
          value: payload['card_name'] ?? '',
        ),
        _buildDetailField(
          label: 'CARDHOLDER',
          value: payload['cardholder'] ?? '',
        ),
        _buildDetailField(label: 'CARD NUMBER', value: payload['number'] ?? ''),
        Row(
          children: [
            Expanded(
              child: _buildDetailField(
                label: 'EXPIRY',
                value: payload['expiry'] ?? '',
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildDetailField(
                label: 'CVV',
                value: payload['cvv'] ?? '',
                obscure: true,
                showToggle: true,
                isToggled: _showCvv,
                onToggle: () => setState(() => _showCvv = !_showCvv),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRawDetail() {
    return _buildDetailField(
      label: 'ENCRYPTED DATA',
      value: (_freshItem ?? widget.item).encryptedData,
    );
  }

  Future<void> _promptAndDecrypt() async {
    var masterPassword = TokenStorage.getMasterPassword();
    if (masterPassword == null || masterPassword.isEmpty) {
      masterPassword = await _showMasterPasswordDialog();
      if (!mounted) return;
      if (masterPassword == null) return;
      TokenStorage.setMasterPassword(masterPassword);
    }
    await _deriveAndDecrypt(masterPassword);
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
                'Enter your master password to decrypt this item.',
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

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = _freshItem ?? widget.item;

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
          _typeLabel(item.type),
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
              _decryptedPayload != null
                  ? Icons.lock_open_outlined
                  : Icons.lock_outline,
              size: 20.sp,
              color: _decryptedPayload != null
                  ? const Color(0xFF00FF88)
                  : AppColors.secondaryText,
            ),
            onPressed: _decryptedPayload != null
                ? () => setState(() {
                    _decryptedPayload = null;
                    _derivedKey = null;
                  })
                : _promptAndDecrypt,
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
      body: SafeArea(child: _buildBody()),
    );
  }
}
