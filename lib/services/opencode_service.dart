import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class OpenCodeService {
  final Dio _dio;
  String? _sessionId;
  String baseUrl;
  String model;
  String? _username;
  String? _password;
  bool _connected = false;

  static const int defaultPort = 4096;

  bool get isConnected => _connected;

  OpenCodeService({this.baseUrl = 'http://localhost:4096', this.model = 'google/gemma-4-31b-it:free'})
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

  static Future<String?> autoDetect() async {
    final candidates = <String>[
      'http://127.0.0.1:$defaultPort',
      'http://10.0.2.2:$defaultPort',
    ];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            final url = 'http://${addr.address}:$defaultPort';
            if (!candidates.contains(url)) candidates.add(url);
          }
        }
      }
    } catch (_) {}

    for (final url in candidates) {
      try {
        final service = OpenCodeService(baseUrl: url);
        final ok = await service.healthCheck();
        service.dispose();
        if (ok) return url;
      } catch (_) {}
    }
    return null;
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
    final endpoints = ['/global/health', '/health', '/config/providers', '/models', '/'];
    for (final endpoint in endpoints) {
      try {
        final resp = await _dio.get('$baseUrl$endpoint', options: Options(headers: _headers));
        if (resp.statusCode == 200 || resp.statusCode == 301 || resp.statusCode == 302) {
          _connected = true;
          return true;
        }
      } catch (_) {}
    }
    _connected = false;
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
      'google/gemma-4-31b-it:free',
      'nvidia/nemotron-3-ultra-550b-a55b:free',
      'nvidia/nemotron-nano-9b-v2:free',
      'google/gemma-4-26b-a4b-it:free',
      'nvidia/nemotron-3-nano-30b-a3b:free',
      'poolside/laguna-s-2.1:free',
      'cohere/north-mini-code:free',
      'nvidia/nemotron-3.5-lightning:free',
    ];
  }

  Future<String> _ensureSession() async {
    if (_sessionId != null && _sessionId != 'default') return _sessionId!;
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
        // Try nested info object
        if (data is Map && data['info'] is Map) {
          final info = data['info'] as Map;
          if (info['id'] != null) {
            _sessionId = info['id'] as String;
            return _sessionId!;
          }
        }
      }
    } catch (e) {
      // Session creation failed, will retry on next call
    }
    _sessionId = 'default';
    return _sessionId!;
  }

  Future<String> sendMessage(String text, {String? systemContext, List<String>? images}) async {
    try {
      final sessionId = await _ensureSession();

      final parts = <Map<String, dynamic>>[];
      parts.add({'type': 'text', 'text': text});
      if (images != null) {
        for (final img in images) {
          parts.add({'type': 'image_url', 'image_url': {'url': img.startsWith('http') ? img : 'data:image/jpeg;base64,$img'}});
        }
      }

      final body = <String, dynamic>{
        'parts': parts,
        'model': {
          'id': model,
          'providerID': 'openrouter',
          'modelID': model,
        },
      };
      if (systemContext != null && systemContext.isNotEmpty) {
        body['system'] = systemContext;
      }

      final resp = await _dio.post(
        '$baseUrl/session/$sessionId/message',
        data: body,
        options: Options(headers: _headers, receiveTimeout: const Duration(seconds: 300)),
      );

      if (resp.statusCode == 200) {
        final data = resp.data;

        // Handle Map response (expected format: { info: Message, parts: Part[] })
        if (data is Map) {
          // Try to get text from parts array
          final responseParts = data['parts'] as List? ?? [];
          final textParts = responseParts
              .where((p) => p is Map && p['type'] == 'text')
              .map((p) => (p as Map)['text'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          if (textParts.isNotEmpty) return textParts.join('\n');

          // Try info.text field
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

          // Try message field
          final message = data['message'];
          if (message is String && message.isNotEmpty) return message;
          if (message is Map && message['text'] != null) {
            return message['text'] as String;
          }
        }

        // Response might be a string directly
        if (data is String && data.isNotEmpty) return data;

        return '⚠️ Réponse vide du serveur OpenCode';
      }

      if (resp.statusCode == 401) {
        return '❌ Authentification requise. Configurez le mot de passe OpenCode.';
      }

      if (resp.statusCode == 404) {
        // Session might be invalid, reset and retry once
        _sessionId = null;
        return '⏳ Session réinitialisée, réessayez...';
      }

      return '❌ Erreur OpenCode (${resp.statusCode}): ${resp.statusMessage ?? "inconnue"}';
    } catch (e) {
      return '❌ Erreur de connexion OpenCode: $e';
    }
  }

  void resetSession() {
    _sessionId = null;
  }

  /// Force creation of a new session on next message
  void newSession() {
    _sessionId = null;
  }

  void dispose() {
    _dio.close();
  }
}
