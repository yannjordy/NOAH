import 'dart:math';
import 'package:flutter/material.dart';

enum BlockType { text, signalHeader, priceCard, chartPreview, riskGauge, portfolioSummary, factorGrid, divider, signalCard, table, lineChart, pieChart, barChart, tradingToggle }

class MessageBlock {
  final BlockType type;
  final Map<String, dynamic> data;

  MessageBlock._({required this.type, required this.data});

  MessageBlock.fromJson(Map<String, dynamic> json)
      : type = BlockType.values.firstWhere((e) => e.name == json['type']),
        data = Map<String, dynamic>.from(json['data'] as Map? ?? {});

  Map<String, dynamic> toJson() => {'type': type.name, 'data': data};

  factory MessageBlock.text(String text) =>
      MessageBlock._(type: BlockType.text, data: {'text': text});

  factory MessageBlock.signalHeader({
    required String action,
    required double confidence,
    required String symbol,
    required double price,
    required double change,
    required String period,
  }) =>
      MessageBlock._(
        type: BlockType.signalHeader,
        data: {
          'action': action,
          'confidence': confidence,
          'symbol': symbol,
          'price': price,
          'change': change,
          'period': period,
        },
      );

  factory MessageBlock.priceCard({
    required String symbol,
    required double price,
    required double change,
    required bool isUp,
  }) =>
      MessageBlock._(
        type: BlockType.priceCard,
        data: {'symbol': symbol, 'price': price, 'change': change, 'isUp': isUp},
      );

  factory MessageBlock.chartPreview({
    required List<double> closes,
    required String symbol,
  }) =>
      MessageBlock._(
        type: BlockType.chartPreview,
        data: {'closes': closes, 'symbol': symbol},
      );

  factory MessageBlock.riskGauge({
    required double riskScore,
    required double exposure,
    required double dailyDrawdown,
    required bool circuitBreaker,
    required String riskLevel,
  }) =>
      MessageBlock._(
        type: BlockType.riskGauge,
        data: {
          'riskScore': riskScore,
          'exposure': exposure,
          'dailyDrawdown': dailyDrawdown,
          'circuitBreaker': circuitBreaker,
          'riskLevel': riskLevel,
        },
      );

  factory MessageBlock.portfolioSummary({
    required double usdt,
    required double posValue,
    required double pnl,
    required double pnlPct,
    required int positionCount,
    required double totalValue,
    required double usdtRatio,
  }) =>
      MessageBlock._(
        type: BlockType.portfolioSummary,
        data: {
          'usdt': usdt,
          'posValue': posValue,
          'pnl': pnl,
          'pnlPct': pnlPct,
          'positionCount': positionCount,
          'totalValue': totalValue,
          'usdtRatio': usdtRatio,
        },
      );

  factory MessageBlock.factorGrid(Map<String, dynamic> factors) =>
      MessageBlock._(type: BlockType.factorGrid, data: {'factors': factors});

  factory MessageBlock.divider() =>
      MessageBlock._(type: BlockType.divider, data: {});

  factory MessageBlock.tradingToggle({required bool isActive}) =>
      MessageBlock._(
        type: BlockType.tradingToggle,
        data: {'isActive': isActive},
      );

  factory MessageBlock.signalCard({
    required String action,
    required double confidence,
    required String symbol,
    required bool isActive,
  }) =>
      MessageBlock._(
        type: BlockType.signalCard,
        data: {
          'action': action,
          'confidence': confidence,
          'symbol': symbol,
          'isActive': isActive,
        },
      );

  factory MessageBlock.table({
    required List<String> headers,
    required List<List<String>> rows,
    required String title,
  }) =>
      MessageBlock._(
        type: BlockType.table,
        data: {'headers': headers, 'rows': rows, 'title': title},
      );

