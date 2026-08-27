import '../models/models.dart' show Kline;

class TechnicalAnalysis {
  static double computeRSI(List<double> closes, {int period = 14}) {
    if (closes.length < period + 1) return 50;
    double gains = 0, losses = 0;
    for (int i = closes.length - period; i < closes.length; i++) {
      final d = closes[i] - closes[i - 1];
      if (d > 0) gains += d;
      else losses -= d;
    }
    if (losses == 0) return 100;
    return 100 - (100 / (1 + gains / losses));
  }

  static List<double> computeMACD(List<double> closes, {int fast = 12, int slow = 26, int signal = 9}) {
    if (closes.length < slow + signal) return [0, 0, 0];
    final emaFast = _ema(closes, fast);
    final emaSlow = _ema(closes, slow);
    final macdLine = emaFast - emaSlow;
    final signalLine = _ema([macdLine], signal);
    final histogram = macdLine - signalLine;
    return [macdLine, signalLine, histogram];
  }

  static List<double> computeBollinger(List<double> closes, {int period = 20, double stdDev = 2.0}) {
    if (closes.length < period) return [0, 0, 0];
    final ma = closes.sublist(closes.length - period).fold(0.0, (a, b) => a + b) / period;
    final variance = closes.sublist(closes.length - period).fold(0.0, (a, b) => a + (b - ma) * (b - ma)) / period;
    final std = variance > 0 ? _sqrt(variance) : 0.0;
    return [ma - stdDev * std, ma, ma + stdDev * std];
  }

  static double computeATR(List<Kline> klines, {int period = 14}) {
    if (klines.length < period + 1) return 0;
    double atr = 0;
    for (int i = klines.length - period; i < klines.length; i++) {
      final high = klines[i].high;
      final low = klines[i].low;
      final prevClose = klines[i - 1].close;
      final tr = [high - low, (high - prevClose).abs(), (low - prevClose).abs()].reduce((a, b) => a > b ? a : b);
      atr += tr;
    }
    return atr / period;
  }

  static double computeVolumeProfile(List<Kline> klines) {
    if (klines.isEmpty) return 0;
    final recentVol = klines.last.volume;
    final avgVol = klines.fold(0.0, (a, k) => a + k.volume) / klines.length;
    return avgVol > 0 ? recentVol / avgVol : 1.0;
  }

  static double _ema(List<double> data, int period) {
    if (data.isEmpty) return 0;
    final k = 2.0 / (period + 1);
    double ema = data.first;
    for (int i = 1; i < data.length; i++) {
      ema = data[i] * k + ema * (1 - k);
    }
    return ema;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static Map<String, dynamic> analyze(String symbol, List<Kline> klines) {
    final closes = klines.map((k) => k.close).toList();
    final rsi = computeRSI(closes);
    final macd = computeMACD(closes);
    final bollinger = computeBollinger(closes);
    final atr = computeATR(klines);
    final volumeRatio = computeVolumeProfile(klines);

    String rsiSignal = 'NEUTRAL';
    if (rsi < 30) rsiSignal = 'OVERSOLD';
    else if (rsi > 70) rsiSignal = 'OVERBOUGHT';

    String macdSignal = 'NEUTRAL';
    if (macd[2] > 0 && macd[0] > macd[1]) macdSignal = 'BULLISH';
    else if (macd[2] < 0 && macd[0] < macd[1]) macdSignal = 'BEARISH';

    String bollingerSignal = 'NEUTRAL';
    if (closes.isNotEmpty && closes.last < bollinger[0]) bollingerSignal = 'OVERSOLD';
    else if (closes.isNotEmpty && closes.last > bollinger[2]) bollingerSignal = 'OVERBOUGHT';

    return {
      'rsi': rsi,
      'rsiSignal': rsiSignal,
      'macd': macd,
      'macdSignal': macdSignal,
      'bollinger': bollinger,
      'bollingerSignal': bollingerSignal,
      'atr': atr,
      'volumeRatio': volumeRatio,
    };
  }
}
