import 'dart:convert';
import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.114.160.25:8001',
    connectTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<bool> sendCode(String email, {String honeypot = ''}) async {
    try {
      final r = await _dio.post('/api/auth/send-code',
          data: {'email': email, 'honeypot': honeypot});
      return r.statusCode == 200 && r.data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyCode(String email, String code,
      {String honeypot = ''}) async {
    try {
      final r = await _dio.post('/api/auth/verify-code',
          data: {'email': email, 'code': code, 'honeypot': honeypot});
      if (r.statusCode == 200) return r.data as Map<String, dynamic>;
      return null;
    } catch (_) {
      return null;
    }
  }
}