  factory MessageBlock.lineChart({
    required List<double> series,
    required String label,
    String? symbol,
    Color? color,
  }) =>
      MessageBlock._(
        type: BlockType.lineChart,
        data: {
          'series': series,
          'label': label,
          'symbol': symbol ?? '',
          'color': color?.value ?? 0,
        },
      );

  factory MessageBlock.pieChart({
    required List<String> labels,
    required List<double> values,
    required String title,
    List<int>? colors,
  }) =>
      MessageBlock._(
        type: BlockType.pieChart,
        data: {
          'labels': labels,
          'values': values,
          'title': title,
          'colors': colors ?? [],
        },
      );

  factory MessageBlock.barChart({
    required List<String> labels,
    required List<double> values,
    required String title,
    Color? color,
  }) =>
      MessageBlock._(
        type: BlockType.barChart,
        data: {
          'labels': labels,
          'values': values,
          'title': title,
          'color': color?.value ?? 0,
        },
      );
}

// ─── RENDERERS ───────────────────────────────────────

const _accentLight = Color(0xFFB08D57);
const _accentDark = Color(0xFFC2A878);
const _greenLight = Color(0xFF2E7D5E);
const _greenDark = Color(0xFF4CAF8E);
const _redLight = Color(0xFFB8453A);
const _redDark = Color(0xFFE07060);
const _amberLight = Color(0xFFA67C2E);
const _amberDark = Color(0xFFD4A84B);

Color accent(bool d) => d ? _accentDark : _accentLight;
Color green(bool d) => d ? _greenDark : _greenLight;
Color red(bool d) => d ? _redDark : _redLight;
Color amber(bool d) => d ? _amberDark : _amberLight;

Color actionColor(String action, bool isDark) {
  switch (action) {
    case 'BUY':
    case 'STRONG_BUY':
      return green(isDark);
    case 'SELL':
    case 'STRONG_SELL':
      return red(isDark);
    default:
      return amber(isDark);
  }
}

Widget renderBlock(MessageBlock block, bool isDark, {VoidCallback? onTap}) {
  switch (block.type) {
    case BlockType.text:
      return _TextBlock(block, isDark);
    case BlockType.signalHeader:
      return _SignalHeaderBlock(block, isDark);
    case BlockType.priceCard:
      return _PriceCardBlock(block, isDark);
    case BlockType.chartPreview:
      return _ChartPreviewBlock(block, isDark);
    case BlockType.riskGauge:
      return _RiskGaugeBlock(block, isDark);
    case BlockType.portfolioSummary:
      return _PortfolioSummaryBlock(block, isDark, onTap: onTap);
    case BlockType.factorGrid:
      return _FactorGridBlock(block, isDark);
    case BlockType.divider:
      return _DividerBlock(isDark);
    case BlockType.signalCard:
      return _SignalCardBlock(block, isDark);
    case BlockType.table:
      return _TableBlock(block, isDark);
    case BlockType.lineChart:
      return _AnimatedLineChart(block, isDark);
    case BlockType.pieChart:
      return _AnimatedPieChart(block, isDark);
    case BlockType.barChart:
      return _AnimatedBarChart(block, isDark);
    case BlockType.tradingToggle:
      return _TradingToggleBlock(block, isDark, onTap: onTap);
  }
}

