import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/crypto/vault_crypto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/create_vault_item_request_model.dart';
import '../../data/models/vault_list_model.dart';
import '../../data/repositories/vault_repository.dart';
import 'vault_detail_screen.dart';

enum VaultItemType { login, secureNote, creditCard }

extension VaultItemTypeX on VaultItemType {
  String get label {
    return switch (this) {
      VaultItemType.login => 'Login',
      VaultItemType.secureNote => 'Secure Note',
      VaultItemType.creditCard => 'Credit Card',
    };
  }

  String get apiValue {
    return switch (this) {
      VaultItemType.login => 'login',
      VaultItemType.secureNote => 'secure_note',
      VaultItemType.creditCard => 'credit_card',
    };
  }

  IconData get icon {
    return switch (this) {
      VaultItemType.login => Icons.login_outlined,
      VaultItemType.secureNote => Icons.note_outlined,
      VaultItemType.creditCard => Icons.credit_card_outlined,
    };
  }
}

class CreateVaultItemScreen extends StatefulWidget {
  const CreateVaultItemScreen({
    required this.token,
    required this.userName,
    required this.cryptoSalt,
    required this.cryptoIterations,
    required this.vaults,
    this.preselectedVault,
    super.key,
  });

  final String token;
  final String userName;
  final String cryptoSalt;
  final int cryptoIterations;
  final List<VaultListModel> vaults;
  final VaultListModel? preselectedVault;

  @override
  State<CreateVaultItemScreen> createState() => _CreateVaultItemScreenState();
}

class _CreateVaultItemScreenState extends State<CreateVaultItemScreen> {
  final _repository = VaultRepository();

  VaultListModel? _selectedVault;
  VaultItemType _selectedType = VaultItemType.login;
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _secretController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showSecret = false;

  final _notesTitleController = TextEditingController();
  final _notesContentController = TextEditingController();

  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderController = TextEditingController();
  bool _showCvv = false;

  String? _titleError;
  String? _vaultError;

