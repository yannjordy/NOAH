import 'agent_base.dart';

class AttributionAgent extends BaseAgent {
  @override
  String get name => 'Attribution';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final trades = ctx.history;
    if (trades.isEmpty) {
      return AgentReport(
        agentName: name, confidence: 0.5,
        summary: 'Aucun trade à analyser.',
        recommendation: 'HOLD',
        details: {'status': 'no_trades'},
      );
    }

    // Per-symbol PnL
    final bySymbol = <String, double>{};
    final byDirection = <String, double>{'buy': 0, 'sell': 0};
    double totalPnl = 0;

    for (final t in trades) {
      final side = t.side;
      bySymbol[t.symbol] = (bySymbol[t.symbol] ?? 0) + (side == 'sell' ? 1 : 0);
      byDirection[side] = (byDirection[side] ?? 0) + 1;
      totalPnl += (side == 'sell' ? 1 : -1) * t.qty;
    }

    // Best & worst symbols
    final sorted = bySymbol.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.isNotEmpty ? sorted.first.key : '';
    final worst = sorted.length > 1 ? sorted.last.key : '';

    final buf = StringBuffer();
    buf.writeln('**📊 Attribution de performance**\n');
    buf.writeln('Trades analysés: ${trades.length}');
    buf.writeln('');

    if (best.isNotEmpty) buf.writeln('⭐ Meilleur: $best (${bySymbol[best]?.toStringAsFixed(0) ?? "0"} trades gagnants)');
    if (worst.isNotEmpty && worst != best) buf.writeln('⚠ Pire: $worst (${bySymbol[worst]?.toStringAsFixed(0) ?? "0"} trades gagnants)');
    buf.writeln('');
    buf.writeln('Achats: ${byDirection['buy'] ?? 0} | Ventes: ${byDirection['sell'] ?? 0}');

    if (byDirection['buy'] != null && byDirection['sell'] != null && byDirection['buy']! + byDirection['sell']! > 0) {
      final buyRatio = byDirection['buy']! / (byDirection['buy']! + byDirection['sell']!);
      buf.writeln('Ratio buy/sell: ${(buyRatio * 100).toStringAsFixed(0)}/ ${((1-buyRatio)*100).toStringAsFixed(0)}');
    }

    final avgTrade = trades.length > 0 ? totalPnl / trades.length : 0;
    buf.writeln('PnL moyen par trade: ${avgTrade >= 0 ? "+" : ""}\$${avgTrade.toStringAsFixed(2)}');

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(trades.length > 10 ? 0.8 : 0.5),
      summary: buf.toString(),
      recommendation: 'HOLD',
      details: {
        'totalTrades': trades.length,
        'bestSymbol': best,
        'worstSymbol': worst,
        'buyCount': byDirection['buy'],
        'sellCount': byDirection['sell'],
        'avgTradePnl': avgTrade,
        'uniqueSymbols': bySymbol.length,
      },
    );
  }
}
