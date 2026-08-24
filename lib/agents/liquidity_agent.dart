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
        agentName: name,
        confidence: 0.5,
        summary: 'Pas de données de carnet pour $symbol.',
        recommendation: 'HOLD',
        details: {'status': 'no_data'},
      );
    }

    final bestBid = bids.isNotEmpty ? bids.first[0] : 0.0;
    final bestAsk = asks.isNotEmpty ? asks.first[0] : 0.0;
    final spread = bestAsk > 0 && bestBid > 0
        ? ((bestAsk - bestBid) / bestAsk) * 100
        : 0;
    final spreadBps = spread * 100;

    final threshold = price * 0.01;
    double bidDepth = 0, askDepth = 0;
    for (final b in bids) {
      if (b[0] >= price - threshold) bidDepth += b[1];
    }
    for (final a in asks) {
      if (a[0] <= price + threshold) askDepth += a[1];
    }
    final depthRatio = askDepth > 0 ? bidDepth / askDepth : 0;

    final slippage = _estimateSlippage(bids, asks, price, 1000);

    double liqScore;
    if (spreadBps < 5 && slippage < 0.1)
      liqScore = 0.9;
    else if (spreadBps < 20 && slippage < 0.5)
      liqScore = 0.7;
    else if (spreadBps < 50 && slippage < 1)
      liqScore = 0.5;
    else
      liqScore = 0.3;

    final buf = StringBuffer();
    buf.writeln('**💧 Liquidité $symbol**\n');
    buf.writeln(
      'Spread: ${spread.toStringAsFixed(3)}% (${spreadBps.toStringAsFixed(1)} bps)',
    );
    buf.writeln('Depth ratio (bid/ask): ${depthRatio.toStringAsFixed(2)}');
    buf.writeln('Slippage estimé (1000\$): ${slippage.toStringAsFixed(2)}%');
    buf.writeln('Score liquidité: ${(liqScore * 100).toStringAsFixed(0)}%');

    if (spreadBps > 50) buf.writeln('⚠ Spread élevé — exécution coûteuse');
    if (depthRatio < 0.5)
      buf.writeln('⚠ Asymétrie carnet — pression vendeuse dominante');
    if (depthRatio > 2.0) buf.writeln('✅ Forte demande — support solide');

    String rec = 'HOLD';
    if (liqScore >= 0.7 && depthRatio > 1.2)
      rec = 'BUY';
    else if (liqScore < 0.3 || depthRatio < 0.5)
      rec = 'SELL';

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(liqScore),
      summary: buf.toString(),
      recommendation: rec,
      details: {
        'spread': spread.toStringAsFixed(3),
        'spreadBps': spreadBps.toStringAsFixed(1),
        'depthRatio': depthRatio.toStringAsFixed(2),
        'slippage': slippage.toStringAsFixed(2),
        'liqScore': liqScore.toStringAsFixed(2),
        'bestBid': bestBid,
        'bestAsk': bestAsk,
        'bidDepth': bidDepth,
        'askDepth': askDepth,
      },
    );
  }

  double _estimateSlippage(
    List<List<double>> bids,
    List<List<double>> asks,
    double price,
    double tradeSizeUsd,
  ) {
    if (price <= 0 || tradeSizeUsd <= 0) return 0;

    double remaining = tradeSizeUsd;
    double totalCost = 0;
    double totalQty = 0;

    for (final ask in asks) {
      final askPrice = ask[0];
      final askQty = ask[1];
      final layerValue = askPrice * askQty;
      if (layerValue >= remaining) {
        final qtyNeeded = remaining / askPrice;
        totalCost += remaining;
        totalQty += qtyNeeded;
        remaining = 0;
        break;
      } else {
        totalCost += layerValue;
        totalQty += askQty;
        remaining -= layerValue;
      }
    }

    if (remaining > 0) return 10.0;
    final avgPrice = totalQty > 0 ? totalCost / totalQty : price;
    return ((avgPrice - price) / price) * 100;
  }
}
