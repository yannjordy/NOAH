import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';

class PnLChartPainter extends CustomPainter {
  final List<double> points;
  final double progress;
  final double minVal;
  final double range;
  final Color gridColor;
  final Color upColor;
  final Color downColor;

  PnLChartPainter({
    required this.points,
    required this.progress,
    required this.minVal,
    required this.range,
    required this.gridColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final h = size.height;
    final w = size.width;
    final count = (points.length * progress).ceil().clamp(2, points.length);
    final visible = points.sublist(0, count);

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final stepX = w / (visible.length - 1).clamp(1, double.infinity);

    double yVal(int i) => h - ((visible[i] - minVal) / range * h * 0.85 + h * 0.075);

    for (int i = 1; i < visible.length; i++) {
      final x0 = (i - 1) * stepX;
      final x1 = i * stepX;
      final y0 = yVal(i - 1);
      final y1 = yVal(i);
      final goingUp = visible[i] >= visible[i - 1];
      final segColor = goingUp ? upColor : downColor;

      final segPath = Path()
        ..moveTo(x0, y0)
        ..lineTo(x1, y1)
        ..lineTo(x1, h)
        ..lineTo(x0, h)
        ..close();
      canvas.drawPath(segPath, Paint()..color = segColor.withValues(alpha: 0.08));
    }

    for (int i = 1; i < visible.length; i++) {
      final x0 = (i - 1) * stepX;
      final x1 = i * stepX;
      final y0 = yVal(i - 1);
      final y1 = yVal(i);
      final goingUp = visible[i] >= visible[i - 1];
      final segColor = goingUp ? upColor : downColor;

      final segPath = Path()
        ..moveTo(x0, y0)
        ..lineTo(x1, y1);
      canvas.drawPath(segPath, Paint()
        ..color = segColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    if (visible.isNotEmpty) {
      final lastX = (visible.length - 1) * stepX;
      final lastY = yVal(visible.length - 1);
      final lastUp = visible.length > 1 && visible.last >= visible[visible.length - 2];
      final dotColor = lastUp ? upColor : downColor;
      canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = dotColor);
      canvas.drawCircle(Offset(lastX, lastY), 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant PnLChartPainter old) =>
      old.progress != progress || old.points != points;
}

List<double> generateChartPoints(PortfolioData? portfolioData) {
  if (portfolioData == null) return _demoCurve(10000, 0);
  final points = <double>[];
  var bal = 10000.0;
  points.add(bal);
  for (final t in portfolioData.walletHistory) {
    if (t.type == 'deposit') bal += t.amount;
    else bal -= t.amount;
    points.add(bal);
  }
  for (final t in portfolioData.history) {
    if (t.side == 'sell') {
      bal += t.qty * t.price;
    } else if (t.side == 'buy') {
      bal -= t.qty * t.price;
    }
    points.add(bal);
  }
  if (points.length <= 2) {
    return _demoCurve(bal, points.last - points.first);
  }
  return points;
}

List<double> _demoCurve(double base, double delta) {
  final pts = <double>[];
  final r = Random();
  var v = base - 500;
  for (int i = 0; i < 30; i++) {
    v += r.nextDouble() * 80 - 30 + delta / 30;
    v = v.clamp(base - 1500, base + 1500);
    pts.add(v);
  }
  pts.add(base + delta);
  return pts;
}
