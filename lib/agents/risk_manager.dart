import '../models/models.dart';

class RiskReport {
  final String riskLabel;
  final double exposurePct;
  final double maxDrawdown;
  final double correlationRisk;
  final double kellySuggested;
  final double unrealizedPnl;
  final double unrealizedPnlPct;

  RiskReport({
    this.riskLabel = 'LOW',
    this.exposurePct = 0,
    this.maxDrawdown = 0,
    this.correlationRisk = 0,
    this.kellySuggested = 0.1,
    this.unrealizedPnl = 0,
    this.unrealizedPnlPct = 0,
  });

  Map<String, dynamic> toJson() => {
    'riskLabel': riskLabel,
    'exposurePct': exposurePct,
    'maxDrawdown': maxDrawdown,
    'correlationRisk': correlationRisk,
    'kellySuggested': kellySuggested,
    'unrealizedPnl': unrealizedPnl,
    'unrealizedPnlPct': unrealizedPnlPct,
  };
}

class RiskManager {
  PortfolioData data;
  final Map<String, double> prices;

  RiskManager({required this.data, required this.prices});

  void updateData(PortfolioData newData) => data = newData;

  double kellyPositionSize({
    required double winRate,
    required double avgWin,
    required double avgLoss,
  }) {
    if (avgLoss <= 0 || avgWin <= 0) return 0.1;
    final b = avgWin / avgLoss;
    final kelly = (winRate * b - (1 - winRate)) / b;
    return kelly.clamp(0.05, 0.5);
  }

  Map<String, dynamic> toJson() => assessRisk().toJson();

  RiskReport assessRisk() {
    final totalValue = data.usdt + data.positionsValue;
    final posValue = data.positionsValue;
    final exposurePct = totalValue > 0 ? posValue / totalValue : 0.0;

    double maxDrawdown = 0;
    if (data.peakCapital > 0) {
      maxDrawdown = (data.peakCapital - totalValue) / data.peakCapital;
    }

    double unrealizedPnl = 0;
    for (final pos in data.positions) {
      final cur = prices[pos.sym] ?? pos.entry;
      unrealizedPnl += (cur - pos.entry) * pos.qty;
    }

    final kelly = kellyPositionSize(
      winRate: data.winRate.clamp(0.01, 0.99),
      avgWin: data.bestTrade.clamp(0.01, double.infinity),
      avgLoss: data.worstTrade.abs().clamp(0.01, double.infinity),
    );

    String riskLabel;
    if (maxDrawdown > 0.15 || exposurePct > 0.8) {
      riskLabel = 'CRITICAL';
    } else if (maxDrawdown > 0.10 || exposurePct > 0.6) {
      riskLabel = 'HIGH';
    } else if (maxDrawdown > 0.05 || exposurePct > 0.4) {
      riskLabel = 'MODERATE';
    } else {
      riskLabel = 'LOW';
    }

    return RiskReport(
      riskLabel: riskLabel,
      exposurePct: exposurePct,
      maxDrawdown: maxDrawdown,
      kellySuggested: kelly,
      unrealizedPnl: unrealizedPnl,
      unrealizedPnlPct: data.totalDeposits > 0 ? (unrealizedPnl / data.totalDeposits * 100) : 0,
    );
  }
}
