import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

enum LLMRole { speed, analyst, fallback, local, community }

class ConnectedLLM {
  final String name;
  final String model;
  final LLMRole role;
  final String? apiKey;
  final String baseUrl;
  bool isConnected;
  int usedToday;
  final int maxPerDay;
  DateTime? lastReset;

  ConnectedLLM({
    required this.name,
    required this.model,
    required this.role,
    this.apiKey,
    required this.baseUrl,
    this.isConnected = false,
    this.usedToday = 0,
    this.maxPerDay = 1000,
  });

  bool get available {
    _checkReset();
    return isConnected && usedToday < maxPerDay;
  }

  double get usagePercent => maxPerDay > 0 ? usedToday / maxPerDay : 1.0;

  void _checkReset() {
    final now = DateTime.now();
    if (lastReset == null || now.difference(lastReset!).inHours >= 24) {
      usedToday = 0;
      lastReset = now;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'model': model,
    'role': role.name,
    'isConnected': isConnected,
    'usedToday': usedToday,
    'maxPerDay': maxPerDay,
    'usagePercent': usagePercent,
  };
}

class MultiLLMCoordinator {
  static final MultiLLMCoordinator _instance = MultiLLMCoordinator._();
  factory MultiLLMCoordinator() => _instance;
  MultiLLMCoordinator._();

  final Dio _dio = Dio();
  final List<ConnectedLLM> _connectedLLMs = [];
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  List<ConnectedLLM> get connectedLLMs => List.unmodifiable(_connectedLLMs);

  // ── REGISTRATION ──
  void registerLLM({
    required String name,
    required String model,
    required LLMRole role,
    String? apiKey,
    required String baseUrl,
    int maxPerDay = 1000,
  }) {
    _connectedLLMs.removeWhere((l) => l.name == name);
    _connectedLLMs.add(ConnectedLLM(
      name: name,
      model: model,
      role: role,
      apiKey: apiKey,
      baseUrl: baseUrl,
      isConnected: apiKey != null && apiKey.isNotEmpty,
      maxPerDay: maxPerDay,
    ));
    _notifyStatus();
  }

  void disconnectLLM(String name) {
    final llm = _connectedLLMs.firstWhere((l) => l.name == name, orElse: () => ConnectedLLM(name: '', model: '', role: LLMRole.fallback, baseUrl: ''));
    llm.isConnected = false;
    _notifyStatus();
  }

  // ── SMART ROUTING ──
  Future<String> chat({
    required String prompt,
    required String taskType,
    String? systemContext,
    double temperature = 0.7,
  }) async {
    // Select best LLM for task
    final llm = _selectBestLLM(taskType);
    if (llm == null) throw Exception('Aucun LLM disponible pour cette tâche');

    try {
      final result = await _callLLM(llm, prompt, systemContext, temperature);
      llm.usedToday++;
      _notifyStatus();
      return result;
    } catch (e) {
      // Try fallback
      final fallback = _getFallback(llm);
      if (fallback != null) {
        final result = await _callLLM(fallback, prompt, systemContext, temperature);
        fallback.usedToday++;
        _notifyStatus();
        return result;
      }
      rethrow;
    }
  }

  ConnectedLLM? _selectBestLLM(String taskType) {
    final available = _connectedLLMs.where((l) => l.available).toList();
    if (available.isEmpty) return null;

    switch (taskType) {
      case 'trading_signal':
        // Speed is critical
        final speed = available.where((l) => l.role == LLMRole.speed);
        if (speed.isNotEmpty) return speed.first;
        break;
      case 'deep_analysis':
        // Quality + context
        final analyst = available.where((l) => l.role == LLMRole.analyst);
        if (analyst.isNotEmpty) return analyst.first;
        break;
      case 'chat':
        // Any available
        break;
      case 'portfolio':
        // Any available
        break;
      case 'risk':
        // Any available
        break;
    }

    // Default: least used
    available.sort((a, b) => a.usagePercent.compareTo(b.usagePercent));
    return available.first;
  }

  ConnectedLLM? _getFallback(ConnectedLLM current) {
    final available = _connectedLLMs.where((l) => l.available && l.name != current.name).toList();
    if (available.isEmpty) return null;

    // Prefer fallback role
    final fallbacks = available.where((l) => l.role == LLMRole.fallback);
    if (fallbacks.isNotEmpty) return fallbacks.first;

    return available.first;
  }

  // ── LLM CALLS ──
  Future<String> _callLLM(ConnectedLLM llm, String prompt, String? systemCtx, double temp) async {
    if (llm.baseUrl.contains('groq.com') || llm.baseUrl.contains('openrouter.ai')) {
      return _callOpenAICompatible(llm, prompt, systemCtx, temp);
    } else if (llm.baseUrl.contains('googleapis.com')) {
      return _callGemini(llm, prompt, systemCtx, temp);
    } else {
      return _callOpenAICompatible(llm, prompt, systemCtx, temp);
    }
  }

  Future<String> _callOpenAICompatible(ConnectedLLM llm, String prompt, String? systemCtx, double temp) async {
    final messages = <Map<String, String>>[];
    if (systemCtx != null) {
      messages.add({'role': 'system', 'content': systemCtx});
    }
    messages.add({'role': 'user', 'content': prompt});

    final response = await _dio.post(
      '${llm.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${llm.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': llm.model,
        'messages': messages,
        'temperature': temp,
        'max_tokens': 1024,
      },
    );

    return response.data['choices'][0]['message']['content'];
  }

  Future<String> _callGemini(ConnectedLLM llm, String prompt, String? systemCtx, double temp) async {
    final contents = <Map<String, dynamic>>[];

    if (systemCtx != null) {
      contents.add({
        'role': 'user',
        'parts': [{'text': systemCtx}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Compris.'}],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final response = await _dio.post(
      '${llm.baseUrl}/models/${llm.model}:generateContent?key=${llm.apiKey}',
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
      data: {
        'contents': contents,
        'generationConfig': {
          'temperature': temp,
          'maxOutputTokens': 1024,
        },
      },
    );

    return response.data['candidates'][0]['content']['parts'][0]['text'];
  }

  // ── AUTONOMOUS CAPABILITIES ──
  Future<Map<String, dynamic>> autonomousDecision({
    required String task,
    required Map<String, dynamic> context,
  }) async {
    final prompt = '''
Tu es le cerveau de NOAH, un trading bot autonome.

TÂCHE: $task
CONTEXTE: ${jsonEncode(context)}

Tu peux:
1. Modifier les paramètres de risque (stopLoss, takeProfit, maxPosition)
2. Acheter/Vendre des actifs
3. Modifier les settings de l'app
4. Activer/Désactiver le trading

Réponds JSON: {"action":"具体 action","params":{...},"reason":"explication"}
''';

    final reply = await chat(prompt: prompt, taskType: 'trading_signal');

    try {
      final jsonStart = reply.indexOf('{');
      final jsonEnd = reply.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd >= 0) {
        return jsonDecode(reply.substring(jsonStart, jsonEnd + 1));
      }
    } catch (_) {}
    return {'action': 'none', 'reason': 'parse error'};
  }

  // ── STATUS ──
  Map<String, dynamic> getStatus() => {
    'totalConnected': _connectedLLMs.where((l) => l.isConnected).length,
    'totalAvailable': _connectedLLMs.where((l) => l.available).length,
    'llms': _connectedLLMs.map((l) => l.toJson()).toList(),
  };

  void _notifyStatus() {
    _statusController.add(getStatus());
  }

  void dispose() {
    _statusController.close();
  }
}
