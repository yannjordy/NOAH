import 'dart:math';
import '../models/models.dart';

class TimeframeData {
  final String label;
  final int periodMinutes;
  final double rsi;
  final double ema9;
  final double ema21;
  final double ema50;
  final bool isBullish;
  final double volatility;
  final String trend;

  TimeframeData({
    required this.label,
    required this.periodMinutes,
    required this.rsi,
    required this.ema9,
    required this.ema21,
    required this.ema50,
    required this.isBullish,
    required this.volatility,
    required this.trend,
  });
}

class MultiTimeframeAnalyzer {
  static const timeframes = [
    ('1m', 1),
    ('5m', 5),
    ('15m', 15),
    ('1h', 60),
    ('4h', 240),
    ('1d', 1440),
  ];

  static List<TimeframeData> analyze(String symbol, Map<String, List<Kline>> klinesMap) {
    final results = <TimeframeData>[];
    for (final (label, period) in timeframes) {
      final klines = _getKlinesForPeriod(symbol, period, klinesMap);
      if (klines.length < 50) continue;

      final closes = klines.map((k) => k.close).toList();
      final rsi = _rsi(closes, 14);
      final ema9 = _ema(closes, 9);
      final ema21 = _ema(closes, 21);
      final ema50 = _ema(closes, 50);
      final lastPrice = closes.last;
      final vol = _volatility(closes, 14);

      final isBullish = ema9 > ema21 && ema21 > ema50 && lastPrice > ema9;
      String trend;
      if (ema9 > ema21 && ema21 > ema50) trend = 'HAUSSIER';
      else if (ema9 < ema21 && ema21 < ema50) trend = 'BAISSIER';
      else trend = 'NEUTRE';

      results.add(TimeframeData(
        label: label,
        periodMinutes: period,
        rsi: rsi,
        ema9: ema9,
        ema21: ema21,
        ema50: ema50,
        isBullish: isBullish,
        volatility: vol,
        trend: trend,
      ));
    }
    return results;
  }

  static String consensus(List<TimeframeData> tfs) {
    if (tfs.isEmpty) return 'NEUTRE';
    final bullish = tfs.where((t) => t.isBullish).length;
    final total = tfs.length;
    if (bullish >= total * 0.66) return 'HAUSSIER FORT';
    if (bullish >= total * 0.5) return 'HAUSSIER';
    if (bullish <= total * 0.33) return 'BAISSIER FORT';
    if (bullish <= total * 0.5) return 'BAISSIER';
    return 'NEUTRE';
  }

  static List<Kline> _getKlinesForPeriod(String symbol, int periodMinutes, Map<String, List<Kline>> klinesMap) {
    final key = '$symbol:$periodMinutes';
    if (klinesMap.containsKey(key)) return klinesMap[key]!;
    final baseKey = '$symbol:60';
    final base = klinesMap[baseKey] ?? klinesMap.values.firstOrNull ?? [];
    if (base.isEmpty) return [];
    final interval = (periodMinutes / 60).round().clamp(1, 24);
    final resampled = <Kline>[];
    for (int i = 0; i < base.length; i += interval) {
      final chunk = base.sublist(i, min(i + interval, base.length));
      if (chunk.isEmpty) continue;
      resampled.add(Kline(
        openTime: chunk.first.openTime,
        open: chunk.first.open,
        high: chunk.map((k) => k.high).reduce(max),
        low: chunk.map((k) => k.low).reduce(min),
        close: chunk.last.close,
        volume: chunk.fold(0.0, (s, k) => s + k.volume),
        closeTime: chunk.last.closeTime,
      ));
    }
    return resampled;
  }

  static double _rsi(List<double> closes, int period) {
    if (closes.length < period + 1) return 50;
    double gain = 0, loss = 0;
    for (int i = closes.length - period; i < closes.length - 1; i++) {
      final diff = closes[i + 1] - closes[i];
      if (diff > 0) gain += diff;
      else loss += diff.abs();
    }
    if (loss == 0) return 100;
    final rs = gain / loss;
    return 100 - (100 / (1 + rs));
  }

  static double _ema(List<double> closes, int period) {
    if (closes.length < period) return closes.last;
    final k = 2 / (period + 1);
    double ema = closes.sublist(0, period).reduce((a, b) => a + b) / period;
    for (int i = period; i < closes.length; i++) {
      ema = closes[i] * k + ema * (1 - k);
    }
    return ema;
  }

  static double _volatility(List<double> closes, int period) {
    if (closes.length < period + 1) return 0;
    final returns = <double>[];
    for (int i = closes.length - period; i < closes.length; i++) {
      returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
    }
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    return sqrt(variance);
  }
}
