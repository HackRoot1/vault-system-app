import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/crypto/vault_crypto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../../../vaults/data/repositories/vault_repository.dart';
import '../../data/repositories/file_repository.dart';

Future<bool> navigateToUploadFileScreen(
  BuildContext context, {
  required String token,
  required String userName,
  List<VaultListModel> vaults = const [],
  VaultListModel? preselectedVault,
}) async {
  final salt = await TokenStorage.getCryptoSalt();
  if (!context.mounted) return false;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
    return false;
  }

  final iterations = await TokenStorage.getCryptoIterations();
  if (!context.mounted) return false;

  var vaultList = List<VaultListModel>.from(vaults);
  if (vaultList.isEmpty) {
    try {
      vaultList = await VaultRepository().getVaults(token);
    } catch (_) {}
  }

  if (!context.mounted) return false;
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => UploadFileScreen(
        token: token,
        userName: userName,
        cryptoSalt: salt,
        cryptoIterations: iterations,
        vaults: vaultList,
        preselectedVault: preselectedVault,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
  return true;
}

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({
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
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  static const int _maxFileSizeBytes = 2 * 1024 * 1024 * 1024;

  final _repository = FileRepository();
  final _notesController = TextEditingController();

  VaultListModel? _selectedVault;
  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  String _selectedClassification = 'Document';
  final List<String> _classifications = const [
    'Document',
    'Image',
    'PDF',
    'Archive',
  ];

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    _selectedVault = widget.preselectedVault ??
        (widget.vaults.isNotEmpty ? widget.vaults.first : null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateSession());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _validateSession() async {
    final salt = await TokenStorage.getCryptoSalt();
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
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: Container(
        color: AppColors.scaffoldBg,
        padding: EdgeInsets.fromLTRB(4.w, 0, 16.w, 8.h),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20.sp,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF8899AA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'New File',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A1F),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF00CC66).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00CC66),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'END-TO-END\nENCRYPTION ACTIVE',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 7.sp,
                        color: const Color(0xFF00CC66),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _fileError = null);

    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > _maxFileSizeBytes) {
      setState(() => _fileError = 'File exceeds 2.0 GB limit');
      return;
    }

    if (file.bytes == null) {
      setState(() => _fileError = 'Could not read file bytes');
      return;
    }

    setState(() {
      _selectedFile = file;
      _selectedFileBytes = file.bytes;
      _selectedClassification = _classifyByExtension(file.extension ?? '');
    });
  }

  String _classifyByExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return 'Image';
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
      case '7z':
        return 'Archive';
      default:
        return 'Document';
    }
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.sourceCodePro(
        fontSize: 10.sp,
        color: const Color(0xFF8899AA),
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHero() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 140.w,
            height: 140.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2255EE).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12.h,
                  child: Container(
                    width: 84.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2F4A),
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2255EE).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF112240),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF2255EE).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2255EE).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 34.sp,
                    color: const Color(0xFF4488FF),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Securely upload and fragment your sensitive\n'
            'data across our encrypted distributed\n'
            'network.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF8899AA),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerZone() {
    final borderColor = _selectedFile != null
        ? const Color(0xFF2255EE).withValues(alpha: 0.6)
        : const Color(0xFF2255EE).withValues(alpha: 0.25);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickFile,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor,
          strokeWidth: 1.5,
          dashWidth: 8,
          dashSpace: 6,
          radius: 14.r,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F4A),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _selectedFile != null
                      ? Icons.check_circle_outline
                      : Icons.upload_file_outlined,
                  size: 28.sp,
                  color: _selectedFile != null
                      ? const Color(0xFF00CC66)
                      : const Color(0xFF4488FF),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                _selectedFile != null
                    ? _selectedFile!.name
                    : 'Select File to Encrypt',
                style: TextStyle(
                  fontSize: _selectedFile != null ? 13.sp : 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              if (_selectedFile != null)
                Text(
                  _formatBytes(_selectedFile!.size),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF00CC66),
                  ),
                )
              else
                Text(
                  'Drag and drop or click to browse',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF8899AA),
                  ),
                ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F4A),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'MAX SIZE: 2.0 GB',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 10.sp,
                    color: const Color(0xFF8899AA),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (_fileError != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _fileError!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFFCC3333),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CONTEXTUAL METADATA (NOTES)'),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF112240),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(fontSize: 13.sp, color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Add a description or keywords for this asset...',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF8899AA),
              ),
              contentPadding: EdgeInsets.all(14.w),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVaultDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('DESTINATION VAULT'),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFF112240),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VaultListModel>(
              value: _selectedVault,
              isExpanded: true,
              dropdownColor: const Color(0xFF112240),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFF8899AA),
                size: 20.sp,
              ),
              hint: Text(
                'Select vault',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
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
              onChanged: (vault) => setState(() => _selectedVault = vault),
            ),
          ),
        ),
      ],
    );
  }

  IconData _classificationIcon(String label) {
    switch (label) {
      case 'Document':
        return Icons.description_outlined;
      case 'Image':
        return Icons.image_outlined;
      case 'PDF':
        return Icons.picture_as_pdf_outlined;
      case 'Archive':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Widget _buildClassificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('FILE CLASSIFICATION'),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 2.8,
          children: _classifications.map((label) {
            final isSelected = _selectedClassification == label;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedClassification = label),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1A3A6A) : const Color(0xFF112240),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4488FF) : const Color(0x20FFFFFF),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _classificationIcon(label),
                      size: 16.sp,
                      color: isSelected ? const Color(0xFF4488FF) : const Color(0xFF8899AA),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isSelected ? Colors.white : const Color(0xFF8899AA),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return Column(
      children: [
        if (_isUploading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: const Color(0xFF112240),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2255EE),
              ),
              minHeight: 4.h,
            ),
          ),
          SizedBox(height: 12.h),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isUploading ? null : _handleUpload,
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              color: _isUploading ? const Color(0xFF1A2F4A) : const Color(0xFF2255EE),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: _isUploading
                  ? const []
                  : [
                      BoxShadow(
                        color: const Color(0xFF2255EE).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUploading)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.shield_outlined,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                SizedBox(width: 10.w),
                Text(
                  _isUploading ? 'ENCRYPTING & UPLOADING...' : 'ENCRYPT & UPLOAD',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _promptMasterPassword() async {
    final controller = TextEditingController();
    var obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF112240),
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
                'Enter your master password to encrypt this file.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF8899AA),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
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
                      color: const Color(0xFF8899AA),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    border: InputBorder.none,
                    suffixIcon: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setDialogState(() => obscure = !obscure),
                      child: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18.sp,
                        color: const Color(0xFF8899AA),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
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
                Navigator.pop(dialogContext, password);
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

  Future<void> _handleUpload() async {
    if (_selectedFile == null || _selectedFileBytes == null) {
      setState(() => _fileError = 'Please select a file first');
      return;
    }
    if (_selectedVault == null) {
      _showErrorSnackBar('Please select a destination vault');
      return;
    }

    var masterPassword = TokenStorage.getMasterPassword();
    if (masterPassword == null || masterPassword.isEmpty) {
      masterPassword = await _promptMasterPassword();
      if (!mounted) return;
      if (masterPassword == null) return;
      TokenStorage.setMasterPassword(masterPassword);
    }

    final salt = await TokenStorage.getCryptoSalt();
    if (!mounted) return;
    if (salt == null || salt.isEmpty) {
      _showErrorSnackBar('Session expired. Please log in again.');
      return;
    }

    final iterations = await TokenStorage.getCryptoIterations();
    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _fileError = null;
    });

    final selectedFile = _selectedFile!;
    final plainBytes = _selectedFileBytes!;

    try {
      setState(() => _uploadProgress = 0.1);
      final key = await VaultCrypto.deriveKey(
        masterPassword: masterPassword,
        saltHex: salt,
        iterations: iterations,
      );
      if (!mounted) return;

      setState(() => _uploadProgress = 0.3);
      final algorithm = AesGcm.with256bits(nonceLength: 12);
      final iv = _randomBytes(12);
      final secretBox = await algorithm.encrypt(
        plainBytes,
        secretKey: key,
        nonce: iv,
      );
      if (!mounted) return;

      final encryptedBytes = Uint8List.fromList(secretBox.cipherText);
      final ivBase64 = base64.encode(iv);
      final tagBase64 = base64.encode(secretBox.mac.bytes);

      setState(() => _uploadProgress = 0.7);
      await _repository.uploadFile(
        vaultId: _selectedVault!.id,
        token: widget.token,
        fileName: selectedFile.name,
        encryptedBytes: encryptedBytes,
        ivBase64: ivBase64,
        tagBase64: tagBase64,
      );
      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
        _selectedFileBytes = null;
      });

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
              Expanded(
                child: Text(
                  '"${selectedFile.name}" encrypted and uploaded',
                  style: TextStyle(fontSize: 13.sp, color: Colors.white),
                ),
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

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Encryption failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => rng.nextInt(256)),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
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
                _buildHero(),
                SizedBox(height: 24.h),
                _buildFilePickerZone(),
                SizedBox(height: 20.h),
                _buildNotesField(),
                SizedBox(height: 20.h),
                _buildVaultDropdown(),
                SizedBox(height: 20.h),
                _buildClassificationSection(),
                SizedBox(height: 28.h),
                _buildUploadButton(),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 8,
    this.dashSpace = 6,
    this.radius = 14,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}
