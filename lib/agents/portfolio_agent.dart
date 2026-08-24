import 'agent_base.dart';

class PortfolioAgent extends BaseAgent {
  @override
  String get name => 'Alexendra';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final report = StringBuffer();
    final totalValue = ctx.usdtBalance + _positionsValue(ctx);
    final totalCost = ctx.positions.fold(0.0, (s, p) => s + p.qty * p.entryPrice);
    final pnl = _positionsValue(ctx) - totalCost;
    final pnlPct = totalCost > 0 ? (pnl / totalCost) * 100 : 0;

    report.writeln('**Vue du portefeuille**\n');
    report.writeln('Solde USDT: ${fmt(ctx.usdtBalance)}');
    report.writeln('Valeur des positions: ${fmt(_positionsValue(ctx))}');
    report.writeln('Capital total: ${fmt(totalValue)}');
    report.writeln('PnL réalisé + non réalisé: ${pnl >= 0 ? '+' : ''}${fmt(pnl)} (${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)');

    if (ctx.positions.isEmpty) {
      report.writeln('\nAucune position ouverte. Capital 100% en USDT.');
    } else {
      report.writeln('\n**Positions ouvertes**\n');
      report.writeln('Symbole | Qté | Entrée | Actuel | PnL');
      for (final pos in ctx.positions) {
        final curPrice = ctx.prices[pos.symbol] ?? 0;
        final posPnl = pos.pnl(curPrice);
        final posPnlPct = pos.pnlPct(curPrice);
        report.writeln('${pos.symbol} | ${pos.qty.toStringAsFixed(4)} | \$${pos.entryPrice.toStringAsFixed(2)} | \$${curPrice.toStringAsFixed(2)} | ${posPnl >= 0 ? '+' : ''}${fmt(posPnl)} (${posPnlPct >= 0 ? '+' : ''}${posPnlPct.toStringAsFixed(1)}%)');
      }

      // Allocation
      report.writeln('\n**Allocation par actif**');
      for (final pos in ctx.positions) {
        final curPrice = ctx.prices[pos.symbol] ?? 0;
        final posVal = pos.qty * curPrice;
        final allocPct = totalValue > 0 ? (posVal / totalValue) * 100 : 0;
        report.writeln('- ${pos.symbol}: ${allocPct.toStringAsFixed(1)}% du portefeuille');
      }

      // Ratio USDT / positions
      final usdtRatio = totalValue > 0 ? (ctx.usdtBalance / totalValue) * 100 : 100;
      report.writeln('\nUSDT: ${usdtRatio.toStringAsFixed(0)}% | Positions: ${(100 - usdtRatio).toStringAsFixed(0)}%');

      if (usdtRatio < 50) {
        report.writeln('\n⚠ Faible réserve USDT — Exposition élevée. Envisager de réduire les positions ou déposer des fonds.');
      }
    }

    // Derniers trades
    if (ctx.history.isNotEmpty) {
      report.writeln('\n**Dernières transactions**');
      for (final t in ctx.history.take(5)) {
        report.writeln('- ${t.side.toUpperCase()} ${t.qty.toStringAsFixed(4)} ${t.symbol} @ ${fmt(t.price)}');
      }
    }

    return AgentReport(
      agentName: name,
      confidence: totalValue > 0 ? 0.9 : 0.5,
      summary: report.toString(),
      details: {
        'usdtBalance': ctx.usdtBalance,
        'positionsValue': _positionsValue(ctx),
        'totalValue': totalValue,
        'pnl': pnl,
        'pnlPct': pnlPct,
        'openPositions': ctx.positions.length,
      },
    );
  }

  double _positionsValue(AgentContext ctx) {
    return ctx.positions.fold(0.0, (s, p) {
      final price = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * price;
    });
  }
}
