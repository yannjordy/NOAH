import '../models/models.dart';
import '../models/blocks.dart';

/// Result of executing an AI action.
class ActionResult {
  final bool success;
  final String message;
  final MessageBlock? block;

  ActionResult({required this.success, required this.message, this.block});
}

/// AI tool system — context building, command parsing, action execution.
class AITools {
  /// Build a system context string with current app state.
  static String buildSystemContext({
    Map<String, double>? prices,
    Map<String, double>? pcts,
    PortfolioData? portfolio,
    double? riskScore,
    double? exposure,
    double? dailyDrawdown,
    bool? circuitBreaker,
    String? riskLevel,
    List<Signal>? signals,
    bool isDemo = true,
  }) {
    final buf = StringBuffer();

    buf.writeln("Tu es NOAH, un assistant de trading IA. Tu as accès aux données suivantes et peux agir sur le portfolio.");
    buf.writeln("Réponds en français, sois concis et professionnel.");
    buf.writeln("");

    buf.writeln(isDemo
        ? "Mode: DÉMO — les trades sont fictifs, l'argent est virtuel."
        : "Mode: RÉEL — l'argent est réel, chaque trade a un impact financier. Sois encore plus prudent.");
    buf.writeln("");

    if (prices != null && prices.isNotEmpty) {
      buf.writeln("## Prix du marché");
      for (final e in prices.entries) {
        final pct = pcts?[e.key];
        final pctStr = pct != null ? "${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%" : "";
        buf.writeln("- ${e.key}/USDT: \$${e.value.toStringAsFixed(2)} $pctStr");
      }
      buf.writeln("");
    }

    if (portfolio != null) {
      buf.writeln("## Portfolio");
      buf.writeln("- USDT disponible: \$${portfolio.usdt.toStringAsFixed(2)}");
      buf.writeln("- Valeur positions: \$${portfolio.positionsValue.toStringAsFixed(2)}");
      buf.writeln("- Valeur totale: \$${portfolio.totalValue.toStringAsFixed(2)}");
      buf.writeln("- PnL: ${portfolio.pnl >= 0 ? '+' : ''}\$${portfolio.pnl.toStringAsFixed(2)} (${portfolio.pnlPct.toStringAsFixed(2)}%)");
      if (portfolio.positions.isNotEmpty) {
        buf.writeln("");
        buf.writeln("### Positions ouvertes");
        for (final p in portfolio.positions) {
          final cur = prices?[p.sym] ?? p.entry;
          final pnlP = p.entry > 0 ? ((cur - p.entry) / p.entry * 100) : 0.0;
          buf.writeln("- ${p.sym}: ${p.qty.toStringAsFixed(4)} @ \$${p.entry.toStringAsFixed(2)} (PnL: ${pnlP >= 0 ? '+' : ''}${pnlP.toStringAsFixed(2)}%)");
          if (p.stopLoss != null) buf.writeln("  Stop Loss: \$${p.stopLoss!.toStringAsFixed(2)}");
          if (p.takeProfit != null) buf.writeln("  Take Profit: \$${p.takeProfit!.toStringAsFixed(2)}");
        }
      }
      buf.writeln("");
    }

    buf.writeln("## Risque");
    buf.writeln("- Score risque: ${riskScore?.toStringAsFixed(2) ?? 'N/A'}");
    buf.writeln("- Exposition: ${exposure?.toStringAsFixed(1) ?? 'N/A'}%");
    buf.writeln("- Drawdown journalier: ${dailyDrawdown?.toStringAsFixed(2) ?? 'N/A'}%");
    buf.writeln("- Circuit breaker: ${circuitBreaker == true ? 'ACTIVÉ' : 'Désactivé'}");
    buf.writeln("- Niveau: ${riskLevel ?? 'N/A'}");
    buf.writeln("");

    if (signals != null && signals.isNotEmpty) {
      buf.writeln("## Signaux actuels");
      for (final s in signals) {
        buf.writeln("- ${s.sym}: ${s.type} (confiance: ${(s.conf * 100).toStringAsFixed(0)}%)");
      }
      buf.writeln("");
    }

    buf.writeln("## Actions et Templates disponibles");
    buf.writeln("Tu peux executer des actions et afficher des templates visuels en incluant des commandes [ACTION:...] dans ta réponse.");
    buf.writeln("Les templates sont des cartes visuelles qui rendent les donnees plus claires.");
    buf.writeln("");

    buf.writeln("### Trade");
    buf.writeln('[ACTION:{"type":"trade","side":"BUY|SELL","symbol":"BTC","qty":0.01,"stopLoss":64000,"takeProfit":70000}]');
    buf.writeln("");

    buf.writeln("### Depot");
    buf.writeln('[ACTION:{"type":"deposit","amount":1000}]');
    buf.writeln("");

    buf.writeln("### Graphiques (line, pie, bar)");
    buf.writeln('[ACTION:{"type":"chart","chartType":"line","title":"BTC","series":[67000,67500,68000]}]');
    buf.writeln('[ACTION:{"type":"chart","chartType":"pie","title":"Repartition","labels":["USDT","BTC"],"values":[5000,3000]}]');
    buf.writeln('[ACTION:{"type":"chart","chartType":"bar","title":"Volumes","labels":["J1","J2"],"values":[100,200]}]');
    buf.writeln("");

    buf.writeln("### Carte de prix (a utiliser quand tu parles d'un prix)");
    buf.writeln('[ACTION:{"type":"template","templateType":"priceCard","symbol":"BTC","price":67000,"change":2.5,"direction":"up"}]');
    buf.writeln("Mots cles declencheurs: prix, cours, valeur, cote, price, value, quote, montant, tarif");
    buf.writeln("");

    buf.writeln("### En-tete de signal (a utiliser quand tu donnes un signal)");
    buf.writeln('[ACTION:{"type":"template","templateType":"signalHeader","action":"BUY|SELL|HOLD","symbol":"BTC","confidence":0.85,"price":67000,"change":2.5}]');
    buf.writeln("Mots cles declencheurs: signal, achat, vente, buy, sell, hold, opportunite, recommandation");
    buf.writeln("");

    buf.writeln("### Jauge de risque (a utiliser quand tu parles du risque)");
    buf.writeln('[ACTION:{"type":"template","templateType":"riskGauge","score":0.3,"label":"Faible","circuitBreaker":false}]');
    buf.writeln("Mots cles declencheurs: risque, risk, score, exposition, drawdown, volatilite, securite, niveau de risque");
    buf.writeln("");

    buf.writeln("### Resume de portefeuille (a utiliser pour les chiffres du portefeuille)");
    buf.writeln('[ACTION:{"type":"template","templateType":"portfolioSummary","usdt":5000,"positionsValue":3000,"totalValue":8000,"pnl":150,"pnlPct":2.5}]');
    buf.writeln("Mots cles declencheurs: portefeuille, portfolio, capital, solde, balance, patrimoine, compte, argent, fonds, USDT disponible, valeur totale, PnL");
    buf.writeln("");

    buf.writeln("### Tableau (a utiliser pour afficher des donnees structurees)");
    buf.writeln('[ACTION:{"type":"template","templateType":"table","title":"Positions","headers":["Symbole","Prix","Change"],"rows":[["BTC","67000","+2.5%"],["ETH","3400","-1.2%"]]}]');
    buf.writeln("Mots cles declencheurs: tableau, table, positions, liste, recapitulatif, apercu, details");
    buf.writeln("");

    buf.writeln("### Carte de signal detaillee");
    buf.writeln('[ACTION:{"type":"template","templateType":"signalCard","signal":"BUY","symbol":"BTC","confidence":0.85,"price":67000,"reason":"Tendance haussiere"]');
    buf.writeln("");

    buf.writeln("### Stop automatique");
    buf.writeln("Si l'utilisateur dit 'arrete', 'stop', 'ne fais rien', ou toute autre phrase d'arret, reponds avec:");
    buf.writeln('[ACTION:{"type":"stop"}]');
    buf.writeln("");

    buf.writeln("### Regles importantes:");
    buf.writeln("- Ne trade JAMAIS sans avoir assez de USDT disponible");
    buf.writeln("- Verifie toujours le score de risque avant de trader (risque > 0.7 = n'achete pas)");
    buf.writeln("- Circuit breaker actif = ne trade PAS");
    buf.writeln("- Sois conservateur: pas plus de 20% du portfolio par trade");
    buf.writeln("- Explique toujours tes decisions en francais");
    buf.writeln("- Ecris d'abord une reponse en texte complete et naturelle, comme un conseiller humain");
    buf.writeln("- Les templates [ACTION:template...] sont des cartes visuelles optionnelles que tu AJOUTES a ton texte pour illustrer les donnees importantes");
    buf.writeln("- Ne fais PAS que des templates sans texte — le texte est obligatoire, les templates sont en supplement");
    buf.writeln("- Inspire-toi de cet exemple:");
    buf.writeln("  Texte: \"Le BTC est actuellement a \$67,000 avec une hausse de 2.5%. L'analyse technique montre un RSI a 62, en zone neutre.\"");
    buf.writeln('  + Template: [ACTION:{"type":"template","templateType":"priceCard","symbol":"BTC","price":67000,"change":2.5,"isUp":true}]');
    buf.writeln("- Tu peux inclure plusieurs actions/templates dans une seule reponse");
    buf.writeln("- Si tu mentionnes un prix, tu PEUX (pas obligatoire) ajouter une priceCard");
    buf.writeln("- Si tu mentionnes un montant ou PnL, tu PEUX ajouter un portfolioSummary");
    buf.writeln("- Si tu parles de risque, tu PEUX ajouter une riskGauge");

    return buf.toString();
  }

