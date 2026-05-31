import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vault_bottom_nav.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/create_vault_request_model.dart';
import '../../data/models/vault_list_model.dart';
import '../../data/repositories/vault_repository.dart';
import 'vault_list_screen.dart';

class CreateVaultScreen extends StatefulWidget {
  const CreateVaultScreen({
    required this.token,
    required this.userName,
    this.vaultToEdit,
    super.key,
  });

  final String token;
  final String userName;
  final VaultListModel? vaultToEdit;

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repository = VaultRepository();

  bool _isLoading = false;
  String? _nameError;

  bool get _isEditMode => widget.vaultToEdit != null;

  String get _screenTitle => _isEditMode ? 'Update Vault' : 'Create Vault';

  String get _cardTitle =>
      _isEditMode ? 'Edit Security Layer' : 'New Security Layer';

  String get _cardSubtitle => _isEditMode
      ? 'Update your encrypted container.'
      : 'Configure your encrypted container.';

  String get _buttonLabel => _isEditMode ? 'Update Vault' : 'Save Vault';

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.vaultToEdit!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(52.h),
      child: Container(
        color: AppColors.scaffoldBg,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                  _screenTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white, size: 20.sp),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final circuitColor = Colors.white.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      height: 180.h,
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _CircuitPainter(color: circuitColor)),
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-0.85)
                  ..rotateZ(-0.7),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 168.w,
                      height: 22.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2F4A),
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 8),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      width: 138.w,
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E30),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      width: 104.w,
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 14,
                            offset: Offset(0, 8.h),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int? maxLines,
    int? minLines,
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: hasError
              ? const Color(0xFFCC3333)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 13.sp, color: Colors.white),
        cursorColor: Colors.white,
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13.sp,
            color: AppColors.secondaryText.withValues(alpha: 0.75),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 14.h,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 22.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cardTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _cardSubtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Vault name',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          _buildTextField(
            controller: _nameController,
            hintText: 'e.g., Personal',
            hasError: _nameError != null,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
          ),
          if (_nameError != null)
            Padding(
              padding: EdgeInsets.only(top: 6.h, left: 2.w),
              child: Text(
                _nameError!,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFFCC3333),
                ),
              ),
            ),
          if (!_isEditMode) ...[
            SizedBox(height: 16.h),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Optional notes',
              maxLines: 5,
              minLines: 4,
            ),
          ],
          SizedBox(height: 20.h),
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: AppColors.statusDot,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'End-to-end Encrypted',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    height: 48.h,
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
                  onTap: _isLoading ? null : _handleSaveVault,
                  child: Container(
                    height: 48.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.loginButtonBackground,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.loginButtonText,
                            ),
                          )
                        : Text(
                            _buttonLabel,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.loginButtonText,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLabel() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 12.sp,
            color: AppColors.secondaryText,
          ),
          SizedBox(width: 6.w),
          Text(
            'A-GRADE AES-256 STANDARD',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10.sp,
              color: AppColors.secondaryText,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveVault() async {
    setState(() => _nameError = null);

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Vault name is required');
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await _repository.updateVault(
          widget.vaultToEdit!.id,
          name,
          widget.token,
        );
      } else {
        final description = _descriptionController.text.trim();
        final request = CreateVaultRequestModel(
          name: name,
          description: description.isEmpty ? null : description,
        );
        await _repository.createVault(request, widget.token);
      }
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
                _isEditMode
                    ? 'Vault updated successfully'
                    : 'Vault created successfully',
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

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              VaultListScreen(token: widget.token, userName: widget.userName),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroBanner(),
              SizedBox(height: 4.h),
              _buildFormCard(),
              SizedBox(height: 16.h),
              _buildBottomLabel(),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (var i = 0; i < 11; i++) {
      final y = size.height * (0.18 + i * 0.055);
      canvas.drawLine(Offset(0, y), Offset(size.width * 0.32, y + 18), paint);
      canvas.drawLine(
        Offset(size.width, y),
        Offset(size.width * 0.68, y + 18),
        paint,
      );
    }

    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.26 + i * 0.06);
      canvas.drawLine(
        Offset(x, size.height * 0.18),
        Offset(x + 18, size.height * 0.02),
        paint,
      );
      canvas.drawLine(
        Offset(x, size.height * 0.82),
        Offset(x + 18, size.height * 0.98),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
