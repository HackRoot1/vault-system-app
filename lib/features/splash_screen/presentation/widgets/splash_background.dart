import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _SplashBackgroundPainter(),
      child: SizedBox.expand(child: child),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.vaultNavyDeep,
          AppColors.vaultNavy,
          Color(0xFF071C2F),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 0.52,
        colors: [
          AppColors.vaultSurface.withValues(alpha: 0.78),
          AppColors.vaultSurface.withValues(alpha: 0.26),
          Colors.transparent,
        ],
        stops: const [0, 0.36, 1],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final verticalLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.099, size.height * 0.156),
      Offset(size.width * 0.099, size.height * 0.244),
      verticalLinePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.833, size.height * 0.648),
      Offset(size.width * 0.833, size.height * 0.793),
      verticalLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
