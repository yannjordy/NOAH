import 'dart:convert';
import 'package:dio/dio.dart';

class OllamaService {
  final Dio _dio;
  String _model;

  OllamaService({String baseUrl = 'http://localhost:8001', String model = 'gemma'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 180),
          headers: {'Content-Type': 'application/json'},
        )),
        _model = model;

  String get model => _model;
  set model(String m) => _model = m;

  Future<bool> healthCheck() async {
    try {
      final resp = await _dio.get('/api/ollama/tags');
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> listModels() async {
    try {
      final resp = await _dio.get('/api/ollama/tags');
      final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data as String) as Map;
      final models = data['models'] as List? ?? [];
      return models.map((m) => (m as Map)['name'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> sendMessage(String text, {String? systemContext}) async {
    try {
      final messages = <Map<String, String>>[
        if (systemContext != null && systemContext.isNotEmpty)
          {'role': 'system', 'content': systemContext}
        else
          {
            'role': 'system',
            'content': 'Tu es NOAH, un assistant IA spécialisé en trading et analyse financière. '
                'Tu aides les utilisateurs à comprendre les marchés crypto, les risques, et les stratégies. '
                'Réponds en français, sois concis et professionnel.'
          },
        {'role': 'user', 'content': text},
      ];
      final resp = await _dio.post('/api/ollama/chat', data: {
        'model': _model,
        'messages': messages,
        'stream': false,
      });
      if (resp.statusCode != 200) {
        return '❌ Erreur Ollama (${resp.statusCode})';
      }
      final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data as String) as Map;
      final message = data['message'] as Map?;
      return (message?['content'] as String?) ?? '⚠️ Réponse vide';
    } catch (e) {
      return '❌ Erreur de connexion à Ollama: $e';
    }
  }

  void dispose() {
    _dio.close();
  }
}
