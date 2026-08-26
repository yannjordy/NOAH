import 'dart:math';
import 'package:flutter/material.dart';

class NoahLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? text;

  const NoahLoader({super.key, this.size = 48, this.color, this.text});

  @override
  State<NoahLoader> createState() => _NoahLoaderState();
}

class _NoahLoaderState extends State<NoahLoader> with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFFC2A878);
    final s = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotateController, _pulseController, _waveController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _NoahLoaderPainter(
                  rotation: _rotateController.value,
                  pulse: _pulseController.value,
                  wave: _waveController.value,
                  color: color,
                ),
              );
            },
          ),
        ),
        if (widget.text != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.text!,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _NoahLoaderPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final double wave;
  final Color color;

  _NoahLoaderPainter({
    required this.rotation,
    required this.pulse,
    required this.wave,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring - rotating
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final ringRect = Rect.fromCircle(center: center, radius: radius * 0.85);
    final startAngle = rotation * 2 * pi;

    // Gradient effect on ring
    for (int i = 0; i < 12; i++) {
      final angle = startAngle + (i * pi * 2 / 12);
      final alpha = ((12 - i) / 12 * 255).toInt();
      ringPaint.color = color.withValues(alpha: alpha / 255);
      canvas.drawArc(
        ringRect,
        angle,
        pi * 2 / 12,
        false,
        ringPaint,
      );
    }

    // Inner circle - pulsing
    final pulseRadius = radius * (0.35 + pulse * 0.1);
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.15 + pulse * 0.1);
    canvas.drawCircle(center, pulseRadius, innerPaint);

    // Center dot
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(center, radius * 0.12, dotPaint);

    // Orbiting dots (3 dots)
    final dotPaint2 = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final angle = rotation * 2 * pi + (i * 2 * pi / 3);
      final orbitRadius = radius * 0.6;
      final dotCenter = Offset(
        center.dx + cos(angle) * orbitRadius,
        center.dy + sin(angle) * orbitRadius,
      );
      final dotAlpha = (0.4 + (wave + sin(wave * pi + i)) * 0.3).clamp(0.0, 1.0);
      dotPaint2.color = color.withValues(alpha: dotAlpha);
      canvas.drawCircle(dotCenter, radius * 0.06 + pulse * 2, dotPaint2);
    }

    // Subtle glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = color.withValues(alpha: 0.08 + pulse * 0.05);
    canvas.drawCircle(center, radius * 0.5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _NoahLoaderPainter oldDelegate) =>
      rotation != oldDelegate.rotation ||
      pulse != oldDelegate.pulse ||
      wave != oldDelegate.wave;
}
