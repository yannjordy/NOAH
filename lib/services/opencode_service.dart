import 'dart:convert';
import 'package:dio/dio.dart';

class OpenCodeService {
  final Dio _dio;
  String? _sessionId;
  String baseUrl;
  String model;
  String? _username;
  String? _password;

  OpenCodeService({this.baseUrl = 'http://localhost:3000', this.model = 'opencode/mimo-v2.5-free'})
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 120),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (_) => true,
        ));

  void setAuth(String? username, String? password) {
    _username = username;
    _password = password;
  }

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_username != null && _password != null) {
      final auth = base64Encode(utf8.encode('$_username:$_password'));
      h['Authorization'] = 'Basic $auth';
    }
    return h;
  }

  Future<bool> healthCheck() async {
    // Try multiple endpoints to detect OpenCode server
    final endpoints = ['/global/health', '/health', '/config/providers', '/models', '/'];
    for (final endpoint in endpoints) {
      try {
        final resp = await _dio.get('$baseUrl$endpoint', options: Options(headers: _headers));
        if (resp.statusCode == 200 || resp.statusCode == 301 || resp.statusCode == 302) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<List<String>> listModels() async {
    try {
      // Try /config/providers first
      final resp = await _dio.get('$baseUrl/config/providers', options: Options(headers: _headers));
      if (resp.statusCode == 200) {
        final data = resp.data;
        final models = <String>[];
        if (data is Map) {
          // Format: {"providers": [{"models": [{"id": "..."}]}]}
          final providers = data['providers'] as List? ?? [];
          for (final p in providers) {
            if (p is Map) {
              final providerModels = p['models'] as List? ?? [];
              for (final m in providerModels) {
                if (m is Map) {
                  final id = m['id'] as String? ?? '';
                  if (id.isNotEmpty) models.add(id);
                }
              }
            }
          }
          // Also try {"models": [{"id": "..."}]} format
          if (models.isEmpty && data.containsKey('models')) {
            final modelList = data['models'] as List? ?? [];
            for (final m in modelList) {
              if (m is Map) {
                final id = m['id'] as String? ?? '';
                if (id.isNotEmpty) models.add(id);
              }
            }
          }
        }
        if (models.isNotEmpty) return models;
      }
    } catch (_) {}

    // Fallback: try /models endpoint
    try {
      final resp = await _dio.get('$baseUrl/models', options: Options(headers: _headers));
      if (resp.statusCode == 200) {
        final data = resp.data;
        final models = <String>[];
        if (data is List) {
          for (final m in data) {
            if (m is Map) {
              final id = m['id'] as String? ?? '';
              if (id.isNotEmpty) models.add(id);
            } else if (m is String && m.isNotEmpty) {
              models.add(m);
            }
          }
        } else if (data is Map && data.containsKey('models')) {
          final modelList = data['models'] as List? ?? [];
          for (final m in modelList) {
            if (m is Map) {
              final id = m['id'] as String? ?? '';
              if (id.isNotEmpty) models.add(id);
            }
          }
        }
        if (models.isNotEmpty) return models;
      }
    } catch (_) {}

    // Final fallback: return defaults
    return [
      'opencode/mimo-v2.5-free',
      'opencode/big-pickle',
      'opencode/deepseek-v4-flash-free',
      'opencode/gpt-5-nano',
      'opencode/nemotron-3-ultra-free',
      'opencode/north-mini-code-free',
      'opencode/qwen3.6-plus-free',
      'opencode/minimax-m2.5-free',
    ];
  }

  Future<String> _ensureSession() async {
    if (_sessionId != null) return _sessionId!;
    try {
      final resp = await _dio.post(
        '$baseUrl/session',
        data: {'title': 'NOAH Trading'},
        options: Options(headers: _headers),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data;
        if (data is Map && data['id'] != null) {
          _sessionId = data['id'] as String;
          return _sessionId!;
        }
        // Try to extract ID from different formats
        if (data is String && data.isNotEmpty) {
          _sessionId = data;
          return _sessionId!;
        }
      }
    } catch (_) {}
    _sessionId = 'default';
    return _sessionId!;
  }

  Future<String> sendMessage(String text, {String? systemContext, List<String>? images}) async {
    try {
      final sessionId = await _ensureSession();

      final parts = <Map<String, dynamic>>[];
      if (systemContext != null && systemContext.isNotEmpty) {
        parts.add({'type': 'text', 'text': '$systemContext\n\n$text'});
      } else {
        parts.add({'type': 'text', 'text': text});
      }
      if (images != null) {
        for (final img in images) {
          parts.add({'type': 'image_url', 'image_url': {'url': img.startsWith('http') ? img : 'data:image/jpeg;base64,$img'}});
        }
      }

      final body = <String, dynamic>{
        'parts': parts,
        'model': model,
      };

      final resp = await _dio.post(
        '$baseUrl/session/$sessionId/message',
        data: body,
        options: Options(headers: _headers, receiveTimeout: const Duration(seconds: 180)),
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map) {
          final responseParts = data['parts'] as List? ?? [];
          final textParts = responseParts
              .where((p) => p is Map && p['type'] == 'text')
              .map((p) => (p as Map)['text'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          if (textParts.isNotEmpty) return textParts.join('\n');
          final info = data['info'] as Map?;
          if (info != null && info['text'] != null) {
            return info['text'] as String;
          }
          // Try content field
          final content = data['content'];
          if (content is String && content.isNotEmpty) return content;
          if (content is List) {
            final texts = content.whereType<String>().where((t) => t.isNotEmpty).toList();
            if (texts.isNotEmpty) return texts.join('\n');
          }
        }
        // Response might be a string directly
        if (data is String && data.isNotEmpty) return data;
        return '⚠️ Réponse vide du serveur OpenCode';
      }

      if (resp.statusCode == 401) {
        return '❌ Authentification requise. Configurez le mot de passe OpenCode.';
      }

      return '❌ Erreur OpenCode (${resp.statusCode}): ${resp.statusMessage ?? "inconnue"}';
    } catch (e) {
      return '❌ Erreur de connexion OpenCode: $e';
    }
  }

  void resetSession() {
    _sessionId = null;
  }

  void dispose() {
    _dio.close();
  }
}
