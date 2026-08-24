import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'widget_card.dart';
import 'pnl_chart_painter.dart';

class ChartWidget extends StatefulWidget {
  final PortfolioData? data;

  const ChartWidget({super.key, required this.data});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant ChartWidget old) {
    super.didUpdateWidget(old);
    if (widget.data != old.data) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    final points = generateChartPoints(widget.data);
    final maxVal = points.isEmpty ? 10000.0 : points.reduce(max);
    final minVal = points.isEmpty ? 0.0 : points.reduce(min);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    return WidgetCard(
      title: 'Évolution',
      subtitle: 'Capital dans le temps',
      icon: Icons.show_chart,
      iconColor: const Color(0xFFC2A878),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return CustomPaint(
            size: Size.infinite,
            painter: PnLChartPainter(
              points: points,
              progress: _anim.value,
              minVal: minVal,
              range: range,
              gridColor: t2.withValues(alpha: 0.12),
              upColor: green,
              downColor: red,
            ),
          );
        },
      ),
    );
  }
}
