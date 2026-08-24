import 'agent_base.dart';
import '../utils.dart';

class TradingAgent extends BaseAgent {
  @override
  String get name => 'Dylan';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final report = StringBuffer();
    final price = ctx.prices[symbol] ?? 0;
    final klines = ctx.klines[symbol] ?? [];

    report.writeln('**Préparation ordre $symbol**\n');

    // Vérifier les positions existantes
    final pos = ctx.positions.where((p) => p.symbol == symbol).firstOrNull;

    if (pos != null) {
      final posPnl = pos.pnl(price);
      final posPnlPct = pos.pnlPct(price);
      report.writeln('Position ouverte: ${pos.qty.toStringAsFixed(4)} $symbol');
      report.writeln('Prix entrée: \$${pos.entryPrice.toStringAsFixed(2)}');
      report.writeln('PnL: ${posPnl >= 0 ? '+' : ''}${fmt(posPnl)} (${posPnlPct >= 0 ? '+' : ''}${posPnlPct.toStringAsFixed(2)}%)');

      if (pos.stopLoss != null) {
        report.writeln('Stop Loss: \$${pos.stopLoss!.toStringAsFixed(2)} (${((pos.stopLoss! / pos.entryPrice - 1) * 100).toStringAsFixed(1)}%)');
      }
      if (pos.takeProfit != null) {
        report.writeln('Take Profit: \$${pos.takeProfit!.toStringAsFixed(2)} (${((pos.takeProfit! / pos.entryPrice - 1) * 100).toStringAsFixed(1)}%)');
      }

      // Suggérer gestion de position existante
      if (posPnlPct > 5) {
        report.writeln('\n📈 Position bénéficiaire — Envisager de déplacer le stop loss au-dessus du prix d\'entrée (trailing stop).');
      } else if (posPnlPct < -3) {
        report.writeln('\n📉 Position perdante — Vérifier si la thèse d\'investissement tient toujours. Stop loss à respecter strictement.');
      }
    } else {
      report.writeln('Aucune position ouverte sur $symbol.');
      // Suggérer des niveaux d'entrée basés sur les données disponibles
      if (klines.length >= 20) {
        final closes = klines.map((k) => k.close).toList();
        final lows = klines.map((k) => k.low).toList();
        final recentLow = lows.sublist(lows.length - 20).reduce((a, b) => a < b ? a : b);
        final recentHigh = closes.sublist(closes.length - 20).reduce((a, b) => a > b ? a : b);

        report.writeln('\n📊 Zone d\'achat: \$${recentLow.toStringAsFixed(2)} - \$${(recentLow * 1.02).toStringAsFixed(2)}');
        report.writeln('Zone de vente: \$${(recentHigh * 0.98).toStringAsFixed(2)} - \$${recentHigh.toStringAsFixed(2)}');
      }
    }

    // Calculate order size based on available balance
    final maxPositionValue = ctx.usdtBalance * 0.25;
    final maxQty = price > 0 ? maxPositionValue / price : 0;
    report.writeln('\nTaille d\'ordre max recommandée: ${maxQty.toStringAsFixed(6)} $symbol (${fmt(maxPositionValue)})');

    return AgentReport(
      agentName: name,
      confidence: price > 0 ? 0.7 : 0.3,
      summary: report.toString(),
      recommendation: pos != null ? 'MANAGE_POSITION' : 'ENTRY_PREPARED',
      details: {
        'price': price,
        'hasPosition': pos != null,
        'maxQty': maxQty,
        'stopLossLevel': pos?.stopLoss,
        'takeProfitLevel': pos?.takeProfit,
      },
    );
  }
}
