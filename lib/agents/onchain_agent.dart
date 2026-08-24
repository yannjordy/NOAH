import 'agent_base.dart';

class OnchainAgent extends BaseAgent {
  final AiThinker? _thinker;

  OnchainAgent({AiThinker? thinker}) : _thinker = thinker;

  @override
  String get name => 'Chaîne';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final base = symbol.replaceAll('USDT', '').replaceAll('USD', '');
    final price = ctx.prices[symbol] ?? 0;
    final pct = ctx.pcts[symbol] ?? 0;

    final whaleConfidence = _simulateWhaleActivity(base, price, pct);
    final exchangeFlow = _simulateExchangeFlow(base, pct);
    final networkHealth = _simulateNetworkHealth(base);

    final buf = StringBuffer();
    buf.writeln('**⛓ Analyse on-chain pour $symbol**\n');

    buf.writeln('**Baleines:** ${whaleConfidence > 0.6 ? "🐋 Accumulation détectée" : whaleConfidence > 0.4 ? "Neutre" : "Distribution détectée"}');
    buf.writeln('**Flux exchanges:** ${exchangeFlow > 0 ? "📤 Sortant (HODL)" : "📥 Entrant (vente potentielle)"}');
    buf.writeln('**Réseau:** $networkHealth');
    buf.writeln('');

    final score = (whaleConfidence + exchangeFlow.abs() + (networkHealth == 'Actif' ? 0.3 : 0)) / 3;

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(score),
      summary: buf.toString(),
      recommendation: score > 0.6 ? 'BUY' : (score < 0.3 ? 'SELL' : 'HOLD'),
      details: {
        'whaleScore': whaleConfidence,
        'exchangeFlow': exchangeFlow,
        'networkHealth': networkHealth,
        'status': 'simulated',
      },
    );
  }

  double _simulateWhaleActivity(String base, double price, double pct) {
    if (base == 'BTC' || base == 'ETH') return 0.55 + (pct > 0 ? 0.1 : -0.1);
    if (pct < -3) return 0.7;
    if (pct > 5) return 0.3;
    return 0.5;
  }

  double _simulateExchangeFlow(String base, double pct) {
    return pct > 2 ? -0.3 : (pct < -2 ? 0.4 : 0.0);
  }

  String _simulateNetworkHealth(String base) {
    return 'Actif';
  }
}
