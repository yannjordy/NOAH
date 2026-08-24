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
      final cred = base64Encode(utf8.encode('$_username:$_password'));
      h['Authorization'] = 'Basic $cred';
    }
    return h;
  }

  Future<bool> healthCheck() async {
    try {
      final res = await _dio.get('$baseUrl/health', options: Options(headers: _headers));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> listModels() async {
    try {
      final res = await _dio.get('$baseUrl/models', options: Options(headers: _headers));
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((m) => m.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String> sendMessage(String prompt, {String? systemContext}) async {
    final messages = <Map<String, String>>[];

    if (systemContext != null && systemContext.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemContext});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = {
      'model': model,
      'messages': messages,
      'stream': false,
    };

    if (_sessionId != null) {
      body['session_id'] = _sessionId;
    }

    try {
      final res = await _dio.post(
        '$baseUrl/chat/completions',
        data: jsonEncode(body),
        options: Options(headers: _headers),
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        if (data is Map) {
          if (data.containsKey('session_id')) {
            _sessionId = data['session_id'];
          }
          if (data.containsKey('choices') && data['choices'] is List) {
            final choices = data['choices'] as List;
            if (choices.isNotEmpty) {
              final content = choices[0]['message']?['content'];
              if (content != null) return content.toString();
            }
          }
          if (data.containsKey('reply')) {
            return data['reply'].toString();
          }
        }
      }
      return 'Erreur: réponse invalide du serveur OpenCode';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Erreur: timeout de connexion vers OpenCode';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Erreur: impossible de joindre OpenCode ($baseUrl)';
      }
      return 'Erreur: ${e.message}';
    } catch (e) {
      return 'Erreur: ${e.toString()}';
    }
  }
}
