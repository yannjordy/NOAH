import 'agent_base.dart';

class LiquidityAgent extends BaseAgent {
  @override
  String get name => 'Liquidité';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final bids = ctx.bids[symbol] ?? [];
    final asks = ctx.asks[symbol] ?? [];
    final price = ctx.prices[symbol] ?? 0;

    if (bids.isEmpty || asks.isEmpty || price <= 0) {
      return AgentReport(
        agentName: name, confidence: 0.5,
        summary: 'Pas de données de carnet pour $symbol.',
        recommendation: 'HOLD',
        details: {'status': 'no_data'},
      );
    }

    // Bid-ask spread
    final bestBid = bids.isNotEmpty ? bids.first[0] : 0.0;
    final bestAsk = asks.isNotEmpty ? asks.first[0] : 0.0;
    final spread = bestAsk > 0 && bestBid > 0 ? ((bestAsk - bestBid) / bestAsk) * 100 : 0;
    final spreadBps = spread * 100;

    // Depth ratio (bid volume / ask volume within 1%)
    final threshold = price * 0.01;
    double bidDepth = 0, askDepth = 0;
    for (final b in bids) { if (b[0] >= price - threshold) bidDepth += b[1]; }
    for (final a in asks) { if (a[0] <= price + threshold) askDepth += a[1]; }
    final depthRatio = askDepth > 0 ? bidDepth / askDepth : 0;

    // Slippage estimate
    final slippage = _estimateSlippage(bids, asks, price, 1000);

    // Liquidity score
    double liqScore;
    if (spreadBps < 5 && slippage < 0.1) liqScore = 0.9;
    else if (spreadBps < 20 && slippage < 0.5) liqScore = 0.7;
    else if (spreadBps < 50 && slippage < 1) liqScore = 0.5;
    else liqScore = 0.3;

    final buf = StringBuffer();
    buf.writeln('**💧 Liquidité $symbol**\n');
    buf.writeln('Spread: ${spread.toStringAsFixed(3)}% (${spreadBps.toStringAsFixed(1)} bps)');
    buf.writeln('Depth ratio (bid/ask): ${depthRatio.toStringAsFixed(2)}');
    buf.writeln('Slippage estimé (1000\$): ${slippage.toStringAsFixed(2)}%');
    buf.writeln('Score liquidité: ${(liqScore * 100).toStringAsFixed(0)}%');

    if (spreadBps > 50) buf.writeln('⚠ Spread élevé — exécution coûteuse');
    if (depthRatio < 0.5) buf.writeln('⚠ Asymétrie carnet — pression vendeuse');
    if (depthRatio > 2.0) buf.writeln('⚠ Asymétrie carnet — pression acheteuse');

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(liqScore),
      summary: buf.toString(),
      recommendation: spreadBps > 100 ? 'HOLD' : 'HOLD',
      details: {
        'spreadBps': spreadBps,
        'depthRatio': depthRatio,
        'slippage': slippage,
        'liqScore': liqScore,
        'bestBid': bestBid,
        'bestAsk': bestAsk,
      },
    );
  }

  double _estimateSlippage(List<List<double>> bids, List<List<double>> asks, double price, double dollarAmount) {
    double remaining = dollarAmount;
    double totalCost = 0;
    for (final a in asks) {
      final cost = a[0] * a[1];
      if (cost >= remaining) { totalCost += remaining; break; }
      totalCost += cost;
      remaining -= cost;
    }
    final avgPrice = dollarAmount > 0 ? totalCost / dollarAmount : price;
    return price > 0 ? ((avgPrice / price - 1) * 100).abs() : 0;
  }
}
