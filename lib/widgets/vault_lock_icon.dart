import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VaultLockIcon extends StatelessWidget {
  const VaultLockIcon({
    this.size = const Size(112, 132),
    this.color = AppColors.vaultBlack,
    this.strokeWidth = 6.4,
    super.key,
  });

  final Size size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _VaultLockPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _VaultLockPainter extends CustomPainter {
  const _VaultLockPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.38,
        size.width * 0.68,
        size.height * 0.43,
      ),
      Radius.circular(size.width * 0.07),
    );
    canvas.drawRRect(body, stroke);

    final shackle = Path()
      ..moveTo(size.width * 0.34, size.height * 0.39)
      ..lineTo(size.width * 0.34, size.height * 0.28)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.09,
        size.width * 0.66,
        size.height * 0.09,
        size.width * 0.66,
        size.height * 0.28,
      )
      ..lineTo(size.width * 0.66, size.height * 0.39);
    canvas.drawPath(shackle, stroke);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.59),
      size.width * 0.089,
      fill,
    );

    final keyStem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.78
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.62),
      Offset(size.width * 0.5, size.height * 0.75),
      keyStem,
    );
  }

  @override
  bool shouldRepaint(covariant _VaultLockPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