// ── Trading Toggle ──────────────────────────────────
class _TradingToggleBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  final VoidCallback? onTap;
  const _TradingToggleBlock(this.b, this.d, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = b.data['isActive'] as bool? ?? false;
    final accent = d ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final green = d ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [green.withOpacity( 0.12), green.withOpacity( 0.03)]
                  : [accent.withOpacity( 0.15), accent.withOpacity( 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? green.withOpacity( 0.2) : accent.withOpacity( 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive ? green.withOpacity( 0.2) : accent.withOpacity( 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? Icons.auto_graph : Icons.swap_vert,
                  size: 16, color: isActive ? green : accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Trading IA Actif' : 'Activer le Trading IA',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? green : accent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? 'Appuyez pour désactiver' : 'NOAH gère vos trades 24/7',
                      style: TextStyle(fontSize: 9, color: d ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C)),
                    ),
                  ],
                ),
              ),
              Icon(
                isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                size: 28, color: isActive ? green : d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Text ─────────────────────────────────────────────
class _TextBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  const _TextBlock(this.b, this.d);

  String _clean(String t) {
    return t
        .replaceAll('**', '')
        .replaceAll('## ', '')
        .replaceAll('__', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final t = _clean(b.data['text'] as String? ?? '');
    if (t.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: TextStyle(fontSize: 13.5, height: 1.55, color: d ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
    );
  }
}

// ── Signal Header ────────────────────────────────────
class _SignalHeaderBlock extends StatefulWidget {
  final MessageBlock b;
  final bool d;
  const _SignalHeaderBlock(this.b, this.d);

  @override
  State<_SignalHeaderBlock> createState() => _SignalHeaderBlockState();
}

class _SignalHeaderBlockState extends State<_SignalHeaderBlock> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _pulseCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.b.data['action'] as String? ?? 'HOLD';
    final conf = widget.b.data['confidence'] as double? ?? 0;
    final symbol = widget.b.data['symbol'] as String? ?? 'BTC';
    final price = widget.b.data['price'] as double? ?? 0;
    final change = widget.b.data['change'] as double? ?? 0;
    final period = widget.b.data['period'] as String? ?? '24h';
    final ac = actionColor(action, widget.d);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [ac.withOpacity( 0.15), ac.withOpacity( 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ac.withOpacity( 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(symbol, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ac, fontFamily: 'PlayfairDisplay')),
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: ac.withOpacity( 0.15 + _pulseCtrl.value * 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ac.withOpacity( 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action == 'BUY' || action == 'STRONG_BUY' ? Icons.arrow_upward : action == 'SELL' || action == 'STRONG_SELL' ? Icons.arrow_downward : Icons.remove,
                            size: 14, color: ac,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            action.replaceAll('_', ' '),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ac, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', color: widget.d ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (change >= 0 ? green(widget.d) : red(widget.d)).withOpacity( 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', color: change >= 0 ? green(widget.d) : red(widget.d))),
                  ),
                  const Spacer(),
                  Text(period, style: TextStyle(fontSize: 10, color: widget.d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(color: widget.d ? const Color(0xFF323232) : const Color(0xFFE8E3D8), child: FractionallySizedBox(
                          widthFactor: conf,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [ac.withOpacity( 0.3), ac], begin: Alignment.centerLeft, end: Alignment.centerRight),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Confiance', style: TextStyle(fontSize: 9, color: widget.d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
                    Text('${(conf * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ac, fontFamily: 'JetBrainsMono')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price Card ───────────────────────────────────────
class _PriceCardBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  const _PriceCardBlock(this.b, this.d);

  @override
  Widget build(BuildContext context) {
    final symbol = b.data['symbol'] as String? ?? '';
    final price = b.data['price'] as double? ?? 0;
    final change = b.data['change'] as double? ?? 0;
    final up = b.data['isUp'] as bool? ?? true;
    final c = up ? green(d) : red(d);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: d ? const Color(0x0DFFFFFF) : const Color(0x0F000000))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: c.withOpacity( 0.15), shape: BoxShape.circle),
            child: Center(child: Icon(up ? Icons.trending_up : Icons.trending_down, size: 16, color: c)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$symbol/USDT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: d ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C))),
              const SizedBox(height: 2),
              Text('\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', color: d ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
            ],
          ),
          const Spacer(),
          Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', color: c)),
        ],
      ),
    );
  }
}

