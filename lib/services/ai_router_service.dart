import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

enum AIRole { quickDecision, deepAnalysis, fallback }

class AIProvider {
  final String name;
  final String baseUrl;
  String? apiKey;
  final String model;
  final int maxTokensPerDay;
  final int rpm;
  int _usedToday = 0;
  DateTime? _lastReset;

  AIProvider({
    required this.name,
    required this.baseUrl,
    this.apiKey,
    required this.model,
    required this.maxTokensPerDay,
    required this.rpm,
  });

  bool get available {
    _checkReset();
    return _usedToday < maxTokensPerDay;
  }

  double get usagePercent => maxTokensPerDay > 0 ? _usedToday / maxTokensPerDay : 1.0;

  void _checkReset() {
    final now = DateTime.now();
    if (_lastReset == null || now.difference(_lastReset!).inHours >= 24) {
      _usedToday = 0;
      _lastReset = now;
    }
  }

  void incrementUsage() {
    _usedToday++;
  }
}

class AIRouterService {
  static final AIRouterService _instance = AIRouterService._();
  factory AIRouterService() => _instance;
  AIRouterService._();

  final Dio _dio = Dio();

  // Providers with specific roles
  late final AIProvider _groq = AIProvider(
    name: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    apiKey: null, // Set by user
    model: 'llama-3.3-70b-versatile',
    maxTokensPerDay: 1000,
    rpm: 30,
  );

  late final AIProvider _gemini = AIProvider(
    name: 'Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    apiKey: null, // Set by user
    model: 'gemini-3.7-flash',
    maxTokensPerDay: 1500,
    rpm: 15,
  );

  late final AIProvider _openrouter = AIProvider(
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    apiKey: null,
    model: 'google/gemma-4-31b-it:free',
    maxTokensPerDay: 1000,
    rpm: 20,
  );

  // Configuration
  void setGroqKey(String key) => _groq.apiKey = key;
  void setGeminiKey(String key) => _gemini.apiKey = key;
  void setOpenRouterKey(String key) => _openrouter.apiKey = key;

  // Get provider status
  Map<String, dynamic> getStatus() => {
    'groq': {
      'available': _groq.available,
      'usage': _groq.usagePercent,
      'remaining': _groq.maxTokensPerDay - _groq._usedToday,
    },
    'gemini': {
      'available': _gemini.available,
      'usage': _gemini.usagePercent,
      'remaining': _gemini.maxTokensPerDay - _gemini._usedToday,
    },
    'openrouter': {
      'available': _openrouter.available,
      'usage': _openrouter.usagePercent,
      'remaining': _openrouter.maxTokensPerDay - _openrouter._usedToday,
    },
  };

  // Smart routing based on task type
  Future<String> chat({
    required String prompt,
    required AIRole role,
    String? systemContext,
    double temperature = 0.7,
  }) async {
    switch (role) {
      case AIRole.quickDecision:
        return _routeQuickDecision(prompt, systemContext, temperature);
      case AIRole.deepAnalysis:
        return _routeDeepAnalysis(prompt, systemContext, temperature);
      case AIRole.fallback:
        return _routeFallback(prompt, systemContext, temperature);
    }
  }

  // QUICK DECISION → Groq (speed priority)
  Future<String> _routeQuickDecision(String prompt, String? systemCtx, double temp) async {
    if (_groq.available && _groq.apiKey != null) {
      try {
        final result = await _callOpenAICompatible(_groq, prompt, systemCtx, temp);
        _groq.incrementUsage();
        return result;
      } catch (e) {
        // Fallback to next provider
      }
    }

    // Fallback: OpenRouter free
    if (_openrouter.available && _openrouter.apiKey != null) {
      try {
        final result = await _callOpenAICompatible(_openrouter, prompt, systemCtx, temp);
        _openrouter.incrementUsage();
        return result;
      } catch (e) {
        // Continue to Gemini
      }
    }

    // Last resort: Gemini
    if (_gemini.available && _gemini.apiKey != null) {
      try {
        final result = await _callGemini(_gemini, prompt, systemCtx, temp);
        _gemini.incrementUsage();
        return result;
      } catch (e) {
        throw Exception('Tous les providers sont indisponibles');
      }
    }

    throw Exception('Aucun provider configuré');
  }

