import 'agent_base.dart';

class AttributionAgent extends BaseAgent {
  @override
  String get name => 'Attribution';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final totalTrades = ctx.history.length;
    final wins = ctx.history.where((t) => t.side == 'sell').length;
    final bestSymbol = ctx.history.isNotEmpty
        ? ctx.history.groupBy((t) => t.symbol).entries
            .map((e) => MapEntry(e.key, e.value.fold(0.0, (s, t) => s + (t.price * t.qty))))
            .fold<MapEntry<String, double>?>(
                null,
                (best, e) => best == null || e.value > best.value ? e : best)
            ?.key
        : null;

    return AgentReport(
      agentName: name,
      confidence: 0.6,
      summary: 'Attribution: $totalTrades trades historiques',
      details: {
        'totalTrades': totalTrades,
        'wins': wins,
        'bestSymbol': bestSymbol ?? 'N/A',
      },
    );
  }
}

extension _GroupBy<T> on List<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final k = key(item);
      map.putIfAbsent(k, () => []).add(item);
    }
    return map;
  }
}