// ── Chart Preview (mini sparkline) ───────────────────
class _ChartPreviewBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  const _ChartPreviewBlock(this.b, this.d);

  @override
  Widget build(BuildContext context) {
    final closes = (b.data['closes'] as List<dynamic>?)?.cast<double>() ?? [];
    final symbol = b.data['symbol'] as String? ?? '';
    if (closes.length < 2) return const SizedBox();

    final lowVal = closes.reduce(min);
    final highVal = closes.reduce(max);
    final range = highVal - lowVal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: d ? const Color(0x0DFFFFFF) : const Color(0x0F000000))),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparklinePainter(closes: closes, minVal: lowVal, range: range, color: closes.last >= closes.first ? green(d) : red(d), isDark: d),
            ),
          ),
          const SizedBox(width: 8),
          Text(symbol, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> closes;
  final double minVal, range;
  final Color color;
  final bool isDark;

  _SparklinePainter({required this.closes, required this.minVal, required this.range, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (range == 0 || closes.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity( 0.25), color.withOpacity( 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (closes.length - 1);

    for (int i = 0; i < closes.length; i++) {
      final x = i * stepX;
      final y = size.height - ((closes[i] - minVal) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.closes != closes || old.color != color;
}

// ── Risk Gauge ───────────────────────────────────────
class _RiskGaugeBlock extends StatefulWidget {
  final MessageBlock b;
  final bool d;
  const _RiskGaugeBlock(this.b, this.d);

  @override
  State<_RiskGaugeBlock> createState() => _RiskGaugeBlockState();
}

class _RiskGaugeBlockState extends State<_RiskGaugeBlock> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riskScore = widget.b.data['riskScore'] as double? ?? 0;
    final exposure = widget.b.data['exposure'] as double? ?? 0;
    final dd = widget.b.data['dailyDrawdown'] as double? ?? 0;
    final cb = widget.b.data['circuitBreaker'] as bool? ?? false;
    final rl = widget.b.data['riskLevel'] as String? ?? 'LOW';

    final riskColor = riskScore < 0.2 ? green(widget.d) : riskScore < 0.5 ? amber(widget.d) : red(widget.d);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final r = riskScore * _anim.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cb ? red(widget.d).withOpacity( 0.5) : widget.d ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(cb ? Icons.warning : Icons.shield_outlined, size: 14, color: cb ? red(widget.d) : riskColor),
                  const SizedBox(width: 6),
                  Text('Risque: $rl', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cb ? red(widget.d) : riskColor, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _gaugeBar('Risque', r, riskColor, widget.d),
                  const SizedBox(width: 6),
                  _gaugeBar('Exposition', (exposure).clamp(0.0, 1.0), amber(widget.d), widget.d),
                  const SizedBox(width: 6),
                  _gaugeBar('Drawdown', (dd.abs()).clamp(0.0, 1.0), red(widget.d), widget.d),
                ],
              ),
              if (cb)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: red(widget.d).withOpacity( 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: red(widget.d).withOpacity( 0.3))),
                    child: Text('Circuit Breaker activé', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: red(widget.d))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _gaugeBar(String label, double value, Color c, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    child: Container(color: isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4), child: FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(color: c),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Portfolio Summary ────────────────────────────────
class _PortfolioSummaryBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  final VoidCallback? onTap;
  const _PortfolioSummaryBlock(this.b, this.d, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final usdt = b.data['usdt'] as double? ?? 0;
    final pnl = b.data['pnl'] as double? ?? 0;
    final pnlPct = b.data['pnlPct'] as double? ?? 0;
    final count = b.data['positionCount'] as int? ?? 0;
    final total = b.data['totalValue'] as double? ?? 0;
    final usdtRatio = b.data['usdtRatio'] as double? ?? 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: d ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 14, color: d ? const Color(0xFFC2A878) : const Color(0xFFB08D57)),
                const SizedBox(width: 6),
                Text('Portefeuille', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: d ? const Color(0xFFC2A878) : const Color(0xFFB08D57))),
                const Spacer(),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 14, color: d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _cell('Total', '\$${total.toStringAsFixed(0)}', d),
                _cell('USDT', '\$${usdt.toStringAsFixed(0)}', d),
                _cell('Positions', count.toString(), d),
                _cell('PnL', '${pnl >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%', d, color: pnl >= 0 ? green(d) : red(d)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: d ? const Color(0xFF282828) : const Color(0xFFF0ECE4), child: FractionallySizedBox(
                        widthFactor: (usdtRatio / 100).clamp(0.0, 1.0),
                        child: Container(color: d ? const Color(0xFFC2A878) : const Color(0xFFB08D57)),
                      )),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('USDT ${usdtRatio.toStringAsFixed(0)}%', style: TextStyle(fontSize: 8, color: d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
                  Text('Positions ${(100 - usdtRatio).toStringAsFixed(0)}%', style: TextStyle(fontSize: 8, color: d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String label, String value, bool isDark, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', color: color ?? (isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C)))),
        ],
      ),
    );
  }
}

// ── Factor Grid ──────────────────────────────────────
class _FactorGridBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  const _FactorGridBlock(this.b, this.d);

  @override
  Widget build(BuildContext context) {
    final factors = b.data['factors'] as Map<String, dynamic>? ?? {};
    if (factors.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: factors.entries.map((e) {
          final v = e.value.toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: d ? const Color(0xFF282828) : const Color(0xFFF0ECE4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${e.key}: ${v}', style: TextStyle(fontSize: 9, fontFamily: 'JetBrainsMono', color: d ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C))),
          );
        }).toList(),
      ),
    );
  }
}

// ── Divider ──────────────────────────────────────────
class _DividerBlock extends StatelessWidget {
  final bool d;
  const _DividerBlock(this.d);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(height: 1, color: d ? const Color(0x17FFFFFF) : const Color(0x1A000000)),
    );
  }
}