  /// Parse actions from AI response text.
  static List<Map<String, dynamic>> parseActions(String text) {
    final actions = <Map<String, dynamic>>[];
    final regex = RegExp(r'\[ACTION:\{(.+?)\}\]');
    final matches = regex.allMatches(text);
    for (final m in matches) {
      try {
        final jsonStr = '{${m.group(1)}}';
        final data = _parseSimpleJson(jsonStr);
        if (data != null) actions.add(data);
      } catch (_) {}
    }
    return actions;
  }

  /// Remove action markers from text for display.
  static String cleanResponse(String text) {
    return text.replaceAll(RegExp(r'\[ACTION:\{(.+?)\}\]'), '').trim();
  }

  /// Parse all templates and charts from a list of action data.
  static List<MessageBlock> parseBlocksFromActions(List<Map<String, dynamic>> actions) {
    final blocks = <MessageBlock>[];
    for (final action in actions) {
      final type = action['type'] as String? ?? '';
      if (type == 'chart') {
        final chart = chartFromAction(action);
        if (chart != null) blocks.add(chart);
      } else if (type == 'template') {
        final template = templateFromAction(action);
        if (template != null) blocks.add(template);
      } else if (type == 'trade') {
        final symbol = action['symbol'] as String? ?? '';
        final side = action['side'] as String? ?? '';
        final confidence = (action['confidence'] as num?)?.toDouble() ?? 0.5;
        if (symbol.isNotEmpty && side.isNotEmpty) {
          blocks.add(MessageBlock.signalHeader(
            action: side.toUpperCase(),
            confidence: confidence,
            symbol: symbol,
            price: (action['price'] as num?)?.toDouble() ?? 0,
            change: 0,
            period: 'instant',
          ));
        }
      }
    }
    return blocks;
  }

