import 'dart:async';
import 'dart:convert';
import '../services/multi_llm_coordinator.dart';

class AutonomousBrain {
  final MultiLLMCoordinator _coordinator;
  final Function(String action, Map<String, dynamic> params) onAction;

  AutonomousBrain(this._coordinator, {required this.onAction});

  // ── RISK MANAGEMENT ──
  Future<void> adjustRisk({
    required double stopLossPct,
    required double takeProfitPct,
    required double maxPositionPct,
    String reason = '',
  }) async {
    onAction('adjust_risk', {
      'stopLoss': stopLossPct,
      'takeProfit': takeProfitPct,
      'maxPosition': maxPositionPct,
      'reason': reason,
    });
  }

  // ── PORTFOLIO MANAGEMENT ──
  Future<void> executeTrade({
    required String symbol,
    required String side,
    required double quantity,
    String reason = '',
  }) async {
    onAction('execute_trade', {
      'symbol': symbol,
      'side': side,
      'quantity': quantity,
      'reason': reason,
    });
  }

  // ── SETTINGS MODIFICATION ──
  Future<void> modifySettings({
    bool? tradingEnabled,
    bool? notificationsEnabled,
    String? defaultModel,
    String? responseMode,
    String reason = '',
  }) async {
    onAction('modify_settings', {
      'tradingEnabled': tradingEnabled,
      'notificationsEnabled': notificationsEnabled,
      'defaultModel': defaultModel,
      'responseMode': responseMode,
      'reason': reason,
    });
  }

  // ── CHAT WITH LLM ──
  Future<String> chat(String message, {String? systemContext}) async {
    return _coordinator.chat(
      prompt: message,
      taskType: 'chat',
      systemContext: systemContext ?? 'Tu es NOAH, un assistant de trading intelligent et amical. Tu peux gérer le portefeuille, ajuster les risques, et modifier les paramètres. Réponds en français.',
    );
  }

  // ── ANALYZE MARKET ──
  Future<Map<String, dynamic>> analyzeMarket(String symbol, Map<String, dynamic> data) async {
    final prompt = '''
Analyse le marché pour $symbol:
${jsonEncode(data)}

Fournis:
1. Tendance (BULLISH/BEARISH/NEUTRAL)
2. Niveau de confiance (0-100)
3. Action recommandée (BUY/SELL/HOLD)
4. Stop Loss recommandé (%)
5. Take Profit recommandé (%)
6. Raison courte

Réponds JSON: {"trend":"...","confidence":85,"action":"BUY","sl":3,"tp":6,"reason":"..."}
''';

    try {
      final reply = await _coordinator.chat(prompt: prompt, taskType: 'deep_analysis');
      final jsonStart = reply.indexOf('{');
      final jsonEnd = reply.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd >= 0) {
        return jsonDecode(reply.substring(jsonStart, jsonEnd + 1));
      }
    } catch (_) {}
    return {'trend': 'NEUTRAL', 'confidence': 0, 'action': 'HOLD', 'reason': 'analyse échouée'};
  }

  // ── MANAGE PORTFOLIO ──
  Future<Map<String, dynamic>> managePortfolio(Map<String, dynamic> portfolioData) async {
    final prompt = '''
État du portefeuille:
${jsonEncode(portfolioData)}

Analyse et recommande:
1. Faut-il rééquilibrer?
2. Y a-t-il des positions à couper?
3. Y a-t-il des opportunités d'achat?
4. Gestion des risques recommandée

Réponds JSON: {"rebalance":false,"cut":[],"buy":[],"riskAdvice":"..."}
''';

    try {
      final reply = await _coordinator.chat(prompt: prompt, taskType: 'portfolio');
      final jsonStart = reply.indexOf('{');
      final jsonEnd = reply.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd >= 0) {
        return jsonDecode(reply.substring(jsonStart, jsonEnd + 1));
      }
    } catch (_) {}
    return {'rebalance': false, 'cut': [], 'buy': [], 'riskAdvice': 'erreur'};
  }

  // ── RISK ASSESSMENT ──
  Future<Map<String, dynamic>> assessRisk(Map<String, dynamic> marketData) async {
    final prompt = '''
Évalue les risques actuels:
${jsonEncode(marketData)}

Fournis:
1. Score de risque (0-100)
2. Niveau (LOW/MEDIUM/HIGH/EXTREME)
3. Recommandations
4. Action recommandée

Réponds JSON: {"riskScore":45,"level":"MEDIUM","recommendations":["..."],"action":"HOLD"}
''';

    try {
      final reply = await _coordinator.chat(prompt: prompt, taskType: 'risk');
      final jsonStart = reply.indexOf('{');
      final jsonEnd = reply.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd >= 0) {
        return jsonDecode(reply.substring(jsonStart, jsonEnd + 1));
      }
    } catch (_) {}
    return {'riskScore': 50, 'level': 'MEDIUM', 'recommendations': [], 'action': 'HOLD'};
  }
}
