import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/register_request_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/vault_card.dart';
import '../widgets/vault_login_button.dart';
import '../widgets/vault_text_field.dart';

enum PasswordStrength { weak, fair, strong, veryStrong }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _masterPasswordController = TextEditingController();
  final _confirmMasterPasswordController = TextEditingController();
  final _repository = AuthRepository();

  late final TapGestureRecognizer _securityProtocolsRecognizer;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _signInRecognizer;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showMasterPassword = false;
  bool _showConfirmMasterPassword = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _masterPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _securityProtocolsRecognizer = TapGestureRecognizer()
      ..onTap = () => debugPrint('Security Protocols tapped');
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => debugPrint('Terms of Service tapped');
    _signInRecognizer = TapGestureRecognizer()..onTap = _handleSignIn;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController
      ..removeListener(_updatePasswordStrength)
      ..dispose();
    _confirmPasswordController.dispose();
    _masterPasswordController.dispose();
    _confirmMasterPasswordController.dispose();
    _securityProtocolsRecognizer.dispose();
    _termsRecognizer.dispose();
    _signInRecognizer.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = _getPasswordStrength(_passwordController.text);
    });
  }

  PasswordStrength _getPasswordStrength(String password) {
    if (password.length >= 12) return PasswordStrength.veryStrong;
    if (password.length >= 9) return PasswordStrength.strong;
    if (password.length >= 6) return PasswordStrength.fair;
    return PasswordStrength.weak;
  }

  void _toggleTerms() {
    setState(() => _agreedToTerms = !_agreedToTerms);
  }

  void _handleSignIn() {
    Navigator.pop(context);
  }

  Future<void> _handleRegister() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _masterPasswordError = null;
    });

    final fields = [
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _confirmPasswordController.text,
      _masterPasswordController.text,
      _confirmMasterPasswordController.text,
    ];

    if (fields.any((value) => value.isEmpty)) {
      _showError('All fields are required.');
      return;
    }

    var hasInlineError = false;
    final email = _emailController.text.trim();

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      _emailError = 'Enter a valid email address';
      hasInlineError = true;
    }
    if (_passwordController.text.length < 12) {
      _passwordError = 'Password must be at least 12 characters.';
      hasInlineError = true;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordError = 'Passwords do not match.';
      hasInlineError = true;
    }
    if (_masterPasswordController.text !=
        _confirmMasterPasswordController.text) {
      _masterPasswordError = 'Master passwords do not match.';
      hasInlineError = true;
    }

    if (hasInlineError) {
      setState(() {});
      return;
    }

    if (!_agreedToTerms) {
      _showError('Please agree to the Security Protocols and Terms.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = RegisterRequestModel(
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        masterPassword: _masterPasswordController.text,
        masterPasswordConfirmation: _confirmMasterPasswordController.text,
      );

      final response = await _repository.register(request);

      TokenStorage.setMasterPassword(_masterPasswordController.text);
      if (response.crypto.salt.isNotEmpty) {
        await TokenStorage.saveCrypto(
          salt: response.crypto.salt,
          iterations: response.crypto.iterations,
        );
        debugPrint('[Register] saved salt: ${response.crypto.salt}');
        debugPrint(
          '[Register] saved iterations: ${response.crypto.iterations}',
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return DashboardScreen(
              userName: response.user.name,
              token: response.token,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    _showErrorSnackBar(message);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryText,
            size: 22.sp,
          ),
        ),
        centerTitle: true,
        title: Text(
          'VAULT SYSTEM',
          style: GoogleFonts.sourceCodePro(
            fontSize: 13.sp,
            letterSpacing: 2.5.w,
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 24.h),
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder, width: 1.w),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48.sp,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Create Operator Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'INITIALIZE YOUR SECURE CREDENTIALS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 10.sp,
                    letterSpacing: 2.5.w,
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(height: 24.h),
                VaultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VaultTextField(
                        label: 'FULL NAME',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        controller: _fullNameController,
                      ),
                      SizedBox(height: 14.h),
                      VaultTextField(
                        label: 'EMAIL',
                        hintText: 'user@example.com',
                        prefixIcon: Icons.alternate_email,
                        controller: _emailController,
                      ),
                      if (_emailError != null) ...[
                        SizedBox(height: 6.h),
                        _InlineFieldError(message: _emailError!),
                      ],
                      SizedBox(height: 14.h),
                      VaultTextField(
                        label: 'PASSWORD',
                        hintText: 'Enter password',
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        suffixIcon: _VisibilityButton(
                          isVisible: _showPassword,
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                      if (_passwordError != null) ...[
                        SizedBox(height: 6.h),
                        _InlineFieldError(message: _passwordError!),
                      ],
                      SizedBox(height: 8.h),
                      _PasswordStrengthIndicator(strength: _passwordStrength),
                      SizedBox(height: 14.h),
                      VaultTextField(
                        label: 'CONFIRM PASSWORD',
                        hintText: 'Confirm password',
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        suffixIcon: _VisibilityButton(
                          isVisible: _showConfirmPassword,
                          onPressed: () {
                            setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            );
                          },
                        ),
                      ),
                      if (_confirmPasswordError != null) ...[
                        SizedBox(height: 6.h),
                        _InlineFieldError(message: _confirmPasswordError!),
                      ],
                      SizedBox(height: 14.h),
                      VaultTextField(
                        label: 'MASTER PASSWORD',
                        hintText: 'Enter master password',
                        prefixIcon: Icons.lock_outline,
                        controller: _masterPasswordController,
                        obscureText: !_showMasterPassword,
                        suffixIcon: _VisibilityButton(
                          isVisible: _showMasterPassword,
                          onPressed: () {
                            setState(
                              () => _showMasterPassword = !_showMasterPassword,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Used only for encrypting vault data. Keep it separate from your login password.',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.secondaryText,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      VaultTextField(
                        label: 'CONFIRM MASTER PASSWORD',
                        hintText: 'Confirm master password',
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmMasterPasswordController,
                        obscureText: !_showConfirmMasterPassword,
                        suffixIcon: _VisibilityButton(
                          isVisible: _showConfirmMasterPassword,
                          onPressed: () {
                            setState(
                              () => _showConfirmMasterPassword =
                                  !_showConfirmMasterPassword,
                            );
                          },
                        ),
                      ),
                      if (_masterPasswordError != null) ...[
                        SizedBox(height: 6.h),
                        _InlineFieldError(message: _masterPasswordError!),
                      ],
                      SizedBox(height: 16.h),
                      _TermsRow(
                        agreedToTerms: _agreedToTerms,
                        onCheckboxTap: _toggleTerms,
                        securityProtocolsRecognizer:
                            _securityProtocolsRecognizer,
                        termsRecognizer: _termsRecognizer,
                      ),
                      SizedBox(height: 20.h),
                      VaultLoginButton(
                        label: 'Register',
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                        icon: Icons.shield_outlined,
                      ),
                      SizedBox(height: 16.h),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: _signInRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                const _RegisterStatusBar(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.isVisible, required this.onPressed});

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.iconColor,
        size: 20.sp,
      ),
    );
  }
}

class _InlineFieldError extends StatelessWidget {
  const _InlineFieldError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        message,
        style: TextStyle(fontSize: 11.sp, color: const Color(0xFFCC3333)),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength});

  final PasswordStrength strength;

  static const _weakColor = Color(0xFFCC3333);
  static const _fairColor = Color(0xFFE8A030);
  static const _strongColor = Color(0xFF44AA77);
  static const _veryStrongColor = Color(0xFF4488FF);

  String get _label {
    return switch (strength) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.fair => 'Fair',
      PasswordStrength.strong => 'Strong',
      PasswordStrength.veryStrong => 'Very Strong',
    };
  }

  Color get _labelColor {
    return switch (strength) {
      PasswordStrength.weak => _weakColor,
      PasswordStrength.fair => _fairColor,
      PasswordStrength.strong => _strongColor,
      PasswordStrength.veryStrong => _veryStrongColor,
    };
  }

  List<Color> get _segmentColors {
    final inactive = AppColors.inputBorder;
    return switch (strength) {
      PasswordStrength.weak => [_weakColor, inactive, inactive, inactive],
      PasswordStrength.fair => [_weakColor, _fairColor, inactive, inactive],
      PasswordStrength.strong => [
        _weakColor,
        _fairColor,
        _strongColor,
        inactive,
      ],
      PasswordStrength.veryStrong => [
        _weakColor,
        _fairColor,
        _strongColor,
        _veryStrongColor,
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _segmentColors;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _label,
              style: TextStyle(
                fontSize: 10.sp,
                color: _labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Min. 12 Characters',
              style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            for (var index = 0; index < colors.length; index++) ...[
              Expanded(
                child: Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              if (index != colors.length - 1) SizedBox(width: 4.w),
            ],
          ],
        ),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.agreedToTerms,
    required this.onCheckboxTap,
    required this.securityProtocolsRecognizer,
    required this.termsRecognizer,
  });

  final bool agreedToTerms;
  final VoidCallback onCheckboxTap;
  final TapGestureRecognizer securityProtocolsRecognizer;
  final TapGestureRecognizer termsRecognizer;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.sp,
      color: AppColors.secondaryText,
    );
    final linkStyle = TextStyle(
      fontSize: 12.sp,
      color: AppColors.primaryText,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primaryText,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onCheckboxTap,
          child: Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              color: agreedToTerms
                  ? AppColors.loginButtonBackground
                  : Colors.transparent,
              border: Border.all(color: AppColors.secondaryText, width: 1.5.w),
              borderRadius: BorderRadius.circular(3.r),
            ),
            child: agreedToTerms
                ? Icon(
                    Icons.check,
                    size: 11.sp,
                    color: AppColors.loginButtonText,
                  )
                : null,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'I agree to the ', style: mutedStyle),
                TextSpan(
                  text: 'Security Protocols',
                  style: linkStyle,
                  recognizer: securityProtocolsRecognizer,
                ),
                TextSpan(text: ' & ', style: mutedStyle),
                TextSpan(
                  text: 'Terms of Service',
                  style: linkStyle,
                  recognizer: termsRecognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterStatusBar extends StatelessWidget {
  const _RegisterStatusBar();

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 9.sp,
      color: AppColors.secondaryText,
      letterSpacing: 1.5.w,
    );
    final valueStyle = TextStyle(
      fontSize: 11.sp,
      color: AppColors.primaryText,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.w,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENCRYPTION LEVEL', style: labelStyle),
                Text('AES-256-GCM', style: valueStyle),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('PROTOCOL VERSION', style: labelStyle),
                Text('V4.1.0-STABLE', style: valueStyle),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            'SECURE NODE: OS-24-NORTH-ALPHA',
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceCodePro(
              fontSize: 9.sp,
              color: AppColors.primaryText.withValues(alpha: 0.25),
              letterSpacing: 2.w,
            ),
          ),
        ),
      ],
    );
  }
}
