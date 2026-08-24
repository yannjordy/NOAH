import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/noah_theme.dart';

/// Equity curve chart with glass morphism
class GlassEquityCurve extends StatelessWidget {
  final List<double> dailyReturns;
  final double initialCapital;
  final double currentCapital;
  final double height;

  const GlassEquityCurve({
    super.key,
    required this.dailyReturns,
    required this.initialCapital,
    required this.currentCapital,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);

    final equity = <double>[];
    double cum = initialCapital;
    equity.add(cum);
    for (final r in dailyReturns) {
      cum *= (1 + r / 100);
      equity.add(cum);
    }
    if (equity.length < 2) equity.add(currentCapital);

    final minEq = equity.reduce(min);
    final maxEq = equity.reduce(max);
    final range = maxEq - minEq;
    final isUp = currentCapital >= initialCapital;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg1.withOpacity( isDark ? 0.7 : 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Courbe d\'équité', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                  const Spacer(),
                  Text(
                    '${isUp ? '+' : ''}${((currentCapital - initialCapital) / initialCapital * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isUp ? green : red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: range > 0
                    ? CustomPaint(
                        size: Size.infinite,
                        painter: _EquityPainter(
                          equity: equity,
                          minVal: minEq,
                          range: range,
                          color: isUp ? green : red,
                          accent: accent,
                          isDark: isDark,
                        ),
                      )
                    : Center(
                        child: Text('Pas encore de données', style: TextStyle(fontSize: 11, color: t2)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquityPainter extends CustomPainter {
  final List<double> equity;
  final double minVal;
  final double range;
  final Color color;
  final Color accent;
  final bool isDark;

  _EquityPainter({
    required this.equity,
    required this.minVal,
    required this.range,
    required this.color,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (equity.length < 2 || range <= 0) return;

    final w = size.width;
    final h = size.height;
    final step = w / (equity.length - 1);

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(0, h);
    for (int i = 0; i < equity.length; i++) {
      final x = i * step;
      final y = h - ((equity[i] - minVal) / range) * h;
      if (i == 0) fillPath.lineTo(x, y);
      else fillPath.lineTo(x, y);
    }
    fillPath.lineTo(w, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity( 0.2),
          color.withOpacity( 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final linePath = Path();
    for (int i = 0; i < equity.length; i++) {
      final x = i * step;
      final y = h - ((equity[i] - minVal) / range) * h;
      if (i == 0) linePath.moveTo(x, y);
      else linePath.lineTo(x, y);
    }
    canvas.drawPath(linePath, linePaint);

    // Last point dot
    final lastX = (equity.length - 1) * step;
    final lastY = h - ((equity.last - minVal) / range) * h;
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      2,
      Paint()..color = bg1,
    );
  }

  Color get bg1 => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Glass pie chart for portfolio allocation
class GlassPieChart extends StatelessWidget {
  final List<({String label, double value, Color color})> segments;
  final double size;

  const GlassPieChart({
    super.key,
    required this.segments,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    final total = segments.fold(0.0, (s, seg) => s + seg.value);

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PiePainter(
              segments: segments,
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: segments.where((s) => s.value > 0).map((s) {
            final pct = total > 0 ? (s.value / total * 100) : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  '${s.label} ${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 10, color: t2, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<({String label, double value, Color color})> segments;
  final double total;

  _PiePainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final innerRadius = radius * 0.55;

    double startAngle = -pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * 2 * pi;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Inner circle (donut)
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
    );
  }

  bool get isDark => false;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