  /// Build a template MessageBlock from AI action data.
  static MessageBlock? templateFromAction(Map<String, dynamic> action) {
    final tplType = action['templateType'] as String? ?? '';

    if (tplType == 'priceCard') {
      final symbol = action['symbol'] as String? ?? '';
      final price = (action['price'] as num?)?.toDouble() ?? 0;
      final change = (action['change'] as num?)?.toDouble() ?? 0;
      if (symbol.isNotEmpty && price > 0) {
        return MessageBlock.priceCard(symbol: symbol, price: price, change: change, isUp: change >= 0);
      }
    }

    if (tplType == 'signalHeader') {
      final act = action['action'] as String? ?? '';
      final symbol = action['symbol'] as String? ?? '';
      final conf = (action['confidence'] as num?)?.toDouble() ?? 0.5;
      final price = (action['price'] as num?)?.toDouble() ?? 0;
      final change = (action['change'] as num?)?.toDouble() ?? 0;
      if (act.isNotEmpty && symbol.isNotEmpty) {
        return MessageBlock.signalHeader(
          action: act, confidence: conf, symbol: symbol,
          price: price, change: change, period: 'now',
        );
      }
    }

    if (tplType == 'riskGauge') {
      final score = (action['score'] as num?)?.toDouble() ?? 0.0;
      final cb = action['circuitBreaker'] as bool? ?? false;
      return MessageBlock.riskGauge(
        riskScore: score, exposure: 0.0, dailyDrawdown: 0.0,
        circuitBreaker: cb, riskLevel: score > 0.7 ? 'Élevé' : score > 0.4 ? 'Modéré' : 'Faible',
      );
    }

    if (tplType == 'portfolioSummary') {
      final usdt = (action['usdt'] as num?)?.toDouble() ?? 0.0;
      final posVal = (action['positionsValue'] as num?)?.toDouble() ?? 0.0;
      final total = (action['totalValue'] as num?)?.toDouble() ?? 0.0;
      final pnl = (action['pnl'] as num?)?.toDouble() ?? 0.0;
      final pnlPct = (action['pnlPct'] as num?)?.toDouble() ?? 0.0;
      final usdtRatio = total > 0 ? (usdt / total * 100) : 100.0;
      return MessageBlock.portfolioSummary(
        usdt: usdt, posValue: posVal, totalValue: total,
        pnl: pnl, pnlPct: pnlPct, positionCount: 0, usdtRatio: usdtRatio,
      );
    }

    if (tplType == 'table') {
      final title = action['title'] as String? ?? '';
      final headers = (action['headers'] as List<dynamic>?)?.cast<String>() ?? [];
      final rowsData = action['rows'] as List<dynamic>?;
      if (headers.isNotEmpty && rowsData != null) {
        final rows = rowsData.map((r) => (r as List<dynamic>).cast<String>()).toList();
        return MessageBlock.table(title: title, headers: headers, rows: rows);
      }
    }

    if (tplType == 'signalCard') {
      final signal = action['signal'] as String? ?? '';
      final symbol = action['symbol'] as String? ?? '';
      final conf = (action['confidence'] as num?)?.toDouble() ?? 0;
      if (signal.isNotEmpty && symbol.isNotEmpty) {
        return MessageBlock.signalCard(
          action: signal, symbol: symbol, confidence: conf, isActive: true,
        );
      }
    }

    return null;
  }

