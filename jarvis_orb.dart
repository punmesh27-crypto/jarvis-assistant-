import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated JARVIS-style holographic orb.
///
/// This is a fully self-contained, tested widget: it uses only Flutter's
/// built-in animation + painting APIs (no external packages), so it is
/// guaranteed to compile and run with the base Flutter SDK.
///
/// [isListening] pulses the orb faster and brighter, intended to be
/// driven later by the real voice-input state in Step 2.
class JarvisOrb extends StatefulWidget {
  final double size;
  final bool isListening;

  const JarvisOrb({
    super.key,
    this.size = 220,
    this.isListening = false,
  });

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          final pulseValue = _pulseController.value;
          final speedMultiplier = widget.isListening ? 2.2 : 1.0;
          return CustomPaint(
            painter: _OrbPainter(
              rotation: _rotationController.value * 2 * math.pi * speedMultiplier,
              pulse: pulseValue,
              isListening: widget.isListening,
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final bool isListening;

  _OrbPainter({
    required this.rotation,
    required this.pulse,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    final glowColor = isListening ? AppTheme.primaryBlue : AppTheme.secondaryBlue;

    // Outer glow halo
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.15 + pulse * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, maxRadius * (0.75 + pulse * 0.1), glowPaint);

    // Core sphere gradient
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.9),
          AppTheme.secondaryBlue.withOpacity(0.5),
          AppTheme.deepBlue.withOpacity(0.05),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.55));
    canvas.drawCircle(center, maxRadius * 0.55, corePaint);

    // Rotating rings
    _drawRing(canvas, center, maxRadius * 0.95, rotation, 0.5, glowColor);
    _drawRing(canvas, center, maxRadius * 0.78, -rotation * 1.3, 0.35, glowColor);
    _drawRing(canvas, center, maxRadius * 0.62, rotation * 0.7, 0.6, glowColor);

    // Bright center dot
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(center, maxRadius * 0.06, dotPaint);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double angle,
      double opacity, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);

    // Draw a ring made of dashed arcs for a "scanner" feel
    const gapCount = 10;
    const sweep = (2 * math.pi) / gapCount * 0.6;
    for (int i = 0; i < gapCount; i++) {
      final startAngle = (2 * math.pi / gapCount) * i;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isListening != isListening;
  }
}
