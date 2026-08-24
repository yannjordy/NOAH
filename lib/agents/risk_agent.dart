import 'dart:math';
import 'agent_base.dart';

class RiskAgent extends BaseAgent {
  @override
  String get name => 'Henri';

  double _maxRiskPerTrade = 0.01;    // 1% max risk per trade
  double _maxDailyLoss = 0.05;        // 5% max daily drawdown
  double _maxExposure = 0.40;         // 40% max total exposure

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final price = ctx.prices[symbol] ?? 0;
    final pct = ctx.pcts[symbol] ?? 0;
    final klines = ctx.klines[symbol] ?? [];

    final totalValue = ctx.usdtBalance + _positionsValue(ctx);
    final posValue = _symbolExposure(symbol, ctx);
    final totalExposure = _positionsValue(ctx);
    final exposurePct = totalValue > 0 ? totalExposure / totalValue : 0;

    // Calcul drawdown based on daily PnL
    final dailyLoss = _dailyLoss(ctx);
    final ddPct = totalValue > 0 ? (dailyLoss.abs() / totalValue) : 0;

    // Max position size based on risk rules
    final maxTradeValue = totalValue * _maxRiskPerTrade;
    final maxQty = price > 0 ? maxTradeValue / price : 0;

    // Évaluation du risque global
    final report = StringBuffer();
    final List<String> warnings = [];
    double riskScore = 0.0;
    bool circuitBreaker = false;

    report.writeln('**Évaluation des risques $symbol**\n');

    // Règle: Drawdown journalier
    if (ddPct.abs() >= _maxDailyLoss) {
      circuitBreaker = true;
      warnings.add('🔴 DRAWDOWN MAX ATTEINT: ${(ddPct * 100).toStringAsFixed(1)}% — Trading suspendu');
      riskScore += 0.3;
    } else if (ddPct.abs() >= _maxDailyLoss * 0.7) {
      warnings.add('🟠 Drawdown élevé: ${(ddPct * 100).toStringAsFixed(1)}% — Mode défensif activé');
      riskScore += 0.15;
    }

    // Règle: Exposition maximale
    if (exposurePct >= _maxExposure) {
      warnings.add('🔴 Exposition maximale atteinte: ${(exposurePct * 100).toStringAsFixed(0)}%');
      riskScore += 0.2;
    } else if (exposurePct >= _maxExposure * 0.7) {
      warnings.add('🟠 Exposition élevée: ${(exposurePct * 100).toStringAsFixed(0)}%');
      riskScore += 0.1;
    }

    // Règle: Taille de position
    if (posValue > 0 && posValue > maxTradeValue * 2) {
      warnings.add('🔴 Position $symbol trop grande: ${fmt(posValue)} vs max ${fmt(maxTradeValue * 2)}');
      riskScore += 0.2;
    }

    // Règle: Volatilité
    if (klines.length >= 5) {
      final closes = klines.map((k) => k.close).toList();
      final returns = <double>[];
      for (int i = 1; i < closes.length; i++) {
        returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
      }
      final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
      final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
      final vol = sqrt(variance);
      if (vol > 0.04) {
        warnings.add('🟠 Volatilité excessive sur $symbol: ${(vol * 100).toStringAsFixed(1)}%');
        riskScore += 0.15;
      }
    }

    // Règle: Série de pertes
    final recentTrades = ctx.history.take(5).toList();
    final losingStreak = _losingStreak(recentTrades, ctx);
    if (losingStreak >= 3) {
      warnings.add('🔴 Série de $losingStreak pertes consécutives — réduction automatique de la taille des positions');
      riskScore += 0.2;
    }

    // Momentum récent
    if (pct < -5) {
      warnings.add('🟠 Baisse brutale de ${pct.toStringAsFixed(1)}% sur 24h — vérifier les fondamentaux');
      riskScore += 0.1;
    }

