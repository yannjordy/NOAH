import 'dart:math';
import 'agent_base.dart';
import '../models/models.dart' show Kline;
import '../services/backtest_service.dart';

class OptimizerResult {
  final double bestSL;
  final double bestTP;
  final double bestPosSize;
  final double bestSharpe;
  final double bestWinRate;
  final double bestPnl;

  OptimizerResult({
    required this.bestSL, required this.bestTP,
    required this.bestPosSize, required this.bestSharpe,
    required this.bestWinRate, required this.bestPnl,
  });
}

class OptimizerAgent extends BaseAgent {
  static final Map<String, OptimizerResult> _cache = {};
  static final Set<String> _running = {};

  @override
  String get name => 'Optimiseur';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final cached = _cache[symbol];
    if (cached == null) {
      return AgentReport(
        agentName: name, confidence: 0,
        summary: '🔄 Optimisation en attente...',
        recommendation: 'HOLD',
        details: {'status': 'pending'},
      );
    }

    final buf = StringBuffer();
    buf.writeln('**🎯 Paramètres optimaux pour $symbol**\n');
    buf.writeln('- Stop Loss: ${(cached.bestSL * 100).toStringAsFixed(1)}%');
    buf.writeln('- Take Profit: ${(cached.bestTP * 100).toStringAsFixed(1)}%');
    buf.writeln('- Position: ${cached.bestPosSize.toStringAsFixed(0)}%');
    buf.writeln('- Sharpe: ${cached.bestSharpe.toStringAsFixed(2)}');
    buf.writeln('- Win Rate: ${(cached.bestWinRate * 100).toStringAsFixed(0)}%');
    buf.writeln('- PnL: ${cached.bestPnl >= 0 ? '+' : ''}${cached.bestPnl.toStringAsFixed(1)}%');

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(min(cached.bestSharpe / 2, 1.0)),
      summary: buf.toString(),
      recommendation: cached.bestSharpe > 1 ? 'BUY' : 'HOLD',
      details: {
        'sl': cached.bestSL, 'tp': cached.bestTP,
        'posSize': cached.bestPosSize,
        'sharpe': cached.bestSharpe,
        'winRate': cached.bestWinRate,
        'pnl': cached.bestPnl,
      },
    );
  }

  Future<void> optimize(String symbol, List<Kline> klines) async {
    if (_running.contains(symbol) || klines.length < 100) return;
    _running.add(symbol);
    try {
      final bt = BacktestService();
      final sls = [0.02, 0.03, 0.05, 0.07, 0.10];
      final tps = [0.05, 0.08, 0.10, 0.15, 0.20];
      final sizes = [0.05, 0.10, 0.15, 0.20];

      final closes = klines.map((k) => k.close).toList();
      final signals = <BacktestSignal>[];
      for (int i = 20; i < klines.length; i++) {
        final rsi = BaseAgent.computeRSI(closes.sublist(0, i + 1));
        final sma20 = BaseAgent.ma(closes.sublist(0, i + 1), 20);
        final sma50 = BaseAgent.ma(closes.sublist(0, i + 1), 50);
        final price = klines[i].open;
        String a = 'HOLD';
        if (sma20 > sma50 && price > sma20) a = 'BUY';
        else if (sma20 < sma50 && price < sma20) a = 'SELL';
        else if (rsi < 30) a = 'BUY';
        else if (rsi > 70) a = 'SELL';
        signals.add(BacktestSignal(index: i, action: a, confidence: 0.5));
      }
      final sigs = signals.where((s) => s.action != 'HOLD').toList();

      OptimizerResult? best;
      double bestScore = -999;

      for (final sl in sls) {
        for (final tp in tps) {
          for (final sz in sizes) {
            final r = bt.run(klines, sigs,
                stopLossPct: sl, takeProfitPct: tp, positionSizePct: sz);
            final score = r.sharpeRatio * 0.4 + (r.winRate) * 0.3 +
                min(r.totalPnlPct / 50, 1.0) * 0.3;
            if (score > bestScore) {
              bestScore = score;
              best = OptimizerResult(
                bestSL: sl, bestTP: tp, bestPosSize: sz * 100,
                bestSharpe: r.sharpeRatio, bestWinRate: r.winRate, bestPnl: r.totalPnlPct,
              );
            }
          }
        }
      }

      if (best != null) _cache[symbol] = best;
    } finally {
      _running.remove(symbol);
    }
  }
}
