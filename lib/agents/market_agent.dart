import 'dart:math';
import 'agent_base.dart';

class MarketAgent extends BaseAgent {
  @override
  String get name => 'Farida';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final price = ctx.prices[symbol] ?? 0;
    final klines = ctx.klines[symbol] ?? [];
    final closes = klines.map((k) => k.close).toList();
    final volumes = klines.map((k) => k.volume).toList();

    double score = 0.5;
    double? rsi;
    double? sma20;
    double? volRatio;
    double? volatility;
    double? support;
    double? resistance;

    if (closes.length >= 14) {
      rsi = BaseAgent.computeRSI(closes);
      sma20 = BaseAgent.ma(closes, 20);
      if (sma20 > 0) {
        score += (price - sma20) / sma20 * 0.3;
      }
    }

    if (volumes.length >= 5) {
      final recentVol = volumes.sublist(volumes.length - 3).fold(0.0, (a, b) => a + b) / 3;
      final avgVol = volumes.fold(0.0, (a, b) => a + b) / volumes.length;
      volRatio = avgVol > 0 ? recentVol / avgVol : 1.0;
      if (volRatio > 1.5) {
        score += 0.1;
      }
    }

    if (closes.length >= 5) {
      final returns = <double>[];
      for (int i = 1; i < closes.length; i++) {
        returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
      }
      if (returns.isNotEmpty) {
        final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
        final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
        volatility = sqrt(variance);
      }
    }

    if (closes.length >= 20) {
      final recent = closes.sublist(closes.length - 20);
      support = recent.reduce((a, b) => a < b ? a : b);
      resistance = recent.reduce((a, b) => a > b ? a : b);
    } else if (closes.isNotEmpty) {
      support = closes.reduce((a, b) => a < b ? a : b);
      resistance = closes.reduce((a, b) => a > b ? a : b);
    }

    score = score.clamp(0.0, 1.0);

    final summary = StringBuffer('Analyse marché $symbol\n');
    summary.writeln('Score: ${score.toStringAsFixed(2)}');
    if (rsi != null) summary.writeln('RSI: ${rsi.toStringAsFixed(1)}');
    if (sma20 != null) summary.writeln('SMA20: \$${sma20.toStringAsFixed(2)}');

    String? rec;
    if (score > 0.55) rec = 'BUY';
    else if (score < 0.45) rec = 'SELL';
    else rec = 'HOLD';

    return AgentReport(
      agentName: name,
      confidence: clampConfidence((score - 0.5).abs() * 2 + 0.3),
      summary: summary.toString(),
      recommendation: rec,
      details: {
        'score': score,
        'rsi': rsi,
        'sma20': sma20,
        'volRatio': volRatio,
        'volatility': volatility,
        'support': support,
        'resistance': resistance,
        'closes': closes,
      },
    );
  }
}
