import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  SharedPreferences? _prefs;
  final Map<String, String> _store = {};

  static const _prefix = 'noah_';
  static const _sessionsKey = '${_prefix}sessions';
  static const _usersKey = '${_prefix}users';
  static const _loggedEmailKey = '${_prefix}logged_email';
  static const _darkKey = '${_prefix}dark';
  static const _demoKey = '${_prefix}demo';
  static const _adminKey = '${_prefix}admin';
  static const _fontKey = '${_prefix}font';
  static const _boldKey = '${_prefix}bold';
  static const _profileIconKey = '${_prefix}icon';
  static const _termsKey = '${_prefix}terms';
  static const _defaultModelKey = '${_prefix}default_model';
  static const _responseModeKey = '${_prefix}response_mode';
  static const _profitThresholdKey = '${_prefix}profit_threshold';
  static const _opencodeUrlKey = '${_prefix}opencode_url';
  static const _binanceApiKey = '${_prefix}binance_api';
  static const _binanceSecretKey = '${_prefix}binance_secret';
  static const _binanceTestnet = '${_prefix}binance_testnet';
  static const _connectedModelsKey = '${_prefix}connected_models';
  static const _agentMemoryKey = '${_prefix}agent_memory';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final key in _prefs!.getKeys()) {
      _store[key] = _prefs!.getString(key) ?? '';
    }
  }

  void _persist() {
    for (final entry in _store.entries) {
      _prefs?.setString(entry.key, entry.value);
    }
  }

  String _get(String key, [String def = '']) => _store[key] ?? def;
  void _set(String key, String value) {
    _store[key] = value;
    _persist();
  }

  // Sessions
  List<ChatSession> getSessions() {
    final data = _get(_sessionsKey);
    if (data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveSessions(List<ChatSession> sessions) {
    final data = jsonEncode(sessions.map((s) => s.toJson()).toList());
    _set(_sessionsKey, data);
  }

  // Users
  List<UserAccount> getUsers() {
    final data = _get(_usersKey);
    if (data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => UserAccount.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveUsers(List<UserAccount> users) {
    final data = jsonEncode(users.map((u) => u.toJson()).toList());
    _set(_usersKey, data);
  }

  // Auth
  String? getLoggedEmail() {
    final email = _get(_loggedEmailKey);
    return email.isEmpty ? null : email;
  }

  void setLoggedEmail(String? email) => _set(_loggedEmailKey, email ?? '');

  // Admin password
  bool hasAdminPassword() => _store.containsKey(_adminKey);
  String getAdminPassword() => _get(_adminKey, '1234');
  void setAdminPassword(String v) => _set(_adminKey, v);

  // Settings
  bool getDarkMode() => _get(_darkKey) == 'true';
  void setDarkMode(bool v) => _set(_darkKey, v.toString());

  bool getDemoMode() => _get(_demoKey, 'true') == 'true';
  void setDemoMode(bool v) => _set(_demoKey, v.toString());

  String getFont() => _get(_fontKey, 'JetBrains Mono');
  void setFont(String v) => _set(_fontKey, v);

  bool getBold() => _get(_boldKey) == 'true';
  void setBold(bool v) => _set(_boldKey, v.toString());

  String getProfileIcon() => _get(_profileIconKey, '');
  void setProfileIcon(String v) => _set(_profileIconKey, v);

  bool getTermsAccepted() => _get(_termsKey) == 'true';
  void setTermsAccepted(bool v) => _set(_termsKey, v.toString());

  double getProfitThreshold() => double.tryParse(_get(_profitThresholdKey, '0')) ?? 0;
  void setProfitThreshold(double v) => _set(_profitThresholdKey, v.toString());

  String getOpenCodeUrl() => _get(_opencodeUrlKey, 'http://localhost:3000');
  void setOpenCodeUrl(String v) => _set(_opencodeUrlKey, v);

  // Binance
  String getBinanceApiKey() => _get(_binanceApiKey);
  String getBinanceSecretKey() => _get(_binanceSecretKey);
  bool getBinanceTestnet() => _get(_binanceTestnet) == 'true';

  void saveBinanceCredentials(String apiKey, String secret, bool testnet) {
    _set(_binanceApiKey, apiKey);
    _set(_binanceSecretKey, secret);
    _set(_binanceTestnet, testnet.toString());
  }

  void clearBinanceCredentials() {
    _store.remove(_binanceApiKey);
    _store.remove(_binanceSecretKey);
    _store.remove(_binanceTestnet);
    _persist();
  }

  // Connected models
  Map<String, String> getConnectedModels() {
    final data = _get(_connectedModelsKey);
    if (data.isEmpty) return {};
    try {
      return Map<String, String>.from(jsonDecode(data));
    } catch (_) {
      return {};
    }
  }

  void saveConnectedModels(Map<String, String> models) {
    _set(_connectedModelsKey, jsonEncode(models));
  }

  // Agent memory
  String getAgentMemory(String agent) => _get('$_agentMemoryKey$agent');
  void setAgentMemory(String agent, String data) => _set('$_agentMemoryKey$agent', data);
}