// ── Signal Card ──────────────────────────────────────
class _SignalCardBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  const _SignalCardBlock(this.b, this.d);

  @override
  Widget build(BuildContext context) {
    final action = b.data['action'] as String? ?? 'HOLD';
    final conf = b.data['confidence'] as double? ?? 0;
    final symbol = b.data['symbol'] as String? ?? '';
    final ac = actionColor(action, d);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.withOpacity( 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                action == 'BUY' || action == 'STRONG_BUY' ? Icons.arrow_upward : action == 'SELL' || action == 'STRONG_SELL' ? Icons.arrow_downward : Icons.remove,
                size: 14, color: ac,
              ),
              const SizedBox(width: 4),
              Text(action, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ac, letterSpacing: 0.6)),
              const SizedBox(width: 6),
              if (symbol.isNotEmpty)
                Text('$symbol/USDT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: d ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: d ? const Color(0xFF323232) : const Color(0xFFE8E3D8),
                      child: FractionallySizedBox(widthFactor: conf, child: Container(color: ac)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('${(conf * 100).toInt()}% confiance', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w700, color: ac)),
          ),
        ],
      ),
    );
  }
}

// ── Table ────────────────────────────────────────────
class _TableBlock extends StatelessWidget {
  final MessageBlock b;
  final bool d;
  const _TableBlock(this.b, this.d);

