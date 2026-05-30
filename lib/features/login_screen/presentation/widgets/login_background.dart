import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _LoginBackgroundPainter(),
      child: SizedBox.expand(child: child),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.vaultNavyDeep,
            AppColors.vaultNavy,
            Color(0xFF061827),
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.02, -0.4),
          radius: 0.82,
          colors: [
            AppColors.vaultSurface.withValues(alpha: 0.32),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
