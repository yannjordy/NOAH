import '../models/models.dart' show Kline;

class BacktestSignal {
  final int index;
  final String action;
  final double confidence;

  BacktestSignal({required this.index, required this.action, required this.confidence});
}

class BacktestResult {
  final double totalPnlPct;
  final double winRate;
  final double sharpeRatio;

  BacktestResult({required this.totalPnlPct, required this.winRate, required this.sharpeRatio});
}

class BacktestService {
  BacktestResult run(
    List<Kline> klines,
    List<BacktestSignal> signals, {
    double stopLossPct = 0.05,
    double takeProfitPct = 0.10,
    double positionSizePct = 0.10,
  }) {
    if (signals.isEmpty) {
      return BacktestResult(totalPnlPct: 0, winRate: 0, sharpeRatio: 0);
    }

    double totalPnl = 0;
    int wins = 0;
    final returns = <double>[];

    for (final sig in signals) {
      if (sig.index >= klines.length) continue;
      final entry = klines[sig.index].close;

      double exit;
      if (sig.action == 'BUY') {
        final slPrice = entry * (1 - stopLossPct);
        final tpPrice = entry * (1 + takeProfitPct);
        exit = tpPrice;
        for (int j = sig.index + 1; j < klines.length && j < sig.index + 20; j++) {
          if (klines[j].low <= slPrice) { exit = slPrice; break; }
          if (klines[j].high >= tpPrice) { exit = tpPrice; break; }
        }
      } else {
        final slPrice = entry * (1 + stopLossPct);
        final tpPrice = entry * (1 - takeProfitPct);
        exit = tpPrice;
        for (int j = sig.index + 1; j < klines.length && j < sig.index + 20; j++) {
          if (klines[j].high >= slPrice) { exit = slPrice; break; }
          if (klines[j].low <= tpPrice) { exit = tpPrice; break; }
        }
      }

      final pnl = sig.action == 'BUY'
          ? (exit - entry) / entry
          : (entry - exit) / entry;
      totalPnl += pnl;
      if (pnl > 0) wins++;
      returns.add(pnl);
    }

    final winRate = signals.isNotEmpty ? wins / signals.length : 0.0;
    double sharpe = 0;
    if (returns.length >= 2) {
      final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
      final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
      final std = _sqrt(variance);
      sharpe = std > 0 ? (mean / std) : 0;
    }

    return BacktestResult(
      totalPnlPct: totalPnl * 100,
      winRate: winRate,
      sharpeRatio: sharpe,
    );
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