  @override
  void initState() {
    super.initState();
    _selectedVault = widget.preselectedVault;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _secretController.dispose();
    _notesController.dispose();
    _notesTitleController.dispose();
    _notesContentController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: Container(
        color: AppColors.scaffoldBg,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    'SECUREVAULT',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12.sp,
                      letterSpacing: 2.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        color: AppColors.secondaryText,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInlineError(String error) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h, left: 2.w),
      child: Text(
        error,
        style: TextStyle(fontSize: 11.sp, color: const Color(0xFFCC3333)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13.sp, color: Colors.white),
        cursorColor: Colors.white,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 14.h,
          ),
          border: InputBorder.none,
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _buildVaultDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: _vaultError != null
              ? const Color(0xFFCC3333)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VaultListModel>(
          value: _selectedVault,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.secondaryText,
            size: 20.sp,
          ),
          hint: Text(
            'Select vault',
            style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
          ),
          style: TextStyle(fontSize: 13.sp, color: Colors.white),
          items: widget.vaults
              .map(
                (vault) => DropdownMenuItem<VaultListModel>(
                  value: vault,
                  child: Text(vault.name),
                ),
              )
              .toList(),
          onChanged: (vault) => setState(() {
            _selectedVault = vault;
            _vaultError = null;
          }),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VaultItemType>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.secondaryText,
            size: 20.sp,
          ),
          style: TextStyle(fontSize: 13.sp, color: Colors.white),
          items: VaultItemType.values
              .map(
                (type) => DropdownMenuItem<VaultItemType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        size: 16.sp,
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: 10.w),
                      Text(type.label),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (type) => setState(() => _selectedType = type!),
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Title'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _titleController,
          hint: 'GitHub',
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        if (_titleError != null) _buildInlineError(_titleError!),
        SizedBox(height: 16.h),
        _buildLabel('Username'),
        SizedBox(height: 8.h),
        _buildTextField(controller: _usernameController, hint: 'octocat'),
        SizedBox(height: 16.h),
        _buildLabel('Secret'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _secretController,
          hint: '',
          obscure: !_showSecret,
          suffix: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showSecret = !_showSecret),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 16.sp,
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _showSecret ? 'Hide' : 'Show',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildLabel('Notes'),
        SizedBox(height: 8.h),
        _buildTextField(controller: _notesController, hint: '', maxLines: 5),
      ],
    );
  }

  Widget _buildSecureNoteFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Title'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _notesTitleController,
          hint: 'Note title',
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        if (_titleError != null) _buildInlineError(_titleError!),
        SizedBox(height: 16.h),
        _buildLabel('Content'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _notesContentController,
          hint: 'Write your secure note here...',
          maxLines: 8,
        ),
      ],
    );
  }

  Widget _buildCreditCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Card Name'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _cardNameController,
          hint: 'e.g. Personal Visa',
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        if (_titleError != null) _buildInlineError(_titleError!),
        SizedBox(height: 16.h),
        _buildLabel('Cardholder Name'),
        SizedBox(height: 8.h),
        _buildTextField(controller: _cardholderController, hint: 'John Doe'),
        SizedBox(height: 16.h),
        _buildLabel('Card Number'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _cardNumberController,
          hint: '**** **** **** ****',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Expiry'),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    controller: _expiryController,
                    hint: 'MM/YY',
                    keyboardType: TextInputType.datetime,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('CVV'),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    controller: _cvvController,
                    hint: '***',
                    obscure: !_showCvv,
                    keyboardType: TextInputType.number,
                    suffix: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _showCvv = !_showCvv),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Icon(
                          _showCvv
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 16.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDynamicFields() {
    return switch (_selectedType) {
      VaultItemType.login => _buildLoginFields(),
      VaultItemType.secureNote => _buildSecureNoteFields(),
      VaultItemType.creditCard => _buildCreditCardFields(),
    };
  }

  Future<void> _handleEncryptAndSave() async {
    setState(() {
      _vaultError = null;
      _titleError = null;
    });

    if (_selectedVault == null) {
      setState(() => _vaultError = 'Please select a vault');
      return;
    }

    final titleValue = switch (_selectedType) {
      VaultItemType.login => _titleController.text.trim(),
      VaultItemType.secureNote => _notesTitleController.text.trim(),
      VaultItemType.creditCard => _cardNameController.text.trim(),
    };

    if (titleValue.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }

    var masterPassword = TokenStorage.getMasterPassword();
    if (masterPassword == null || masterPassword.isEmpty) {
      masterPassword = await _promptMasterPassword();
      if (masterPassword == null) return;
      TokenStorage.setMasterPassword(masterPassword);
    }

    setState(() => _isLoading = true);

    try {
      final key = VaultCrypto.deriveKey(
        masterPassword: masterPassword,
        saltHex: widget.cryptoSalt,
        iterations: widget.cryptoIterations,
      );

      final payload = switch (_selectedType) {
        VaultItemType.login => {
          'title': _titleController.text.trim(),
          'username': _usernameController.text.trim(),
          'secret': _secretController.text,
          'notes': _notesController.text.trim(),
        },
        VaultItemType.secureNote => {
          'title': _notesTitleController.text.trim(),
          'content': _notesContentController.text.trim(),
        },
        VaultItemType.creditCard => {
          'card_name': _cardNameController.text.trim(),
          'cardholder': _cardholderController.text.trim(),
          'number': _cardNumberController.text.trim(),
          'expiry': _expiryController.text.trim(),
          'cvv': _cvvController.text,
        },
      };

      final encrypted = VaultCrypto.encrypt(
        plainText: jsonEncode(payload),
        key: key,
      );

      final request = CreateVaultItemRequestModel(
        type: _selectedType.apiValue,
        encryptedData: encrypted['encrypted_data']!,
        iv: encrypted['iv']!,
        tag: encrypted['tag']!,
      );

      await _repository.createItem(_selectedVault!.id, request, widget.token);
      if (!mounted) return;

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
                'Item encrypted and saved',
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

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              VaultDetailScreen(
                vault: _selectedVault!,
                token: widget.token,
                userName: widget.userName,
                cryptoSalt: widget.cryptoSalt,
                cryptoIterations: widget.cryptoIterations,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptMasterPassword() async {
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
                'Enter your master password to encrypt this item.',
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
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Add Item',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
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
                            'Encrypted\nSession',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 8.sp,
                              color: const Color(0xFF00FF88),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildLabel('Vault'),
                SizedBox(height: 8.h),
                _buildVaultDropdown(),
                if (_vaultError != null) _buildInlineError(_vaultError!),
                SizedBox(height: 16.h),
                _buildLabel('Type'),
                SizedBox(height: 8.h),
                _buildTypeDropdown(),
                SizedBox(height: 20.h),
                _buildDynamicFields(),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          height: 52.h,
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isLoading ? null : _handleEncryptAndSave,
                        child: Container(
                          height: 52.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2255EE),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 16.sp,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Encrypt & Save',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
