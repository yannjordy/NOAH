import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';
import 'crypto_utils.dart';

class StorageService {
  static const _usersKey = 'noah_users';
  static const _sessionsKey = 'noah_sessions';
  static const _darkKey = 'noah_dark';
  static const _demoKey = 'noah_demo';
  static const _loggedKey = 'noah_logged';
  static const _modelsKey = 'noah_connected_models';
  static const _apiKeysKey = 'noah_api_keys';
  static const _termsKey = 'noah_terms_accepted';
  static const _binanceApiKey = 'noah_binance_api';
  static const _binanceSecretKey = 'noah_binance_secret';
  static const _binanceTestnetKey = 'noah_binance_testnet';
  static const _riskKey = 'noah_risk';
  static const _adminPasswordKey = 'noah_admin_password';
  static const _opencodeUrlKey = 'noah_opencode_url';
  static const _profileIconKey = 'noah_profile_icon';

  Map<String, String> _store = {};

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/noah_store.json');
        if (await file.exists()) {
          final data = await file.readAsString();
          _store = Map<String, String>.from(jsonDecode(data));
        }
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/noah_store.json');
        await file.writeAsString(jsonEncode(_store));
      } catch (_) {}
    }
  }

  List<UserAccount> getUsers() {
    final data = _store[_usersKey];
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => UserAccount.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveUsers(List<UserAccount> users) {
    final data = jsonEncode(users.map((u) => u.toJson()).toList());
    _store[_usersKey] = data;
    _persist();
  }

  List<ChatSession> getSessions() {
    final data = _store[_sessionsKey];
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveSessions(List<ChatSession> sessions) {
    final data = jsonEncode(sessions.map((s) => s.toJson()).toList());
    _store[_sessionsKey] = data;
    _persist();
  }

  bool getDarkMode() => _store[_darkKey] == 'true';
  void setDarkMode(bool v) {
    _store[_darkKey] = v.toString();
    _pers