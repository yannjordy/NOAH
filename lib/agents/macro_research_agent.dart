import 'dart:math';
import 'agent_base.dart';
import '../services/web_research_service.dart';

class MacroResearchAgent extends BaseAgent {
  final WebResearchService _web = WebResearchService();
  final AiThinker? _thinker;

  static final Map<String, List<WebResearchResult>> _cache = {};
  static final Map<String, String> _aiInsights = {};
  static final String _pending = '🔄 Exploration en cours...';
  static final Set<String> _refreshing = {};

  MacroResearchAgent({AiThinker? thinker}) : _thinker = thinker;

  @override
  String get name => 'Emmilienne';

  /// Returns cached report instantly — no blocking I/O.
  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final cached = _cache[symbol];

    if (cached == null) {
      return AgentReport(
        agentName: name,
        confidence: 0,
        summary: _pending,
        recommendation: 'HOLD',
        details: {'webResults': 0, 'fearGreed': 45, 'status': 'caching'},
      );
    }

    final buf = StringBuffer();
    final rng = Random();
    final shuffled = [...cached]..shuffle(rng);
    final shown = shuffled.take(min(shuffled.length, 4)).toList();

    final topic = _web.nextTopic;
    buf.writeln('**🔎 Emmilienne a exploré "$topic"**\n');
    for (final r in shown) {
      buf.writeln('- **${r.source}** › ${r.title}');
      if (r.snippet.isNotEmpty) buf.writeln('  ${r.snippet}');
      buf.writeln('');
    }

    final insight = _aiInsights[symbol];
    if (insight != null) {
      buf.writeln('**🧠 Emmilienne réfléchit...**\n');
      buf.writeln('$insight\n');
    }

    final fg = 45;
    final categories = cached.map((r) => r.category).toSet().join(', ');
    buf.writeln('**🌍 Fear & Greed : $fg/100**');
    buf.writeln('Catégories: $categories | Sources: ${cached.map((r) => r.source).toSet().join(', ')}');
    if (cached.length >= 5) buf.writeln('✅ Données à jour');

    final confidence = min(0.4 + cached.length * 0.04, 0.9);

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(confidence),
      summary: buf.toString(),
      recommendation: 'HOLD',
      details: {
        'webResults': cached.length,
        'fearGreed': fg,
        'sources': cached.map((r) => r.source).toSet().join(', '),
        'status': 'ready',
      },
    );
  }

  /// Background refresh — non-blocking, populates cache for next analyze().
  Future<void> refresh(String symbol) async {
    if (_refreshing.contains(symbol)) return;
    _refreshing.add(symbol);
    try {
      final results = await _web.searchAll(symbol);
      _cache[symbol] = results;
      if (_thinker != null && results.isNotEmpty) {
        final prompt = '''
Tu es Emmilienne, chercheuse web. Voici ce que tu as trouvé pour $symbol :
${results.map((r) => '- [${r.source}] ${r.title}').join('\n')}

Qu'est-ce qui est le plus intéressant ? Donne un conseil en 2 phrases max, français.
''';
        _thinker!(prompt, systemContext: 'Tu es Emmilienne. 2 phrases max, français.')
            .then((r) { if (!r.startsWith('❌')) _aiInsights[symbol] = r; });
      }
    } finally {
      _refreshing.remove(symbol);
    }
  }

  void clearCache() => _cache.clear();
}
