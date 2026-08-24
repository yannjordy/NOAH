import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

class DeerFlowMessage {
  final String role; // 'user', 'assistant'
  final String content;

  DeerFlowMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class DeerFlowResponse {
  final String content;
  final String? threadId;
  final String? runId;

  DeerFlowResponse({required this.content, this.threadId, this.runId});
}

class DeerFlowService {
  final Dio _dio;
  String? _currentThreadId;

  DeerFlowService({String baseUrl = 'http://localhost:2026'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ));

  /// Check if the DeerFlow server is reachable.
  Future<bool> healthCheck() async {
    try {
      final resp = await _dio.get('/health');
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Send a message and get a response (blocking wait).
  Future<DeerFlowResponse> sendMessage(String content) async {
    try {
      // Create thread if needed
      if (_currentThreadId == null) {
        final threadResp = await _dio.post('/api/threads', data: {});
        if (threadResp.statusCode != 200 && threadResp.statusCode != 201) {
          return DeerFlowResponse(content: '❌ Erreur: impossible de créer un thread');
        }
        final threadData = threadResp.data is Map ? threadResp.data as Map : jsonDecode(threadResp.data as String) as Map;
        _currentThreadId = threadData['thread_id'] as String?;
      }

      // Send run and wait for result
      final runResp = await _dio.post(
        '/api/threads/$_currentThreadId/runs/wait',
        data: {
          'messages': [DeerFlowMessage(role: 'user', content: content).toJson()],
        },
      );

      if (runResp.statusCode != 200) {
        return DeerFlowResponse(content: '❌ Erreur API (${runResp.statusCode})');
      }

      final runData = runResp.data is Map ? runResp.data as Map : jsonDecode(runResp.data as String) as Map;
      final messages = runData['messages'] as List?;
      if (messages == null || messages.isEmpty) {
        return DeerFlowResponse(content: '⚠️ Aucune réponse reçue');
      }

      final last = messages.last as Map;
      final reply = last['content'] as String? ?? '';

      return DeerFlowResponse(
        content: reply,
        threadId: _currentThreadId,
        runId: runData['run_id'] as String?,
      );
    } catch (e) {
      return DeerFlowResponse(content: '❌ Erreur de connexion à DeerFlow: $e');
    }
  }

  /// Reset thread (start a new conversation).
  void resetThread() {
    _currentThreadId = null;
  }

  void dispose() {
    _dio.close();
  }
}
