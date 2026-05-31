import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _startLoadingSequence();
  }

  Future<void> _startLoadingSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _statusText = 'DECRYPTING LOCAL VAULT...');

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _statusText = 'VERIFYING CREDENTIALS...');

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _statusText = 'INITIALIZING SECURE CHANNEL...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final hasSession = await TokenStorage.hasSession();
    if (!mounted) return;

    if (hasSession) {
      final name = await TokenStorage.getUserName() ?? '';
      if (!mounted) return;

      final token = await TokenStorage.getToken() ?? '';
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DashboardScreen(userName: name, token: token),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 0.8,
            colors: [Color(0xFF1A2F4A), AppColors.scaffoldBg],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.w,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 64.sp,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    AppStrings.vaultTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.w,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'SECURE YOUR DIGITAL SECRETS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.w,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      color: AppColors.inputBorder,
                      thickness: 1.h,
                      height: 1.h,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14.sp,
                          color: AppColors.secondaryText,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: _AnimatedStatusText(statusText: _statusText),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatusText extends StatelessWidget {
  const _AnimatedStatusText({required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        statusText,
        key: ValueKey(statusText),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: GoogleFonts.sourceCodePro(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.5.w,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
