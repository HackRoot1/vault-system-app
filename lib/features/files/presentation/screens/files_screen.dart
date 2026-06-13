import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/crypto/vault_crypto.dart';
import '../../../../core/storage/download_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../vaults/data/models/vault_list_model.dart';
import '../../../vaults/presentation/screens/vault_list_screen.dart';
import 'upload_file_screen.dart';
import '../../data/models/vault_file_model.dart';
import '../../data/repositories/file_repository.dart';
import '../widgets/file_list_tile.dart';

enum _FileSortMode { recent, alphabetical, oldest }

class FilesScreen extends StatefulWidget {
  const FilesScreen({
    required this.token,
    required this.userName,
    required this.vaults,
    super.key,
  });

  final String token;
  final String userName;
  final List<VaultListModel> vaults;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _repository = FileRepository();
  final _searchController = TextEditingController();

  List<VaultListModel> _vaults = [];
  VaultListModel? _selectedVault;
  List<VaultFileModel> _allFiles = [];
  List<VaultFileModel> _filteredFiles = [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _showSearchClear = false;
  String _selectedFilter = 'All';
  List<String> _filterChips = ['All'];
  _FileSortMode _sortMode = _FileSortMode.recent;
  int _selectedNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _vaults = widget.vaults;
    if (_vaults.isNotEmpty) {
      _selectedVault = _vaults.first;
    }
    _searchController.addListener(_onSearchChanged);
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSettingsScreen,
                child: Icon(
                  Icons.settings_outlined,
                  size: 22.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFiles() async {
    final selectedVault = _selectedVault;
    if (selectedVault == null) {
      if (!mounted) return;
      setState(() {
        _allFiles = [];
        _filteredFiles = [];
        _filterChips = ['All'];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await _repository.getFiles(selectedVault.id, widget.token);
      if (!mounted) return;

      final exts =
          files
              .map((f) => f.extension.toUpperCase())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      setState(() {
        _allFiles = files;
        _filterChips = ['All', ...exts];
        _selectedFilter = 'All';
        _isLoading = false;
      });
      _applyFilters();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _allFiles.where((file) {
      final matchesFilter =
          _selectedFilter == 'All' ||
          file.extension.toUpperCase() == _selectedFilter;
      final matchesSearch =
          query.isEmpty || file.fileName.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    filtered.sort(_compareFiles);

    if (!mounted) return;
    setState(() {
      _filteredFiles = filtered;
    });
  }

  int _compareFiles(VaultFileModel a, VaultFileModel b) {
    switch (_sortMode) {
      case _FileSortMode.alphabetical:
        return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
      case _FileSortMode.oldest:
        return DateTime.tryParse(a.createdAt)?.compareTo(
              DateTime.tryParse(b.createdAt) ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            ) ??
            0;
      case _FileSortMode.recent:
        return (DateTime.tryParse(b.createdAt) ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
              DateTime.tryParse(a.createdAt) ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            );
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _showSearchClear = _searchController.text.isNotEmpty);
    _applyFilters();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(30.r),
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
                hintText: 'Search files...',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 13.h),
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
                color: const Color(0xFF8899AA),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVaultSelector() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Container(
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
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF8899AA)),
            ),
            style: TextStyle(fontSize: 13.sp, color: Colors.white),
            items: _vaults
                .map(
                  (vault) => DropdownMenuItem<VaultListModel>(
                    value: vault,
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14.sp,
                          color: const Color(0xFF8899AA),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(child: Text(vault.name)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (vault) {
              if (vault == null) return;
              setState(() {
                _selectedVault = vault;
                _selectedFilter = 'All';
                _searchController.clear();
              });
              _loadFiles();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 72.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: _filterChips.length,
        itemBuilder: (context, index) {
          final chip = _filterChips[index];
          final isSelected = _selectedFilter == chip;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selectedFilter = chip);
              _applyFilters();
            },
            child: Container(
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF112240),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0x20FFFFFF),
                ),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0D1B2A)
                      : const Color(0xFF8899AA),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilesHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Encrypted Files',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showFilterSortSheet,
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 18.sp,
                  color: const Color(0xFF8899AA),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF8899AA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => _buildShimmerTile(),
      );
    }

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
                onPressed: _loadFiles,
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

    if (_selectedVault == null) {
      return _buildEmptyVaultState();
    }

    if (_allFiles.isEmpty) {
      return _buildNoFilesState();
    }

    if (_filteredFiles.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 36.sp,
                color: const Color(0xFF8899AA),
              ),
              SizedBox(height: 12.h),
              Text(
                'No files match "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF112240),
      onRefresh: _loadFiles,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredFiles.length,
        itemBuilder: (context, index) {
          final file = _filteredFiles[index];
          return FileListTile(
            file: file,
            onDownload: () => _downloadFile(file),
            onShare: () => _sharePlaceholder(file),
            onDelete: () => _confirmDeleteFile(file),
            onLongPress: () => _showFileOptions(file),
          );
        },
      ),
    );
  }

  Widget _buildEmptyVaultState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 52.sp,
              color: const Color(0xFF8899AA),
            ),
            SizedBox(height: 16.h),
            Text(
              'No vaults available',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Create a vault before adding encrypted files',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF8899AA)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  navigateToUploadFileScreen(
                    context,
                    token: widget.token,
                    userName: widget.userName,
                    vaults: _vaults,
                    preselectedVault: _selectedVault,
                  ).then((opened) {
                    if (mounted && opened) _loadFiles();
                  }),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8D8E8),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Upload File',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilesState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 52.sp,
              color: const Color(0xFF8899AA),
            ),
            SizedBox(height: 16.h),
            Text(
              'No files yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Upload your first encrypted file',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF8899AA)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  navigateToUploadFileScreen(
                    context,
                    token: widget.token,
                    userName: widget.userName,
                    vaults: _vaults,
                    preselectedVault: _selectedVault,
                  ).then((opened) {
                    if (mounted && opened) _loadFiles();
                  }),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8D8E8),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Upload File',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLongPressHint() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(
        'Long press a file for security options',
        textAlign: TextAlign.center,
        style: GoogleFonts.sourceCodePro(
          fontSize: 10.sp,
          color: const Color(0x55FFFFFF),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildShimmerTile() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140.w,
                  height: 13.h,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 90.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 24.w,
                height: 24.w,
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

  Future<void> _downloadFile(VaultFileModel file) async {
    try {
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
                'Preparing download...',
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
          duration: const Duration(seconds: 20),
        ),
      );

      final downloadUrlOrToken = await _repository.getDownloadUrl(
        file.vaultId,
        file.id,
        widget.token,
      );
      if (!mounted) return;
      debugPrint(
        'FilesScreen download-url for file=${file.id}, vault=${file.vaultId}: $downloadUrlOrToken',
      );

      final bytes = await _repository.downloadFile(
        downloadUrlOrToken,
        token: widget.token,
      );
      if (!mounted) return;
      debugPrint(
        'FilesScreen downloaded bytes for file=${file.id}: ${bytes.length}',
      );

      final masterPassword = await _getMasterPasswordForDownload();
      if (!mounted) return;
      if (masterPassword == null || masterPassword.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      final salt = await TokenStorage.getCryptoSalt();
      if (!mounted) return;
      if (salt == null || salt.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Session expired. Please log in again.');
        return;
      }

      final iterations = await TokenStorage.getCryptoIterations();
      if (!mounted) return;

      final key = await VaultCrypto.deriveKey(
        masterPassword: masterPassword,
        saltHex: salt,
        iterations: iterations,
      );
      if (!mounted) return;

      final plainBytes = await VaultCrypto.decryptBytes(
        encryptedBytes: bytes,
        ivB64: file.iv,
        tagB64: file.tag,
        key: key,
      );
      if (!mounted) return;

      final savePath = await _resolveDownloadPath(file.fileName);
      if (!mounted) return;
      if (savePath == null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download folder not selected.',
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF112240),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      debugPrint('FilesScreen save-path for file=${file.id}: $savePath');

      try {
        await File(savePath).writeAsBytes(plainBytes, flush: true);
        debugPrint('FilesScreen wrote file to: $savePath');
      } catch (e, st) {
        debugPrint('FilesScreen write error: $e');
        debugPrint('FilesScreen write stack: $st');
        rethrow;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.download_done_outlined,
                color: Colors.white,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Downloaded ${file.displayName}',
                  maxLines: 2,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white),
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
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      debugPrint(
        'FilesScreen download ApiException: ${e.statusCode} ${e.message}',
      );
      _showErrorSnackBar('Download failed (${e.statusCode}): ${e.message}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      debugPrint('FilesScreen download failed with an unknown error.');
      _showErrorSnackBar('Unable to download file.');
    }
  }

  String _downloadFileName(String fileName) {
    return fileName.replaceFirst(RegExp(r'\.enc$', caseSensitive: false), '');
  }

  Future<String?> _getMasterPasswordForDownload() async {
    final currentPassword = TokenStorage.getMasterPassword();
    if (currentPassword != null && currentPassword.isNotEmpty) {
      return currentPassword;
    }

    final password = await _showMasterPasswordDialog();
    if (!mounted) return null;
    if (password == null || password.isEmpty) return null;
    TokenStorage.setMasterPassword(password);
    await TokenStorage.saveMasterPasswordSecure(password);
    return password;
  }

  Future<String?> _showMasterPasswordDialog() async {
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
                'Enter your master password to decrypt this file.',
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

  Future<String?> _resolveDownloadPath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final expectedDirectory =
        '${appDir.path}${Platform.pathSeparator}VaultSystemDownloads';
    var downloadDirectory = await DownloadStorage.getDownloadDirectory();

    if (downloadDirectory == null || downloadDirectory.isEmpty) {
      final shouldSet = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF112240),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            'Set Download Folder',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Downloads will be saved in the app folder by default. You can change this later from settings.',
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF8899AA)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8899AA),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Use App Folder',
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (shouldSet != true) {
        return null;
      }
      downloadDirectory = expectedDirectory;
      await DownloadStorage.saveDownloadDirectory(downloadDirectory);
    }

    final directory = Directory(downloadDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return '${directory.path}${Platform.pathSeparator}${_downloadFileName(fileName)}';
  }

  void _sharePlaceholder(VaultFileModel file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share feature coming soon.',
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

  Future<void> _confirmDeleteFile(VaultFileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              'Delete File',
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
                file.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
            onPressed: () => Navigator.pop(dialogContext, false),
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
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteFile(file);
  }

  Future<void> _deleteFile(VaultFileModel file) async {
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
              'Deleting file...',
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF112240),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      await _repository.deleteFile(file.vaultId, file.id, widget.token);
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
                'File deleted successfully',
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
        _allFiles.removeWhere((f) => f.id == file.id);
      });
      _applyFilters();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar(e.message);
    }
  }

  void _showFileOptions(VaultFileModel file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF112240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
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
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14.sp,
                    color: const Color(0xFF8899AA),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Encrypted File',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF8899AA),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                file.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              const Divider(color: Color(0x14FFFFFF)),
              SizedBox(height: 4.h),
              _OptionRow(
                icon: Icons.download_outlined,
                label: 'Download & Decrypt',
                color: const Color(0xFF8899AA),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _downloadFile(file);
                },
              ),
              _OptionRow(
                icon: Icons.share_outlined,
                label: 'Share',
                color: const Color(0xFF8899AA),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sharePlaceholder(file);
                },
              ),
              _OptionRow(
                icon: Icons.delete_outline,
                label: 'Delete File',
                color: const Color(0xFFCC3333),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteFile(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF112240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
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
                'Sort Files',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              const Divider(color: Color(0x14FFFFFF)),
              _OptionRow(
                icon: Icons.access_time_outlined,
                label: 'Most Recent',
                color: const Color(0xFF8899AA),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _sortMode = _FileSortMode.recent);
                  _applyFilters();
                },
              ),
              _OptionRow(
                icon: Icons.sort_by_alpha,
                label: 'Alphabetical',
                color: const Color(0xFF8899AA),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _sortMode = _FileSortMode.alphabetical);
                  _applyFilters();
                },
              ),
              _OptionRow(
                icon: Icons.history_outlined,
                label: 'Oldest First',
                color: const Color(0xFF8899AA),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _sortMode = _FileSortMode.oldest);
                  _applyFilters();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettingsScreen() async {
    final email = await TokenStorage.getUserEmail() ?? '';
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(
          token: widget.token,
          userName: widget.userName,
          userEmail: email,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2255EE),
        onPressed: () =>
            navigateToUploadFileScreen(
              context,
              token: widget.token,
              userName: widget.userName,
              vaults: _vaults,
              preselectedVault: _selectedVault,
            ).then((opened) {
              if (mounted && opened) _loadFiles();
            }),
        child: Icon(
          Icons.upload_file_outlined,
          color: Colors.white,
          size: 22.sp,
        ),
      ),
      bottomNavigationBar: VaultBottomNav(
        selectedIndex: _selectedNavIndex,
        onTabChanged: (i) => setState(() => _selectedNavIndex = i),
        onHomeTap: () => Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DashboardScreen(userName: widget.userName, token: widget.token),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        ),
        onVaultsTap: () => Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                VaultListScreen(token: widget.token, userName: widget.userName),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        ),
        onSettingsTap: _openSettingsScreen,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildVaultSelector(),
            _buildFilterChips(),
            _buildFilesHeader(),
            Expanded(child: _buildBody()),
            _buildLongPressHint(),
          ],
        ),
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
        padding: EdgeInsets.symmetric(vertical: 12.h),
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
