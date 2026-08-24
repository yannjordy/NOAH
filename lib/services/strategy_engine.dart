import 'dart:math';
import '../models/models.dart';

class StrategySignal {
  final String symbol;
  final String action;
  final double confidence;
  final Map<String, dynamic> factors;

  StrategySignal({
    required this.symbol,
    required this.action,
    required this.confidence,
    required this.factors,
  });
}

class StrategyEngine {
  static StrategySignal analyze(String symbol, {List<Kline>? klines}) {
    final pct = pcts[symbol] ?? 0;
    final rsi = _computeRSI(symbol, klines: klines);
    final trendScore = _computeTrendScore(symbol, klines: klines);
    final volumeScore = _computeVolumeScore(symbol, klines: klines);
    final volatility = _computeVolatility(symbol, klines: klines);

    final trendFactor = (trendScore / 50).clamp(-1.0, 1.0);
    final rsiFactor = rsi != null ? _rsiToFactor(rsi) : 0.0;
    final volFactor = volumeScore.clamp(-1.0, 1.0);
    final pctFactor = (pct / 10).clamp(-1.0, 1.0);
    final volaFactor = volatility > 0.05 ? -0.3 : 0.1;

    final overall = trendFactor * 0.3 + rsiFactor * 0.25 + volFactor * 0.2 + pctFactor * 0.15 + volaFactor * 0.1;
    final confidence = (overall.abs() * 100).clamp(0.0, 100.0);
    final action = _determineAction(overall, confidence);

    return StrategySignal(
      symbol: symbol,
      action: action,
      confidence: confidence / 100,
      factors: {
        'trendScore': trendScore.toStringAsFixed(2),
        'rsi': rsi?.toStringAsFixed(1) ?? 'N/A',
        'volumeScore': volumeScore.toStringAsFixed(2),
        'pctChange': pct,
        'volatility': volatility.toStringAsFixed(4),
        'overall': overall.toStringAsFixed(3),
      },
    );
  }

  static String _determineAction(double overall, double conf) {
    if (conf < 20) return 'HOLD';
    if (overall > 0.5) return 'STRONG_BUY';
    if (overall > 0.2) return 'BUY';
    if (overall < -0.5) return 'STRONG_SELL';
    if (overall < -0.2) return 'SELL';
    return 'HOLD';
  }

  static double? _computeRSI(String symbol, {List<Kline>? klines, int period = 14}) {
    if (klines == null || klines.length < period + 1) return null;
    final closes = klines.sublist(0, period + 1).map((k) => k.close).toList();
    double gains = 0, losses = 0;
    for (int i = 1; i < closes.length; i++) {
      final d = closes[i] - closes[i - 1];
      if (d > 0) gains += d; else losses -= d;
    }
    if (losses == 0) return 100;
    final rs = gains / losses;
    return 100 - (100 / (1 + rs));
  }

  static double _computeTrendScore(String symbol, {List<Kline>? klines}) {
    if (klines == null || klines.length < 10) return 0;
    final closes = klines.map((k) => k.close).toList();
    final short = closes.sublist(closes.length - 5).reduce((a, b) => a + b) / 5;
    final long = closes.reduce((a, b) => a + b) / closes.length;
    return ((short - long) / long) * 100;
  }

  static double _computeVolumeScore(String symbol, {List<Kline>? klines}) {
    if (klines == null || klines.length < 5) return 0;
    final vols = klines.map((k) => k.volume).toList();
    final recent = vols.sublist(vols.length - 3).reduce((a, b) => a + b) / 3;
    final avg = vols.reduce((a, b) => a + b) / vols.length;
    if (avg == 0) return 0;
    return ((recent - avg) / avg).clamp(-1.0, 1.0);
  }

  static double _computeVolatility(String symbol, {List<Kline>? klines}) {
    if (klines == null || klines.length < 5) return 0;
    final closes = klines.map((k) => k.close).toList();
    final returns = <double>[];
    for (int i = 1; i < closes.length; i++) {
      returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
    }
    if (returns.isEmpty) return 0;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    return sqrt(variance);
  }

  static double _rsiToFactor(double rsi) {
    if (rsi > 70) return -0.8;
    if (rsi < 30) return 0.8;
    return (rsi - 50) / 25 * -1;
  }
}
