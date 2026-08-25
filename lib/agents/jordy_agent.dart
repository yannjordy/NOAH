import 'dart:math';
import 'agent_base.dart';

class SupervisionReport {
  final int alerts;
  final int warnings;
  final int ok;
  final List<String> flags;
  final double healthScore;

  SupervisionReport({
    required this.alerts, required this.warnings, required this.ok,
    required this.flags, required this.healthScore,
  });
}

class JordyAgent extends BaseAgent {
  JordyAgent();

  @override
  String get name => 'Jordy';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final flags = <String>[];
    int alerts = 0, warnings = 0, ok = 0;

    // Check 1: Portfolio health
    final totalValue = ctx.usdtBalance + _posValue(ctx);
    final posRatio = totalValue > 0 ? _posValue(ctx) / totalValue : 0;
    if (posRatio > 0.8) { alerts++; flags.add('⚠ Exposition >80% — risque élevé'); }
    else if (posRatio > 0.6) { warnings++; flags.add('⚠ Exposition ${(posRatio*100).toStringAsFixed(0)}% — à surveiller'); }
    else { ok++; }

    // Check 2: USDT reserve
    final usdtRatio = totalValue > 0 ? ctx.usdtBalance / totalValue : 1;
    if (usdtRatio < 0.2) { alerts++; flags.add('⚠ Réserve USDT <20% — marge insuffisante'); }
    else if (usdtRatio > 0.8) { warnings++; flags.add('ℹ  ${(usdtRatio*100).toStringAsFixed(0)}% en USDT — capital inactif'); }
    else { ok++; }

    // Check 3: Concentration
    final posMap = <String, double>{};
    for (final p in ctx.positions) {
      posMap[p.symbol] = (posMap[p.symbol] ?? 0) + p.qty * (ctx.prices[p.symbol] ?? 0);
    }
    if (posMap.length == 1 && posRatio > 0.3) {
      alerts++; flags.add('⚠ Portefeuille concentré sur ${posMap.keys.first}');
    }
    if (ctx.positions.length > 10) { warnings++; flags.add('ℹ  ${ctx.positions.length} positions — dispersion élevée'); }

    // Check 4: Recent PnL
    if (ctx.history.length >= 5) {
      final recent = ctx.history.sublist(ctx.history.length - min(5, ctx.history.length));
      final losses = recent.where((t) => t.side == 'sell').length;
      if (losses >= 4) { alerts++; flags.add('⚠ ${losses}/5 dernières sorties en perte — revoir stratégie'); }
    }

    // Check 5: Risk consistency
    if (ctx.positions.isNotEmpty && usdtRatio < 0.1) {
      alerts++; flags.add('⚠ Positions ouvertes sans réserve — liquidation risk');
    }

    final healthScore = max(0.0, 1.0 - (alerts * 0.3 + warnings * 0.1));
    final buf = StringBuffer();
    buf.writeln('**🛡 Jordy — Rapport de supervision**\n');
    buf.writeln('Santé système: ${(healthScore * 100).toStringAsFixed(0)}% '
        '($ok OK / $warnings warnings / $alerts alerts)\n');
    if (flags.isEmpty) { buf.writeln('✅ Tout est vert.'); }
    else { for (final f in flags) buf.writeln('$f\n'); }

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(healthScore),
      summary: buf.toString(),
      recommendation: healthScore > 0.7 ? 'HOLD' : (alerts > 0 ? 'SELL' : 'HOLD'),
      details: {
        'healthScore': healthScore,
        'alerts': alerts, 'warnings': warnings, 'ok': ok,
        'exposurePct': posRatio * 100,
        'usdtRatio': usdtRatio * 100,
        'flags': flags,
      },
    );
  }

  double _posValue(AgentContext ctx) => ctx.positions.fold(0.0, (s, p) =>
      s + p.qty * (ctx.prices[p.symbol] ?? 0));
}