  static const _priceKeywords = [
    'prix', 'cours', 'cotation', 'valeur', 'price', 'value', 'quote',
    'montant', 'tarif', 'cout', 'coût', 'evalue', 'estimé',
  ];

  static const _moneyKeywords = [
    'argent', 'fonds', 'capital', 'solde', 'portefeuille', 'portfolio',
    'compte', 'patrimoine', 'usdt', 'usd', 'dollar', 'montant',
    'valeur totale', 'total value',
  ];

  static const _riskKeywords = [
    'risque', 'risk', 'score', 'exposition', 'exposure', 'drawdown',
    'volatilite', 'volatility', 'securite', 'circuit breaker',
    'niveau de risque', 'risk level',
  ];

  /// Detect if text contains keywords for a specific template category.
  static bool hasPriceContext(String text) => _priceKeywords.any((k) => text.toLowerCase().contains(k));
  static bool hasMoneyContext(String text) => _moneyKeywords.any((k) => text.toLowerCase().contains(k));
  static bool hasRiskContext(String text) => _riskKeywords.any((k) => text.toLowerCase().contains(k));

  /// Auto-generate template blocks from text content analysis.
  /// Uses keyword detection + regex to find numbers/patterns in the AI's text.
  static MessageBlock? autoDetectBlock(String text, {String? symbol}) {

    // Detect priceCard patterns: "BTC à $67000", "prix: 67000", etc.
    final priceRegex = RegExp(r'(\w{2,5})\s*(?:à|:|=|est à|vaut|a\s*)\s*\$?(\d{1,2}(?:,\d{3})*(?:\.\d+)?)');
    if (hasPriceContext(text) || priceRegex.hasMatch(text)) {
      final match = priceRegex.firstMatch(text);
      if (match != null) {
        final sym = match.group(1)?.toUpperCase() ?? symbol ?? 'BTC';
        final priceStr = match.group(2)?.replaceAll(',', '') ?? '';
        final price = double.tryParse(priceStr);
        if (price != null && price > 0) {
          return MessageBlock.priceCard(symbol: sym, price: price, change: 0, isUp: false);
        }
      }
    }

    // Detect risk patterns: "risque: 0.3", "score: 30%", etc.
    final riskRegex = RegExp(r'(?:risque|risk|score|exposition)\s*(?:de|:|=|à)\s*(\d+(?:\.\d+)?)\s*%?');
    if (hasRiskContext(text) || riskRegex.hasMatch(text)) {
      final match = riskRegex.firstMatch(text);
      if (match != null) {
        final val = double.tryParse(match.group(1) ?? '');
        if (val != null) {
          final score = val > 1 ? val / 100 : val;
          final clamped = score.clamp(0.0, 1.0); return MessageBlock.riskGauge(riskScore: clamped, exposure: 0.0, dailyDrawdown: 0.0, circuitBreaker: false, riskLevel: clamped > 0.7 ? 'Élevé' : clamped > 0.4 ? 'Modéré' : 'Faible');
        }
      }
    }

    // Detect portfolio/money patterns
    final moneyRegex = RegExp(r'(?:solde|balance|capital|total|usdt|portefeuille)\s*(?:de|:|=|à|:.*?)\s*\$?(\d+(?:,\d{3})*(?:\.\d+)?)');
    if (hasMoneyContext(text) || moneyRegex.hasMatch(text)) {
      return MessageBlock.portfolioSummary(
        usdt: 0.0, posValue: 0.0, totalValue: 0.0, pnl: 0.0, pnlPct: 0.0, positionCount: 0, usdtRatio: 100.0,
      );
    }

    return null;
  }

