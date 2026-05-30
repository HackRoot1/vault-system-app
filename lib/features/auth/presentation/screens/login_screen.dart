import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'register_screen.dart';
import '../widgets/vault_card.dart';
import '../widgets/vault_login_button.dart';
import '../widgets/vault_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: AppStrings.emailHint);
  final _passwordController = TextEditingController(text: 'securevault');
  late final TapGestureRecognizer _registerRecognizer;

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _registerRecognizer = TapGestureRecognizer()..onTap = _handleRegisterTap;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerRecognizer.dispose();
    super.dispose();
  }

  void _toggleRememberMe() {
    setState(() => _rememberMe = !_rememberMe);
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _handleLogin() {}

  void _handleForgotPassword() {}

  void _handleRegisterTap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const RegisterScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final statusHeight = 48.h;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 24.h, 0, statusHeight + 24.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: VaultCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _LockHeader(),
                            SizedBox(height: 20.h),
                            Text(
                              AppStrings.vaultTitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              AppStrings.welcomeBack,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle,
                            ),
                            SizedBox(height: 28.h),
                            VaultTextField(
                              label: AppStrings.email,
                              hintText: AppStrings.emailHint,
                              prefixIcon: Icons.alternate_email,
                              controller: _emailController,
                            ),
                            SizedBox(height: 16.h),
                            VaultTextField(
                              label: AppStrings.password,
                              hintText: AppStrings.passwordHint,
                              prefixIcon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                onPressed: _togglePasswordVisibility,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.iconColor,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            _RememberForgotRow(
                              rememberMe: _rememberMe,
                              onRememberTap: _toggleRememberMe,
                              onForgotTap: _handleForgotPassword,
                            ),
                            SizedBox(height: 24.h),
                            VaultLoginButton(
                              label: AppStrings.login,
                              onPressed: _handleLogin,
                            ),
                            SizedBox(height: 20.h),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.noAccount,
                                    style: AppTextStyles.registerMuted,
                                  ),
                                  TextSpan(
                                    text: AppStrings.register,
                                    style: AppTextStyles.registerLink,
                                    recognizer: _registerRecognizer,
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
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const _BottomStatusBar(),
          ),
        ],
      ),
    );
  }
}

class _LockHeader extends StatelessWidget {
  const _LockHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputBackground,
      ),
      child: Icon(
        Icons.lock_outline,
        size: 56.sp,
        color: AppColors.primaryText,
      ),
    );
  }
}

class _RememberForgotRow extends StatelessWidget {
  const _RememberForgotRow({
    required this.rememberMe,
    required this.onRememberTap,
    required this.onForgotTap,
  });

  final bool rememberMe;
  final VoidCallback onRememberTap;
  final VoidCallback onForgotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRememberTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: rememberMe
                        ? AppColors.loginButtonBackground
                        : Colors.transparent,
                    border: Border.all(
                      color: AppColors.secondaryText,
                      width: 1.5.w,
                    ),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                  child: rememberMe
                      ? Icon(
                          Icons.check,
                          size: 11.sp,
                          color: AppColors.loginButtonText,
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    AppStrings.rememberMe,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTextStyles.actionText,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        TextButton(
          onPressed: onForgotTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondaryText,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.forgotPassword,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: AppTextStyles.actionText,
          ),
        ),
      ],
    );
  }
}

class _BottomStatusBar extends StatelessWidget {
  const _BottomStatusBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                  Flexible(
                    child: Text(
                      AppStrings.systemSecure,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: AppTextStyles.status,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                AppStrings.encryptionStatus,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textAlign: TextAlign.end,
                style: AppTextStyles.status,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
