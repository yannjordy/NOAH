import 'agent_base.dart';

class PortfolioAgent extends BaseAgent {
  @override
  String get name => 'Alexendra';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final totalValue = ctx.usdtBalance + ctx.positions.fold(0.0, (s, p) {
      final price = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * price;
    });

    final posValue = ctx.positions.fold(0.0, (s, p) {
      final price = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * price;
    });

    final usdtRatio = totalValue > 0 ? ctx.usdtBalance / totalValue : 1.0;

    double totalPnl = 0;
    for (final pos in ctx.positions) {
      final price = ctx.prices[pos.symbol] ?? 0;
      totalPnl += pos.pnl(price);
    }

    final summary = StringBuffer('Analyse portefeuille\n');
    summary.writeln('Capital USDT: \$${ctx.usdtBalance.toStringAsFixed(2)}');
    summary.writeln('Valeur positions: \$${posValue.toStringAsFixed(2)}');
    summary.writeln('Valeur totale: \$${totalValue.toStringAsFixed(2)}');
    summary.writeln('Exposition USDT: ${(usdtRatio * 100).toStringAsFixed(0)}%');
    summary.writeln('Positions: ${ctx.positions.length}');

    String rec;
    if (usdtRatio > 0.7) {
      rec = 'UNDER_INVESTED';
    } else if (usdtRatio < 0.2) {
      rec = 'OVER_EXPOSED';
    } else {
      rec = 'BALANCED';
    }

    return AgentReport(
      agentName: name,
      confidence: 0.8,
      summary: summary.toString(),
      recommendation: rec,
      details: {
        'totalValue': totalValue,
        'positionsValue': posValue,
        'usdtBalance': ctx.usdtBalance,
        'usdtRatio': usdtRatio,
        'pnl': totalPnl,
        'positionCount': ctx.positions.length,
      },
    );
  }
}