  /// Main parser: extract all blocks from AI response text.
  /// Returns both explicit [ACTION:] blocks and auto-detected ones.
  static ({List<MessageBlock> blocks, String cleanText}) parseResponse(String text, {String? symbol}) {
    final actions = parseActions(text);
    final cleanText = AITools.cleanResponse(text);
    final blocks = parseBlocksFromActions(actions);

    // Auto-detect additional blocks from remaining text
    if (blocks.isEmpty) {
      final auto = autoDetectBlock(cleanText, symbol: symbol);
      if (auto != null) blocks.add(auto);
    }

    return (blocks: blocks, cleanText: cleanText);
  }

  /// Simple JSON parser (no deps).
  static Map<String, dynamic>? _parseSimpleJson(String json) {
    try {
      final result = <String, dynamic>{};
      final cleaned = json
          .replaceAll(RegExp(r'^\s*\{\s*'), '')
          .replaceAll(RegExp(r'\s*\}\s*$'), '');
      final pairs = _splitOutside(cleaned, ',');
      for (final pair in pairs) {
        final kv = _splitOutside(pair, ':');
        if (kv.length >= 2) {
          final key = _stripQuotes(kv[0].trim());
          var value = kv.sublist(1).join(':').trim();
          value = _stripQuotes(value);
          final numVal = num.tryParse(value);
          if (numVal != null) {
            result[key] = numVal;
          } else if (value == 'true') {
            result[key] = true;
          } else if (value == 'false') {
            result[key] = false;
          } else if (value.startsWith('[') && value.endsWith(']')) {
            final arrStr = value.substring(1, value.length - 1);
            final items = _splitOutside(arrStr, ',');
            final list = <dynamic>[];
            for (final item in items) {
              final trimmed = _stripQuotes(item.trim());
              final n = num.tryParse(trimmed);
              list.add(n ?? trimmed);
            }
            result[key] = list;
          } else {
            result[key] = value;
          }
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  static List<String> _splitOutside(String input, String delimiter) {
    final result = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < input.length; i++) {
      if (input[i] == '{' || input[i] == '[') depth++;
      if (input[i] == '}' || input[i] == ']') depth--;
      if (input[i] == delimiter[0] && depth == 0) {
        result.add(input.substring(start, i));
        start = i + 1;
      }
    }
    if (start < input.length) result.add(input.substring(start));
    return result;
  }

  static String _stripQuotes(String s) {
    if (s.length >= 2 && ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'")))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  /// Check if text contains a stop command.
  static bool isStopCommand(String text) {
    final lower = text.toLowerCase();
    final stopWords = [
      'arrête', 'arrete', 'stop', 'ne fais rien', 'ne fait rien',
      'arrête toi', 'arrete toi', 'ferme', 'tais', 'silence',
      'désactive', 'desactive', 'annule', 'cancel',
    ];
    return stopWords.any((w) => lower.contains(w));
  }
}

/// Build a chart MessageBlock from AI action data.
MessageBlock? chartFromAction(Map<String, dynamic> action) {
  final chartType = action['chartType'] as String? ?? '';
  final title = action['title'] as String? ?? '';

  if (chartType == 'line') {
    final series = (action['series'] as List<dynamic>?)?.cast<double>() ?? [];
    if (series.isEmpty) return null;
    return MessageBlock.lineChart(series: series, label: title);
  }

  if (chartType == 'pie') {
    final labels = (action['labels'] as List<dynamic>?)?.cast<String>() ?? [];
    final values = (action['values'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    if (labels.isEmpty || values.isEmpty) return null;
    return MessageBlock.pieChart(labels: labels, values: values, title: title);
  }

  if (chartType == 'bar') {
    final labels = (action['labels'] as List<dynamic>?)?.cast<String>() ?? [];
    final values = (action['values'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    if (labels.isEmpty || values.isEmpty) return null;
    return MessageBlock.barChart(labels: labels, values: values, title: title);
  }

  return null;
}
