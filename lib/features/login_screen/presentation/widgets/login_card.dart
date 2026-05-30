import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/vault_lock_icon.dart';
import '../providers/login_controller.dart';
import '../providers/login_state.dart';
import 'login_action_button.dart';
import 'login_field.dart';
import 'login_options_row.dart';

class LoginCard extends ConsumerStatefulWidget {
  const LoginCard({super.key});

  @override
  ConsumerState<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends ConsumerState<LoginCard> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(loginControllerProvider);
    _emailController = TextEditingController(text: state.email);
    _passwordController = TextEditingController(text: state.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return CustomPaint(
      painter: const _LoginCardPainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 24 : 40,
          40,
          isCompact ? 24 : 40,
          34,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: VaultLockIcon(size: Size(72, 84), strokeWidth: 4.2),
            ),
            const SizedBox(height: 34),
            const _LoginHeading(),
            const SizedBox(height: 52),
            LoginField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              leading: const Text(
                '@',
                style: TextStyle(
                  color: AppColors.vaultMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
              onChanged: controller.emailChanged,
            ),
            const SizedBox(height: 30),
            LoginField(
              label: 'Password',
              controller: _passwordController,
              obscureText: state.obscurePassword,
              leading: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.vaultMuted,
                size: 24,
              ),
              trailing: IconButton(
                onPressed: controller.togglePasswordVisibility,
                icon: Icon(
                  state.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.vaultMuted,
                  size: 25,
                ),
              ),
              onChanged: controller.passwordChanged,
            ),
            const SizedBox(height: 24),
            LoginOptionsRow(
              rememberMe: state.rememberMe,
              onRememberChanged: controller.rememberMeChanged,
            ),
            if (state.status == LoginStatus.failure) ...[
              const SizedBox(height: 18),
              Text(
                state.errorMessage ?? 'Unable to unlock vault.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFB4AB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: state.status == LoginStatus.failure ? 18 : 32),
            LoginActionButton(
              isLoading: state.isLoading,
              onPressed: controller.submit,
            ),
            const SizedBox(height: 44),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: AppColors.vaultText),
              child: const Text(
                'Don\'t have an account? Register',
                style: TextStyle(
                  color: AppColors.vaultText,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeading extends StatelessWidget {
  const _LoginHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppConstants.appName.toUpperCase(),
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.vaultText,
              fontFamily: 'Times New Roman',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 4.4,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 0,
                  color: AppColors.vaultBlack,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Welcome back, Operator',
          style: TextStyle(
            color: AppColors.vaultMuted,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _LoginCardPainter extends CustomPainter {
  const _LoginCardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF0B1F31).withValues(alpha: 0.92)
        ..style = PaintingStyle.fill,
    );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.72),
          radius: 0.55,
          colors: [
            AppColors.vaultText.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.vaultText.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
