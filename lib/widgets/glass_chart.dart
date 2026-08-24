import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/market_service.dart';
import '../theme/noah_theme.dart';

/// TradingView-style chart widget with glass morphism
class GlassChartWidget extends StatelessWidget {
  final String symbol;
  final MarketService market;
  final double height;
  final void Function(String text, String? imageBase64)? onShareToChat;

  const GlassChartWidget({
    super.key,
    required this.symbol,
    required this.market,
    this.height = 280,
    this.onShareToChat,
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

    final klines = market.klinesMap[symbol] ?? [];
    final price = prices[symbol] ?? 0;
    final pct = pcts[symbol] ?? 0;
    final up = pct >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg1.withValues(alpha: isDark ? 0.7 : 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    '$symbol/USDT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t0,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: up
                          ? green.withValues(alpha: 0.12)
                          : red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${up ? '+' : ''}${pct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: up ? green : red,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fmt(price),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chart area
              Expanded(
                child: klines.length >= 20
                    ? _buildCandlestickChart(klines, isDark, green, red, accent)
                    : _buildPlaceholder(t2),
              ),
              // Timeframe chips
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['1H', '4H', '1D', '1W'].map((tf) {
                  final isActive = tf == '1H';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? accent.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      tf,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? accent : t2,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandlestickChart(
    List<Kline> klines,
    bool isDark,
    Color green,
    Color red,
    Color accent,
  ) {
    final closes = klines.map((k) => k.close).toList();
    final highs = klines.map((k) => k.high).toList();
    final lows = klines.map((k) => k.low).toList();
    final minVal = lows.reduce(min);
    final maxVal = highs.reduce(max);
    final range = maxVal - minVal;

    return CustomPaint(
      painter: _CandlestickPainter(
        klines: klines,
        closes: closes,
        minVal: minVal,
        range: range,
        green: green,
        red: red,
        accent: accent,
        isDark: isDark,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildPlaceholder(Color t2) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.candlestick_chart, size: 32, color: t2.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            'Chargement du graphique...',
            style: TextStyle(fontSize: 11, color: t2),
          ),
        ],
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<Kline> klines;
  final List<double> closes;
  final double minVal;
  final double range;
  final Color green;
  final Color red;
  final Color accent;
  final bool isDark;

  _CandlestickPainter({
    required this.klines,
    required this.closes,
    required this.minVal,
    required this.range,
    required this.green,
    required this.red,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty || range <= 0) return;

    final w = size.width;
    final h = size.height;
    final candleW = max(w / klines.length * 0.6, 1.0);
    final gap = w / klines.length;

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Candles
    for (int i = 0; i < klines.length; i++) {
      final k = klines[i];
      final x = i * gap + gap / 2;
      final isUp = k.close >= k.open;

      final high = ((k.high - minVal) / range) * h;
      final low = ((k.low - minVal) / range) * h;
      final open = ((k.open - minVal) / range) * h;
      final close = ((k.close - minVal) / range) * h;

      final color = isUp ? green : red;

      // Wick
      final wickPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, h - high),
        Offset(x, h - low),
        wickPaint,
      );

      // Body
      final bodyPaint = Paint()..color = color;
      final bodyTop = h - max(open, close);
      final bodyHeight = max((open - close).abs(), 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - candleW / 2, bodyTop, candleW, bodyHeight),
          Radius.circular(candleW / 4),
        ),
        bodyPaint,
      );
    }

    // Moving average line (SMA20)
    if (closes.length >= 20) {
      final maPaint = Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (int i = 19; i < closes.length; i++) {
        double sum = 0;
        for (int j = i - 19; j <= i; j++) {
          sum += closes[j];
        }
        final sma = sum / 20;
        final y = h - ((sma - minVal) / range) * h;
        final x = i * gap + gap / 2;
        if (i == 19) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, maPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
