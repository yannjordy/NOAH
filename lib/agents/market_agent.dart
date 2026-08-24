import 'dart:math';
import 'agent_base.dart';

class MarketAgent extends BaseAgent {
  @override
  String get name => 'Farida';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final price = ctx.prices[symbol] ?? 0;
    final pct = ctx.pcts[symbol] ?? 0;
    final klines = ctx.klines[symbol] ?? [];

    if (klines.length < 20) {
      return AgentReport(
        agentName: name,
        confidence: 0.3,
        summary: 'Données insuffisantes pour analyser $symbol.',
        recommendation: 'HOLD',
        details: {'price': price, 'change24h': pct, 'note': 'Données insuffisantes'},
      );
    }

    final closes = klines.map((k) => k.close).toList();
    final highs = klines.map((k) => k.high).toList();
    final lows = klines.map((k) => k.low).toList();
    final vols = klines.map((k) => k.volume).toList();

    // Indicateurs techniques
    final rsi = BaseAgent.computeRSI(closes);
    final sma20 = BaseAgent.ma(closes, 20);
    final sma50 = BaseAgent.ma(closes, min(50, closes.length));
    final sma5 = BaseAgent.ma(closes, 5);

    // Tendance
    final trendScore = sma5 > sma20
        ? (sma5 - sma20) / sma20 * 100
        : (sma5 - sma20) / sma20 * 100;

    // Volume
    final avgVol = BaseAgent.ma(vols, min(20, vols.length));
    final recentVol = BaseAgent.ma(vols, min(5, vols.length));
    final volRatio = avgVol > 0 ? recentVol / avgVol : 1.0;

    // Support/Résistance
    final recentHigh = highs.sublist(max(0, highs.length - 20)).reduce(max);
    final recentLow = lows.sublist(max(0, lows.length - 20)).reduce(min);

    // Volatilité
    final returns = <double>[];
    for (int i = 1; i < closes.length; i++) {
      returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
    }
    final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    final volatility = sqrt(variance);

    // Score technique composite
    double score = 0.5;

    // RSI
    if (rsi < 30) score += 0.2;
    else if (rsi > 70) score -= 0.2;
    else score += (50 - rsi) / 50 * 0.1;

    // Tendance
    if (sma5 > sma20 && sma20 > sma50) score += 0.15;
    else if (sma5 < sma20 && sma20 < sma50) score -= 0.15;

    // Prix vs SMA
    if (price > sma20) score += 0.1;
    else score -= 0.1;

    // Volume
    if (volRatio > 1.5 && price > sma5) score += 0.1;
    else if (volRatio > 1.5 && price < sma5) score -= 0.1;

    // Proximité support/résistance
    if (price <= recentLow * 1.02) score += 0.1;
    else if (price >= recentHigh * 0.98) score -= 0.1;

    // Volatilité excessive
    if (volatility > 0.03) score -= 0.1;

    final confidence = clampConfidence((score - 0.5).abs() * 2);
    final bullish = score > 0.55;
    final bearish = score < 0.45;

    String action;
    if (bullish && confidence > 0.4) action = 'BUY';
    else if (bearish && confidence > 0.4) action = 'SELL';
    else action = 'HOLD';

    final buffer = StringBuffer();
    buffer.writeln('**Analyse Technique $symbol**\n');
    buffer.writeln('Prix: \$${price.toStringAsFixed(2)} | Variation 24h: ${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%');
    buffer.writeln('RSI(14): ${rsi.toStringAsFixed(1)} | SMA20: \$${sma20.toStringAsFixed(2)}');
    buffer.writeln('Support: \$${recentLow.toStringAsFixed(2)} | Résistance: \$${recentHigh.toStringAsFixed(2)}');
    buffer.writeln('Volume relatif: ${volRatio.toStringAsFixed(2)}x | Volatilité: ${(volatility * 100).toStringAsFixed(2)}%');

    if (rsi < 35) buffer.writeln('\n⚠ RSI en zone survendue — possible rebond.');
    else if (rsi > 65) buffer.writeln('\n⚠ RSI en zone surachat — attention au retournement.');

    if (price <= recentLow * 1.03) buffer.writeln('📊 Prix proche du support — zone d\'achat potentielle.');
    else if (price >= recentHigh * 0.97) buffer.writeln('📊 Prix proche de la résistance — zone de vente potentielle.');

    return AgentReport(
      agentName: name,
      confidence: confidence,
      summary: buffer.toString(),
      recommendation: action,
      details: {
        'price': price,
        'rsi': rsi,
        'sma20': sma20,
        'sma50': sma50,
        'volRatio': volRatio,
        'volatility': volatility,
        'support': recentLow,
        'resistance': recentHigh,
        'trendScore': trendScore,
        'score': score,
      },
    );
  }
}
