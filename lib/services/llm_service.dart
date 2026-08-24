import 'dart:convert';
import 'package:dio/dio.dart';

class LlmService {
  final Dio _dio;
  String _apiKey;
  String _model;

  LlmService({String baseUrl = 'https://api.openai.com/v1', String apiKey = '', String model = 'gpt-4o'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (_) => true,
        )),
        _apiKey = apiKey,
        _model = model;

  String get model => _model;
  set model(String m) => _model = m;

  String get apiKey => _apiKey;
  set apiKey(String k) => _apiKey = k;

  void updateConfig({String? baseUrl, String? apiKey, String? model}) {
    if (baseUrl != null) _dio.options.baseUrl = baseUrl;
    if (apiKey != null) _apiKey = apiKey;
    if (model != null) _model = model;
  }

  Future<bool> healthCheck() async {
    try {
      final resp = await _dio.get('/models',
          options: Options(headers: {'Authorization': 'Bearer $_apiKey'}));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> sendMessage(String text, {String? systemContext, List<String>? images}) async {
    if (_apiKey.isEmpty) {
      return '❌ Clé API non configurée. Allez dans Connexions pour ajouter votre clé.';
    }
    try {
      final userContent = <Map<String, dynamic>>[
        {'type': 'text', 'text': text},
        if (images != null)
          for (final img in images)
            {'type': 'image_url', 'image_url': {'url': img.startsWith('http') ? img : 'data:image/jpeg;base64,$img'}},
      ];

      final messages = <Map<String, dynamic>>[
        if (systemContext != null && systemContext.isNotEmpty)
          {'role': 'system', 'content': systemContext}
        else
          {
            'role': 'system',
            'content': 'Tu es NOAH, un assistant IA spécialisé en trading et analyse financière. '
                'Tu aides les utilisateurs à comprendre les marchés crypto, les risques, et les stratégies. '
                'Réponds en français, sois concis et professionnel.'
          },
        {'role': 'user', 'content': userContent.length == 1 ? text : userContent},
      ];
      final resp = await _dio.post('/chat/completions', data: {
        'model': _model,
        'messages': messages,
        'stream': false,
      }, options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        if (_dio.options.baseUrl.contains('openrouter.ai')) ...{
          'HTTP-Referer': 'https://noah-trading.app',
          'X-Title': 'NOAH AI Trading',
        },
      }));
      if (resp.statusCode != 200) {
        if (resp.statusCode == 402) {
          return '❌ Erreur 402 — Crédits insuffisants. Ajoute des fonds sur OpenRouter pour utiliser ce modèle.';
        }
        return '❌ Erreur API (${resp.statusCode}): ${resp.statusMessage}';
      }
      final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data as String) as Map;
      final choices = data['choices'] as List? ?? [];
      if (choices.isEmpty) return '⚠️ Réponse vide';
      final message = choices.first as Map;
      final content = (message['message'] as Map?)?['content'] as String?;
      return content ?? '⚠️ Réponse vide';
    } catch (e) {
      return '❌ Erreur de connexion: $e';
    }
  }

  void dispose() {
    _dio.close();
  }
}
