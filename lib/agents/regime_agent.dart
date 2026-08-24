import 'dart:math';
import 'agent_base.dart';
import '../models/models.dart' show Kline;

class RegimeAgent extends BaseAgent {
  @override
  String get name => 'Régime';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final klines = ctx.klines[symbol] ?? [];
    if (klines.length < 30) {
      return AgentReport(
        agentName: name, confidence: 0,
        summary: 'Pas assez de données pour détecter le régime.',
        recommendation: 'HOLD',
        details: {'regime': 'unknown', 'candles': klines.length},
      );
    }

    final closes = klines.map((k) => k.close).toList();
    final highs = klines.map((k) => k.high).toList();
    final lows = klines.map((k) => k.low).toList();

    // ADX — trend strength
    final adx = _calcADX(highs, lows, closes);
    // ATR ratio — volatility regime
    final atr = _calcATR(highs, lows, closes);
    final avgPrice = closes.fold(0.0, (a, b) => a + b) / closes.length;
    final atrRatio = avgPrice > 0 ? atr / avgPrice * 100 : 0;
    // RSI slope — direction
    final rsi = BaseAgent.computeRSI(closes);
    final rsiSlope = closes.length >= 10
        ? BaseAgent.computeRSI(closes.sublist(closes.length - 10)) - BaseAgent.computeRSI(closes.sublist(closes.length - 20, closes.length - 10))
        : 0;

    String regime;
    double confidence;

    if (adx > 25) {
      // Strong trend
      if (rsi > 55 && rsiSlope > 0) {
        regime = 'UPTREND';
        confidence = min(0.5 + (adx - 25) / 50 + (rsiSlope / 20).abs(), 0.95);
      } else if (rsi < 45 && rsiSlope < 0) {
        regime = 'DOWNTREND';
        confidence = min(0.5 + (adx - 25) / 50 + (rsiSlope / 20).abs(), 0.95);
      } else {
        regime = 'TRENDING';
        confidence = 0.5 + (adx - 25) / 50;
      }
    } else if (atrRatio > 3.0) {
      regime = 'VOLATILE';
      confidence = min(atrRatio / 10, 0.9);
    } else {
      regime = 'RANGING';
      confidence = 0.5;
    }

    final buf = StringBuffer();
    buf.writeln('**📊 Régime de marché pour $symbol**\n');
    buf.writeln('Régime: **$regime** (confiance: ${(confidence * 100).toStringAsFixed(0)}%)');
    buf.writeln('ADX: ${adx.toStringAsFixed(1)} (${adx > 25 ? "tendance" : "faible"})');
    buf.writeln('ATR: ${atrRatio.toStringAsFixed(2)}% (${atrRatio > 3 ? "volatile" : "calme"})');
    buf.writeln('RSI: ${rsi.toStringAsFixed(0)} | Pente: ${rsiSlope >= 0 ? "+" : ""}${rsiSlope.toStringAsFixed(1)}');

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(confidence),
      summary: buf.toString(),
      recommendation: regime == 'UPTREND' ? 'BUY' : (regime == 'DOWNTREND' ? 'SELL' : 'HOLD'),
      details: {'regime': regime, 'adx': adx, 'atrRatio': atrRatio, 'rsi': rsi, 'rsiSlope': rsiSlope},
    );
  }

  double _calcADX(List<double> high, List<double> low, List<double> close) {
    if (close.length < 30) return 0;
    final tr = <double>[];
    final plusDM = <double>[];
    final minusDM = <double>[];
    for (int i = 1; i < close.length; i++) {
      tr.add([high[i] - low[i], (high[i] - close[i - 1]).abs(), (low[i] - close[i - 1]).abs()].reduce(max));
      plusDM.add(high[i] - high[i - 1] > low[i - 1] - low[i] ? max(high[i] - high[i - 1], 0.0) : 0);
      minusDM.add(low[i - 1] - low[i] > high[i] - high[i - 1] ? max(low[i - 1] - low[i], 0.0) : 0);
    }
    final period = 14;
    if (tr.length < period) return 0;
    double atr = tr.sublist(0, period).fold(0.0, (a, b) => a + b) / period;
    double plusDI = plusDM.sublist(0, period).fold(0.0, (a, b) => a + b) / atr * 100;
    double minusDI = minusDM.sublist(0, period).fold(0.0, (a, b) => a + b) / atr * 100;
    for (int i = period; i < tr.length; i++) {
      atr = (atr * (period - 1) + tr[i]) / period;
      final pdi = plusDM.sublist(i - period + 1, i + 1).fold(0.0, (a, b) => a + b) / atr * 100;
      final mdi = minusDM.sublist(i - period + 1, i + 1).fold(0.0, (a, b) => a + b) / atr * 100;
      plusDI = pdi; minusDI = mdi;
    }
    final dx = (plusDI + minusDI) > 0 ? (((plusDI - minusDI).abs() / (plusDI + minusDI)) * 100).toDouble() : 0.0;
    return dx;
  }

  double _calcATR(List<double> high, List<double> low, List<double> close) {
    if (close.length < 15) return 0;
    final tr = <double>[];
    for (int i = 1; i < close.length; i++) {
      tr.add([high[i] - low[i], (high[i] - close[i - 1]).abs(), (low[i] - close[i - 1]).abs()].reduce(max));
    }
    final period = 14;
    if (tr.length < period) return 0;
    double atr = tr.sublist(0, period).fold(0.0, (a, b) => a + b) / period;
    for (int i = period; i < tr.length; i++) {
      atr = (atr * (period - 1) + tr[i]) / period;
    }
    return atr;
  }
}