  @override
  Widget build(BuildContext context) {
    final headers = (b.data['headers'] as List<dynamic>?)?.cast<String>() ?? [];
    final rows = (b.data['rows'] as List<dynamic>?)?.map((r) => (r as List<dynamic>).cast<String>()).toList() ?? [];
    final title = b.data['title'] as String? ?? '';

    if (headers.isEmpty || rows.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: d ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: d ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C), letterSpacing: 0.5)),
            const SizedBox(height: 8),
          ],
          Table(
            defaultColumnWidth: const FlexColumnWidth(),
            children: [
              TableRow(
                children: headers.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(h, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C), letterSpacing: 0.4)),
                )).toList(),
              ),
              ...rows.map((row) => TableRow(
                children: row.map((cell) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(cell, style: TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: d ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
                )).toList(),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Animated Line Chart ──────────────────────────────
class _AnimatedLineChart extends StatefulWidget {
  final MessageBlock b;
  final bool d;
  const _AnimatedLineChart(this.b, this.d);

  @override
  State<_AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<_AnimatedLineChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _drawAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _drawAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = (widget.b.data['series'] as List<dynamic>?)?.cast<double>() ?? [];
    final label = widget.b.data['label'] as String? ?? '';
    if (series.length < 2) return const SizedBox();

    final c = Color(widget.b.data['color'] as int? ?? (widget.d ? 0xFF4CAF8E : 0xFF2E7D5E));
    final bg1 = widget.d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.d ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.d ? const Color(0xFFC2A878) : const Color(0xFFB08D57))),
            ),
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _drawAnim,
              builder: (_, __) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    series: series,
                    progress: _drawAnim.value,
                    color: c,
                    gridColor: widget.d ? const Color(0x17FFFFFF) : const Color(0x0F000000),
                    textColor: widget.d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C),
                    isDark: widget.d,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> series;
  final double progress;
  final Color color, gridColor, textColor;
  final bool isDark;

  _LineChartPainter({
    required this.series,
    required this.progress,
    required this.color,
    required this.gridColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hPad = 40.0, vPad = 20.0;
    final chartW = size.width - hPad * 2;
    final chartH = size.height - vPad * 2;
    if (chartW <= 0 || chartH <= 0 || series.length < 2) return;

    final minVal = series.reduce(min);
    final maxVal = series.reduce(max);
    final range = maxVal - minVal > 0 ? maxVal - minVal : 1.0;

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = vPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(hPad, y), Offset(hPad + chartW, y), gridPaint);
      final val = minVal + range * i / 4;
      final tp = TextPainter(
        text: TextSpan(text: _fmt(val), style: TextStyle(fontSize: 8, color: textColor)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: hPad - 4);
      tp.paint(canvas, Offset(hPad - tp.width - 4, y - tp.height / 2));
    }

    final visibleCount = max(2, (series.length * progress).ceil());
    final stepX = chartW / (series.length - 1);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity( 0.3), color.withOpacity( 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(hPad, vPad, chartW, chartH));

    final path = Path();
    final fillPath = Path();
    fillPath.moveTo(hPad, vPad + chartH);

    for (int i = 0; i < visibleCount; i++) {
      final x = hPad + i * stepX;
      final y = vPad + chartH - ((series[i] - minVal) / range) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (visibleCount > 0) {
      final lastX = hPad + (visibleCount - 1) * stepX;
      final lastY = vPad + chartH - ((series[visibleCount - 1] - minVal) / range) * chartH;
      canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
      canvas.drawCircle(Offset(lastX, lastY), 8, Paint()..color = color.withOpacity( 0.2));
    }

    fillPath.lineTo(hPad + (visibleCount - 1) * stepX, vPad + chartH);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  String _fmt(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 1) return '\$${v.toStringAsFixed(0)}';
    return v.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.progress != progress || old.series != series;
}

// ── Animated Pie Chart ───────────────────────────────
class _AnimatedPieChart extends StatefulWidget {
  final MessageBlock b;
  final bool d;
  const _AnimatedPieChart(this.b, this.d);

  @override
  State<_AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<_AnimatedPieChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = (widget.b.data['labels'] as List<dynamic>?)?.cast<String>() ?? [];
    final values = (widget.b.data['values'] as List<dynamic>?)?.cast<double>() ?? [];
    final title = widget.b.data['title'] as String? ?? '';
    final rawColors = (widget.b.data['colors'] as List<dynamic>?)?.cast<int>() ?? [];
    if (labels.isEmpty || values.isEmpty) return const SizedBox();

    final total = values.fold(0.0, (a, b) => a + b);
    final defaultColors = [0xFF4CAF8E, 0xFFC2A878, 0xFFE07060, 0xFF4285F4, 0xFFB388FF, 0xFFFF8A65];
    final bg1 = widget.d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.d ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.d ? const Color(0xFFC2A878) : const Color(0xFFB08D57))),
            ),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    return CustomPaint(
                      size: const Size(110, 110),
                      painter: _PieChartPainter(
                        values: values,
                        progress: _anim.value,
                        colors: rawColors.isNotEmpty
                            ? rawColors.map((c) => Color(c)).toList()
                            : defaultColors.map((c) => Color(c)).toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(labels.length, (i) {
                    final pct = total > 0 ? values[i] / total * 100 : 0.0;
                    final c = rawColors.isNotEmpty && i < rawColors.length
                        ? Color(rawColors[i])
                        : Color(defaultColors[i % defaultColors.length]);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(labels[i], style: TextStyle(fontSize: 10, color: widget.d ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C)), overflow: TextOverflow.ellipsis),
                          ),
                          Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', color: widget.d ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final double progress;
  final List<Color> colors;

  _PieChartPainter({required this.values, required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    final bgPaint = Paint()..color = const Color(0x0DFFFFFF)..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -pi / 2;
    final strokePaint = Paint()..color = const Color(0xFF1E1E1E)..style = PaintingStyle.stroke..strokeWidth = 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi * progress;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, strokePaint);
      startAngle += sweepAngle;
    }

    canvas.drawCircle(center, radius * 0.45, Paint()..color = const Color(0xFF1E1E1E));
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) => old.progress != progress || old.values != values;
}