    report.writeln('Capital total: ${fmt(totalValue)}');
    report.writeln('Exposition $symbol: ${(posValue > 0 ? posValue / totalValue * 100 : 0).toStringAsFixed(1)}%');
    report.writeln('Exposition totale: ${(exposurePct * 100).toStringAsFixed(0)}%');
    report.writeln('Drawdown journalier: ${(ddPct * 100).toStringAsFixed(1)}%');
    report.writeln('Perte max autorisée par trade: ${(maxTradeValue).toStringAsFixed(2)} USDT\n');

    if (warnings.isNotEmpty) {
      report.writeln('⚠ **Alertes**');
      for (final w in warnings) {
        report.writeln('- $w');
      }
      report.writeln();
    }

    if (circuitBreaker) {
      report.writeln('⛔ **CIRCUIT BREAKER ACTIVÉ** — Trading suspendu jusqu\'à réévaluation.');
      riskScore = 1.0;
    } else if (riskScore >= 0.5) {
      report.writeln('⚠ **Risque élevé** — Réduire l\'exposition, privilégier la protection du capital.');
    } else if (riskScore >= 0.2) {
      report.writeln('🟡 **Risque modéré** — Surveillance renforcée, stops serrés.');
    } else {
      report.writeln('✅ **Risque maîtrisé** — Conditions de trading acceptables.');
    }

    final recommendations = <String>[];
    if (circuitBreaker) recommendations.add('SUSPENDRE_TRADING');
    if (exposurePct > _maxExposure * 0.7) recommendations.add('REDUIRE_EXPOSITION');
    if (ddPct.abs() > _maxDailyLoss * 0.5) recommendations.add('MODE_DEFENSIF');
    if (riskScore < 0.3) recommendations.add('NORMAL');

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(1.0 - riskScore),
      summary: report.toString(),
      recommendation: recommendations.join(','),
      details: {
        'riskScore': riskScore,
        'circuitBreaker': circuitBreaker,
        'exposurePct': exposurePct,
        'dailyDrawdown': ddPct,
        'maxTradeValue': maxTradeValue,
        'maxQty': maxQty,
        'riskLevel': circuitBreaker ? 'CRITICAL' : riskScore >= 0.5 ? 'HIGH' : riskScore >= 0.2 ? 'MODERATE' : 'LOW',
      },
    );
  }

  double _positionsValue(AgentContext ctx) {
    return ctx.positions.fold(0.0, (s, p) {
      final price = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * price;
    });
  }

  double _symbolExposure(String symbol, AgentContext ctx) {
    final pos = ctx.positions.where((p) => p.symbol == symbol).firstOrNull;
    if (pos == null) return 0;
    final price = ctx.prices[symbol] ?? 0;
    return pos.qty * price;
  }

  double _dailyLoss(AgentContext ctx) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    // Track realized PnL from sells + current open position PnL
    double realizedPnl = 0;
    double currentPnl = 0;

    for (final t in ctx.history) {
      if (!t.time.contains(todayStr)) continue;
      // Realized trade: sell side
      if (t.side == 'sell') {
        final pos = ctx.positions.where((p) => p.symbol == t.symbol).firstOrNull;
        final entryPrice = pos?.entryPrice ?? t.price;
        realizedPnl += (t.price - entryPrice) * t.qty;
      }
    }

    // Unrealized PnL for current positions
    for (final pos in ctx.positions) {
      final curPrice = ctx.prices[pos.symbol] ?? pos.entryPrice;
      currentPnl += pos.pnl(curPrice);
    }

    return realizedPnl + currentPnl;
  }

  int _losingStreak(List<TradeSnapshot> trades, AgentContext ctx) {
    int streak = 0;
    for (final t in trades) {
      if (t.side == 'buy') continue;
      // Compare sell price to price from paired buy (approximate)
      final pairedBuy = ctx.history
          .where((h) => h.symbol == t.symbol && h.side == 'buy')
          .toList();
      if (pairedBuy.isEmpty) continue;
      final avgBuyPrice = pairedBuy.fold(0.0, (s, b) => s + b.price) / pairedBuy.length;
      final pnl = (t.price - avgBuyPrice) * t.qty;
      if (pnl < 0) streak++;
      else break;
    }
    return streak;
  }
}
