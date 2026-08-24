import 'package:flutter/material.dart';
import '../theme/noah_theme.dart';

class OrderBook extends StatelessWidget {
  final List<List<double>> bids;
  final List<List<double>> asks;
  final String symbol;

  const OrderBook({
    super.key,
    required this.bids,
    required this.asks,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final t2 = isDark ? NoahColors.dkT2 : NoahColors.t2;
    final accent = isDark ? NoahColors.dkAccent : NoahColors.accent;
    final green = isDark ? NoahColors.dkGreen : NoahColors.green;
    final red = isDark ? NoahColors.dkRed : NoahColors.red;
    final border = isDark ? NoahColors.dkBorder : NoahColors.border;
    final bg1 = isDark ? NoahColors.dkBg1 : NoahColors.bg1;

    final maxBidVol = bids.fold(0.0, (p, e) => p > e[1] ? p : e[1]);
    final maxAskVol = asks.fold(0.0, (p, e) => p > e[1] ? p : e[1]);
    final maxVol = maxBidVol > maxAskVol ? maxBidVol : maxAskVol;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border),
        boxShadow: NoahTheme.shadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('Carnet d\'ordres $symbol/USDT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 3, child: Text('Prix', style: TextStyle(fontSize: 9, color: t2, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Volume', style: TextStyle(fontSize: 9, color: t2, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 9, color: t2, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = asks.length - 1; i >= 0; i--) ...[
            _depthRow(asks[i], red, maxVol, false),
            if (i > 0) const SizedBox(height: 2),
          ],
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22262E) : const Color(0xFFEEECE5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _spread,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2),
              ),
            ),
          ),
          for (int i = 0; i < bids.length; i++) ...[
            _depthRow(bids[i], green, maxVol, true),
            if (i < bids.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  String get _spread {
    if (asks.isEmpty || bids.isEmpty) return '—';
    final s = (asks.last[0] - bids.first[0]) / ((asks.last[0] + bids.first[0]) / 2) * 100;
    return 'Spread: ${s.toStringAsFixed(3)}%';
  }

  Widget _depthRow(List<double> level, Color color, double maxVol, bool isBid) {
    final price = level[0];
    final vol = level[1];
    final total = price * vol;
    final pct = maxVol > 0 ? vol / maxVol : 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: isBid ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(color: color.withValues(alpha: 0.12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(
                  price.toStringAsFixed(2),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, fontFamily: 'JetBrains Mono'),
                )),
                Expanded(flex: 2, child: Text(
                  vol.toStringAsFixed(4),
                  style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8), fontFamily: 'JetBrains Mono'),
                )),
                Expanded(flex: 2, child: Text(
                  total.toStringAsFixed(2),
                  style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.6), fontFamily: 'JetBrains Mono'),
                )),
              ],
            ),
          ),
        ],
      );
    });
  }
}