  // DEEP ANALYSIS → Gemini (context + quality priority)
  Future<String> _routeDeepAnalysis(String prompt, String? systemCtx, double temp) async {
    if (_gemini.available && _gemini.apiKey != null) {
      try {
        final result = await _callGemini(_gemini, prompt, systemCtx, temp);
        _gemini.incrementUsage();
        return result;
      } catch (e) {
        // Fallback
      }
    }

    // Fallback: Groq (still good quality, just faster)
    if (_groq.available && _groq.apiKey != null) {
      try {
        final result = await _callOpenAICompatible(_groq, prompt, systemCtx, temp);
        _groq.incrementUsage();
        return result;
      } catch (e) {
        // Continue
      }
    }

    // Last resort: OpenRouter
    if (_openrouter.available && _openrouter.apiKey != null) {
      try {
        final result = await _callOpenAICompatible(_openrouter, prompt, systemCtx, temp);
        _openrouter.incrementUsage();
        return result;
      } catch (e) {
        throw Exception('Tous les providers sont indisponibles');
      }
    }

    throw Exception('Aucun provider configuré');
  }

  // FALLBACK → Any available provider
  Future<String> _routeFallback(String prompt, String? systemCtx, double temp) async {
    // Try in order: OpenRouter → Groq → Gemini
    for (final provider in [_openrouter, _groq, _gemini]) {
      if (provider.available && provider.apiKey != null) {
        try {
          String result;
          if (provider == _gemini) {
            result = await _callGemini(provider, prompt, systemCtx, temp);
          } else {
            result = await _callOpenAICompatible(provider, prompt, systemCtx, temp);
          }
          provider.incrementUsage();
          return result;
        } catch (e) {
          continue;
        }
      }
    }

    throw Exception('Aucun provider disponible');
  }

  // OpenAI-compatible API call (Groq, OpenRouter)
  Future<String> _callOpenAICompatible(AIProvider provider, String prompt, String? systemCtx, double temp) async {
    final messages = <Map<String, String>>[];
    if (systemCtx != null) {
      messages.add({'role': 'system', 'content': systemCtx});
    }
    messages.add({'role': 'user', 'content': prompt});

    final response = await _dio.post(
      '${provider.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${provider.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': provider.model,
        'messages': messages,
        'temperature': temp,
        'max_tokens': 1024,
      },
    );

    return response.data['choices'][0]['message']['content'];
  }

  // Gemini API call
  Future<String> _callGemini(AIProvider provider, String prompt, String? systemCtx, double temp) async {
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
      '${provider.baseUrl}/models/${provider.model}:generateContent?key=${provider.apiKey}',
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

  // Convenience methods for specific trading tasks
  Future<String> quickTradeSignal(String symbol, Map<String, dynamic> data) async {
    final prompt = 'Signal trading rapide pour $symbol: $data. Réponds JSON: {"action":"BUY/SELL/HOLD","confidence":0.0-1.0,"reason":"phrase"}';
    return chat(prompt: prompt, role: AIRole.quickDecision, systemContext: 'Tu es un trader IA rapide. Réponds en JSON uniquement.');
  }

  Future<String> deepMarketAnalysis(String symbol, Map<String, dynamic> context) async {
    final prompt = 'Analyse approfondie de $symbol:\n$context\n\nFournis une analyse détaillée avec: tendance, supports/résistances, risques, opportunité.';
    return chat(prompt: prompt, role: AIRole.deepAnalysis, systemContext: 'Tu es un analyste marché expert. Analyse détaillée requise.');
  }

  Future<String> fallbackQuery(String prompt) async {
    return chat(prompt: prompt, role: AIRole.fallback, systemContext: 'Tu es un assistant IA helpful.');
  }
}
