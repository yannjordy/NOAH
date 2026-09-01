import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

/// Service client pour le backend Alex Desktop (FastAPI sur port 8765).
/// Permet a NOAH d'utiliser l'intelligence, la memoire et les outils d'Alex.
class AlexBrainService {
  final Dio _dio;
  bool _connected = false;
  String _userName = 'Utilisateur';
  Map<String, dynamic> _userFacts = {};

  AlexBrainService({String baseUrl = 'http://127.0.0.1:8765'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (_) => true,
        ));

  bool get isConnected => _connected;
  String get userName => _userName;
  Map<String, dynamic> get userFacts => _userFacts;

  /// Verifie si le backend Alex est disponible
  Future<bool> checkConnection() async {
    try {
      final res = await _dio.get('/health');
      _connected = res.statusCode == 200;
      if (_connected) {
        await _loadUserFacts();
      }
      return _connected;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  /// Charge les faits utilisateur depuis la memoire d'Alex
  Future<void> _loadUserFacts() async {
    try {
      final res = await _dio.get('/memory/facts');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          _userFacts = data;
          _userName = data['name']?.toString() ?? 'Utilisateur';
        }
      }
    } catch (_) {}
  }

  /// Recupere le resume des conversations recentes d'Alex
  Future<String> getConversationContext() async {
    try {
      final res = await _dio.get('/memory');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          final facts = data['facts'] as List? ?? [];
          if (facts.isNotEmpty) {
            return 'Connaissance utilisateur (Alex): ${facts.take(10).map((f) => f['content'] ?? f['fact'] ?? '').join('; ')}';
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// Envoie un message au LLM d'Alex et recoit la reponse (streaming SSE)
  Future<String> chatWithAlex(String message, {String? systemPrompt}) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'user': _userName,
      };
      if (systemPrompt != null) {
        body['system'] = systemPrompt;
      }

      final res = await _dio.post('/chat/opencode',
          data: body,
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            responseType: ResponseType.stream,
          ));

      if (res.statusCode == 200) {
        final stream = res.data as Stream;
        final buffer = StringBuffer();
        await for (final chunk in stream) {
          final text = utf8.decode(chunk);
          for (final line in text.split('\n')) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') break;
              try {
                final json = jsonDecode(data);
                final content = json['choices']?[0]?['delta']?['content'];
                if (content != null) buffer.write(content);
              } catch (_) {}
            }
          }
        }
        return buffer.toString();
      }
    } catch (_) {}
    return '';
  }

  /// Execute un outil Alex directement (web search, weather, etc.)
  Future<Map<String, dynamic>?> executeTool(String toolName, {Map<String, dynamic>? params}) async {
    try {
      final res = await _dio.post('/tools/execute', data: {
        'tool': toolName,
        'params': params ?? {},
      });
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  /// Recherche web via Alex (DuckDuckGo)
  Future<String> webSearch(String query) async {
    final result = await executeTool('web_search', params: {'query': query});
    if (result != null && result['success'] == true) {
      return result['result']?.toString() ?? '';
    }
    return '';
  }

  /// Recupere la meteo via Alex
  Future<String> getWeather(String city) async {
    final result = await executeTool('weather', params: {'city': city});
    if (result != null && result['success'] == true) {
      return result['result']?.toString() ?? '';
    }
    return '';
  }

  /// Recupere les informations systeme via Alex
  Future<String> getSystemInfo() async {
    final result = await executeTool('system_info', params: {});
    if (result != null && result['success'] == true) {
      return result['result']?.toString() ?? '';
    }
    return '';
  }

  /// Analyse l'ecran via Alex (vision)
  Future<String> analyzeScreen({String? question}) async {
    try {
      final res = await _dio.post('/vision/ask', data: {
        'question': question ?? 'Decris ce que tu vois a l\'ecran',
      });
      if (res.statusCode == 200) {
        return res.data['answer']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Recupere le resume des connaissances d'Alex pour le contexte LLM
  Future<String> getLearningContext() async {
    if (!_connected) return '';

    final buffer = StringBuffer();

    // Faits utilisateur
    if (_userFacts.isNotEmpty) {
      buffer.writeln('## Profil Utilisateur (via Alex)');
      _userFacts.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          buffer.writeln('- $key: $value');
        }
      });
    }

    // Contexte conversationnel
    final convCtx = await getConversationContext();
    if (convCtx.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(convCtx);
    }

    return buffer.toString();
  }

  /// Recherche web pour enrichir l'analyse de marche
  Future<String> searchMarketNews(String query) async {
    return await webSearch('crypto $query actualites marche');
  }

  /// Verifie la securite du systeme (scan Alex)
  Future<String> securityCheck() async {
    final result = await executeTool('scan_systeme', params: {});
    if (result != null && result['success'] == true) {
      return result['result']?.toString() ?? '';
    }
    return '';
  }

  /// Envoie une demande de decision de trading au cerveau d'Alex
  /// Retourne une Map avec action, confidence, reason, positionSizePct
  Future<Map<String, dynamic>?> getTradingDecision({
    required String symbol,
    required double currentPrice,
    required Map<String, dynamic> technicalData,
    required String marketContext,
  }) async {
    if (!_connected) return null;

    final prompt = '''Tu es le cerveau de trading de NOAH. Analyse et donne UNE decision precise.

SYMBOL: $symbol
PRIX ACTUEL: \$$currentPrice
DONNEES TECHNIQUES: $technicalData
CONTEXTE MARCHE: $marketContext

Reponds UNIQUEMENT avec un JSON valide:
{"action": "BUY"|"SELL"|"HOLD", "confidence": 0.0-1.0, "reason": "explication courte", "positionSizePct": 5-25, "sl_pct": 3, "tp_pct": 6}

Regles:
- BUY si confiance > 0.6
- SELL si positions ouvertes et signal de sortie
- HOLD si pas d'opportunite claire
- positionSizePct: taille en % du portefeuille
- SL: 3% par defaut, TP: 6% (ratio 1:2)''';

    try {
      final response = await chatWithAlex(prompt);
      if (response.isEmpty) return null;

      // Extraire le JSON de la reponse
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
      if (jsonMatch == null) return null;

      final decision = Map<String, dynamic>.from(
        // Use jsonDecode on the matched string
        await _parseJson(jsonMatch.group(0)!) ?? {},
      );

      if (decision.containsKey('action')) {
        return decision;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _parseJson(String text) async {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Recupere un resume de marche enrichi par Alex (recherche web + memoire)
  Future<String> getEnrichedMarketContext(String symbol) async {
    if (!_connected) return '';

    final buffer = StringBuffer();

    // Recherche web via Alex
    final news = await searchMarketNews('$symbol tendance prix');
    if (news.isNotEmpty) {
      buffer.writeln('Actualites: ${news.substring(0, news.length.clamp(0, 500))}');
    }

    // Faits utilisateur pertinents
    if (_userFacts.isNotEmpty) {
      buffer.writeln('Profil: ${_userFacts.entries.take(3).map((e) => '${e.key}=${e.value}').join(', ')}');
    }

    return buffer.toString();
  }
}
