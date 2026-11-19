import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HologramInterface extends StatefulWidget {
  const HologramInterface({super.key});

  @override
  State<HologramInterface> createState() => _HologramInterfaceState();
}

class _HologramInterfaceState extends State<HologramInterface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HologramPainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _HologramPainter extends CustomPainter {
  final double progress;

  _HologramPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.32;

    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);

    canvas.drawCircle(center, radius * 1.4, glowPaint);

    final ringPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, ringPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    final outerPaint = Paint()
      ..color = AppTheme.secondaryBlue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.2),
      0,
      math.pi * 1.4,
      false,
      outerPaint,
    );

    canvas.restore();

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5, dotPaint);

    final linePaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.25)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.92, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HologramPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}





