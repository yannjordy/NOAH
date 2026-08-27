import '../models/models.dart' show Kline;

class AgentContext {
  final Map<String, double> prices;
  final Map<String, double> pcts;
  final Map<String, List<Kline>> klines;
  final Map<String, List<List<double>>> bids;
  final Map<String, List<List<double>>> asks;
  final double usdtBalance;
  final List<PositionSnapshot> positions;
  final List<TradeSnapshot> history;
  final Map<String, dynamic> sentiment;
  final Map<String, Map<String, dynamic>> technicals;

  AgentContext({
    required this.prices,
    required this.pcts,
    required this.klines,
    required this.bids,
    required this.asks,
    required this.usdtBalance,
    required this.positions,
    required this.history,
    this.sentiment = const {},
    this.technicals = const {},
  });
}

class PositionSnapshot {
  final String symbol;
  final double qty;
  final double entryPrice;
  final double? stopLoss;
  final double? takeProfit;

  PositionSnapshot({
    required this.symbol,
    required this.qty,
    required this.entryPrice,
    this.stopLoss,
    this.takeProfit,
  });

  double currentValue(double price) => qty * price;
  double pnl(double price) => qty * (price - entryPrice);
  double pnlPct(double price) => entryPrice > 0 ? ((price - entryPrice) / entryPrice) * 100 : 0;
}

class TradeSnapshot {
  final String side;
  final String symbol;
  final double qty;
  final double price;
  final String time;

  TradeSnapshot({
    required this.side,
    required this.symbol,
    required this.qty,
    required this.price,
    required this.time,
  });
}

class AgentReport {
  final String agentName;
  final double confidence;
  final String summary;
  final String? recommendation;
  final Map<String, dynamic> details;

  AgentReport({
    required this.agentName,
    required this.confidence,
    required this.summary,
    this.recommendation,
    required this.details,
  });
}

abstract class BaseAgent {
  String get name;

  AgentReport analyze(String symbol, AgentContext ctx);
  double clampConfidence(double raw) => raw.clamp(0.0, 1.0);

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

  static double ma(List<double> data, int period) {
    if (data.length < period) return data.fold(0.0, (a, b) => a + b) / data.length;
    return data.sublist(data.length - period).fold(0.0, (a, b) => a + b) / period;
  }
}

typedef AiThinker = Future<String> Function(String prompt, {String? systemContext});

String fmt(double p) {
  if (p >= 1000) {
    final parts = p.toStringAsFixed(0);
    final buffer = StringBuffer('\$');
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
  if (p >= 1) return '\$${p.toStringAsFixed(2)}';
  return '\$${p.toStringAsFixed(4)}';
}