// ── Animated Bar Chart ───────────────────────────────
class _AnimatedBarChart extends StatefulWidget {
  final MessageBlock b;
  final bool d;
  const _AnimatedBarChart(this.b, this.d);

  @override
  State<_AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<_AnimatedBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = (widget.b.data['labels'] as List<dynamic>?)?.cast<String>() ?? [];
    final values = (widget.b.data['values'] as List<dynamic>?)?.cast<double>() ?? [];
    final title = widget.b.data['title'] as String? ?? '';
    if (labels.isEmpty || values.isEmpty) return const SizedBox();

    final c = Color(widget.b.data['color'] as int? ?? (widget.d ? 0xFFC2A878 : 0xFFB08D57));
    final bg1 = widget.d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.d ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.d ? const Color(0xFFC2A878) : const Color(0xFFB08D57))),
            ),
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _BarChartPainter(
                    labels: labels,
                    values: values,
                    progress: _anim.value,
                    barColor: c,
                    gridColor: widget.d ? const Color(0x17FFFFFF) : const Color(0x0F000000),
                    textColor: widget.d ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final double progress;
  final Color barColor, gridColor, textColor;

  _BarChartPainter({
    required this.labels,
    required this.values,
    required this.progress,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hPad = 10.0, vPad = 10.0, bottomPad = 20.0;
    final chartW = size.width - hPad * 2;
    final chartH = size.height - vPad - bottomPad;
    if (chartW <= 0 || chartH <= 0 || values.isEmpty) return;

    final maxVal = values.reduce(max);
    final barW = chartW / values.length * 0.6;
    final gap = chartW / values.length * 0.4;

    for (int i = 0; i < values.length; i++) {
      final barH = (values[i] / maxVal) * chartH * progress;
      final x = hPad + i * (barW + gap) + gap / 2;
      final y = vPad + chartH - barH;
      final alpha = ((i + 1) / values.length * 0.5 + 0.3).clamp(0.3, 0.8);

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, barH), const Radius.circular(4)),
        Paint()..color = barColor.withOpacity( alpha),
      );

      if (labels.length > i) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: TextStyle(fontSize: 8, color: textColor)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: barW + gap);
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, vPad + chartH + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.progress != progress || old.values != values;
}
