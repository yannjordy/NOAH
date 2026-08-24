import 'dart:math';
import '../models/models.dart';

class RiskManager {
  PortfolioData data;
  final Map<String, double> prices;

  RiskManager({required this.data, required this.prices});

  void updateData(PortfolioData d) { data = d; }

  double get totalValue => data.totalValue;
  double get positionsValue => data.positionsValue;
  double get usdt => data.usdt;
  double get deposits => data.totalDeposits;

  double get unrealizedPnl => totalValue - deposits;
  double get unrealizedPnlPct => deposits > 0 ? (unrealizedPnl / deposits * 100) : 0;

  double get exposurePct => totalValue > 0 ? (positionsValue / totalValue * 100).clamp(0, 100) : 0;

  double get maxDrawdown {
    double peak = data.initialUsdt;
    double mdd = 0;
    for (final t in data.history.reversed) {
      final curValue = data.usdt + data.positionsValue;
      if (curValue > peak) peak = curValue;
      final dd = (peak - curValue) / peak * 100;
      if (dd > mdd) mdd = dd;
    }
    return mdd;
  }

  double get currentDrawdown {
    double peak = data.initialUsdt;
    for (final t in data.history.reversed) {
      final cur = (t.pnl ?? 0) > 0 ? peak : peak;
    }
    final total = totalValue;
    if (total <= data.initialUsdt) return 0;
    return ((total - data.initialUsdt) / data.initialUsdt * 100).abs();
  }

  double kellyPositionSize({required double winRate, required double avgWin, required double avgLoss}) {
    if (avgLoss <= 0 || winRate <= 0 || winRate >= 1) return 0.01;
    final b = avgWin / avgLoss;
    final q = 1 - winRate;
    final kelly = (b * winRate - q) / b;
    return kelly.clamp(0.01, 0.25);
  }

  double atrBasedStopLoss({required double atr, double multiplier = 2}) {
    return atr * multiplier;
  }

  double atrBasedPositionSize({required double atr, required double accountBalance, double riskPct = 0.01, double entryPrice = 1}) {
    if (atr <= 0 || entryPrice <= 0) return 0;
    final stopDist = atr * 2;
    final dollarRisk = accountBalance * riskPct;
    return dollarRisk / stopDist;
  }

  double correlationScore(List<double> a, List<double> b) {
    if (a.length != b.length || a.length < 2) return 0;
    final n = a.length;
    final meanA = a.reduce((s, v) => s + v) / n;
    final meanB = b.reduce((s, v) => s + v) / n;
    double cov = 0, varA = 0, varB = 0;
    for (int i = 0; i < n; i++) {
      final da = a[i] - meanA;
      final db = b[i] - meanB;
      cov += da * db;
      varA += da * da;
      varB += db * db;
    }
    final denom = sqrt(varA * varB);
    return denom == 0 ? 0 : (cov / denom).clamp(-1, 1);
  }

  bool isCorrelated(Position a, Position b) {
    final priceA = prices[a.sym] ?? 0;
    final priceB = prices[b.sym] ?? 0;
    if (priceA <= 0 || priceB <= 0) return false;
    final sim = [a.entry / priceA, b.entry / priceB];
    return sim[0] > 0.8 && sim[1] > 0.8;
  }

  double get correlationRisk {
    int correlated = 0;
    for (int i = 0; i < data.positions.length; i++) {
      for (int j = i + 1; j < data.positions.length; j++) {
        if (isCorrelated(data.positions[i], data.positions[j])) correlated++;
      }
    }
    if (data.positions.length < 2) return 0;
    return correlated / (data.positions.length * (data.positions.length - 1) / 2);
  }

  String get riskLabel {
    final e = exposurePct;
    final mdd = maxDrawdown;
    final corr = correlationRisk;
    if (e > 80 || mdd > 30 || corr > 0.6) return 'CRITIQUE';
    if (e > 60 || mdd > 15 || corr > 0.4) return 'ÉLEVÉ';
    if (e > 40 || mdd > 8 || corr > 0.2) return 'MOYEN';
    return 'FAIBLE';
  }

  Map<String, dynamic> toJson() => {
    'exposurePct': exposurePct,
    'maxDrawdown': maxDrawdown,
    'correlationRisk': correlationRisk,
    'unrealizedPnl': unrealizedPnl,
    'unrealizedPnlPct': unrealizedPnlPct,
    'riskLabel': riskLabel,
    'kellySuggested': kellyPositionSize(winRate: 0.55, avgWin: 1.5, avgLoss: 1.0),
  };
}

class PerformanceAnalyzer {
  final List<TradeOrder> history;
  final double initialCapital;

  PerformanceAnalyzer(this.history, this.initialCapital);

  int get totalTrades => history.length;
  int get wins => history.where((t) => (t.pnl ?? 0) > 0).length;
  int get losses => history.where((t) => (t.pnl ?? 0) < 0).length;
  double get winRate => totalTrades > 0 ? wins / totalTrades : 0;

  double get avgWin {
    final w = history.where((t) => (t.pnl ?? 0) > 0).map((t) => t.pnl!).toList();
    return w.isEmpty ? 0 : w.reduce((a, b) => a + b) / w.length;
  }

  double get avgLoss {
    final l = history.where((t) => (t.pnl ?? 0) < 0).map((t) => t.pnl!.abs()).toList();
    return l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
  }

  double get profitFactor {
    final grossProfit = history.where((t) => (t.pnl ?? 0) > 0).fold(0.0, (s, t) => s + t.pnl!);
    final grossLoss = history.where((t) => (t.pnl ?? 0) < 0).fold(0.0, (s, t) => s + t.pnl!.abs());
    return grossLoss > 0 ? grossProfit / grossLoss : 0;
  }

  double get sharpeRatio {
    if (history.length < 2) return 0;
    final returns = <double>[];
    double capital = initialCapital;
    for (final t in history) {
      final r = (t.pnl ?? 0) / capital;
      returns.add(r);
      capital += t.pnl ?? 0;
    }
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / (returns.length - 1);
    final stdDev = sqrt(variance);
    return stdDev > 0 ? mean / stdDev * sqrt(365) : 0;
  }

  double get sortinoRatio {
    if (history.length < 2) return 0;
    final returns = <double>[];
    double capital = initialCapital;
    for (final t in history) {
      final r = (t.pnl ?? 0) / capital;
      returns.add(r);
      capital += t.pnl ?? 0;
    }
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final downside = returns.where((r) => r < 0).map((r) => pow(r - mean, 2)).fold(0.0, (a, b) => a + b);
    final downDev = sqrt(downside / (returns.length - 1));
    return downDev > 0 ? mean / downDev * sqrt(365) : 0;
  }

  double get expectancy {
    if (winRate <= 0 || totalTrades <= 0) return 0;
    return winRate * avgWin - (1 - winRate) * avgLoss;
  }

  Map<String, dynamic> toJson() => {
    'totalTrades': totalTrades,
    'wins': wins,
    'losses': losses,
    'winRate': winRate,
    'avgWin': avgWin,
    'avgLoss': avgLoss,
    'profitFactor': profitFactor,
    'sharpeRatio': sharpeRatio,
    'sortinoRatio': sortinoRatio,
    'expectancy': expectancy,
  };
}
