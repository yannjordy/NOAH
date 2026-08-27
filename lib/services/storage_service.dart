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
      } catch (e) {
        // Log error but don't crash — data may be lost on restart
        // ignore: avoid_print
        print('[StorageService] _persist error: $e');
      }
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
    _persist();
  }

  bool getDemoMode() => _store[_demoKey] != 'false';
  void setDemoMode(bool v) {
    _store[_demoKey] = v.toString();
    _persist();
  }

  String? getLoggedEmail() => _store[_loggedKey];
  void setLoggedEmail(String? email) {
    if (email == null) {
      _store.remove(_loggedKey);
    } else {
      _store[_loggedKey] = email;
    }
    _persist();
  }

  Map<String, String> getConnectedModels() {
    final data = _store[_modelsKey];
    if (data == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(data));
    } catch (_) {
      return {};
    }
  }

  void saveConnectedModels(Map<String, String> models) {
    _store[_modelsKey] = jsonEncode(models);
    _persist();
  }

  bool getTermsAccepted() => _store[_termsKey] == 'true';
  void setTermsAccepted(bool v) {
    _store[_termsKey] = v.toString();
    _persist();
  }

  String? getBinanceApiKey() => _store[_binanceApiKey];
  String? getBinanceSecretKey() => _store[_binanceSecretKey];
  bool getBinanceTestnet() => _store[_binanceTestnetKey] == 'true';

  void saveBinanceCredentials(String apiKey, String secretKey, {bool testnet = false}) {
    _store[_binanceApiKey] = apiKey;
    _store[_binanceSecretKey] = secretKey;
    _store[_binanceTestnetKey] = testnet.toString();
    _persist();
  }

  void clearBinanceCredentials() {
    _store.remove(_binanceApiKey);
    _store.remove(_binanceSecretKey);
    _store.remove(_binanceTestnetKey);
    _persist();
  }

  String get _userSeed => getLoggedEmail() ?? 'default';

  void savePortfolio(PortfolioData data) {
    _store['noah_portfolio'] = jsonEncode(data.toJson());
    _persist();
  }

  PortfolioData loadPortfolio() {
    final data = _store['noah_portfolio'];
    if (data == null) return PortfolioData();
    try {
      return PortfolioData.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return PortfolioData();
    }
  }

  Map<String, dynamic> loadRisk() {
    final data = _store[_riskKey];
    if (data == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(data) as Map);
    } catch (_) {
      return {};
    }
  }

  void saveRisk(Map<String, dynamic> risk) {
    _store[_riskKey] = jsonEncode(risk);
    _persist();
  }

  Map<String, String> getApiKeys() {
    final data = _store[_apiKeysKey];
    if (data == null) return {};
    try {
      final decrypted = CryptoUtils.decrypt(data, userSeed: _userSeed);
      return Map<String, String>.from(jsonDecode(decrypted));
    } catch (_) {
      return {};
    }
  }

  void saveApiKeys(Map<String, String> keys) {
    final encrypted = CryptoUtils.encrypt(jsonEncode(keys), userSeed: _userSeed);
    _store[_apiKeysKey] = encrypted;
    _persist();
  }

  String getFont() => _store[_fontKey] ?? 'Inter';
  void setFont(String v) { _store[_fontKey] = v; _persist(); }
  bool getBold() => _store[_boldKey] == 'true';
  void setBold(bool v) { _store[_boldKey] = v.toString(); _persist(); }

  String getAgentMemory() => _store[_agentMemoryKey] ?? _defaultAgentMemory;
  void setAgentMemory(String v) { _store[_agentMemoryKey] = v; _persist(); }

  double getProfitThreshold() {
    final v = _store[_profitThresholdKey];
    if (v == null) return 0;
    return double.tryParse(v) ?? 0;
  }
  void setProfitThreshold(double v) { _store[_profitThresholdKey] = v.toString(); _persist(); }

  String? getAdminPassword() => _store[_adminPasswordKey];
  void setAdminPassword(String? password) {
    if (password == null || password.isEmpty) {
      _store.remove(_adminPasswordKey);
    } else {
      _store[_adminPasswordKey] = password;
    }
    _persist();
  }
  bool hasAdminPassword() => _store.containsKey(_adminPasswordKey) && _store[_adminPasswordKey]!.isNotEmpty;

  String getOpenCodeUrl() => _store[_opencodeUrlKey] ?? 'http://localhost:4096';
  void setOpenCodeUrl(String url) {
    _store[_opencodeUrlKey] = url;
    _persist();
  }

  String getProfileIcon() => _store[_profileIconKey] ?? 'icon-noire-admin.jpg';
  void setProfileIcon(String icon) {
    _store[_profileIconKey] = icon;
    _persist();
  }

  // ═══════════════════════════════════════════════════════
  //  TRADE JOURNAL (NOAH's learning memory)
  // ═══════════════════════════════════════════════════════
  String? getTradeJournal() => _store['noah_trade_journal'];
  void setTradeJournal(String v) { _store['noah_trade_journal'] = v; _persist(); }

  String? getEvolvedMemory() => _store['noah_evolved_memory'];
  void setEvolvedMemory(String v) { _store['noah_evolved_memory'] = v; _persist(); }

  String? getStrategyPerformance() => _store['noah_strategy_perf'];
  void setStrategyPerformance(String v) { _store['noah_strategy_perf'] = v; _persist(); }

  // ═══════════════════════════════════════════════════════
  //  SETTINGS — AI Config
  // ═══════════════════════════════════════════════════════
  String getDefaultModel() => _store['noah_default_model'] ?? 'DeepSeek';
  void setDefaultModel(String v) { _store['noah_default_model'] = v; _persist(); }

  String getResponseMode() => _store['noah_response_mode'] ?? 'Précis';
  void setResponseMode(String v) { _store['noah_response_mode'] = v; _persist(); }

  // ═══════════════════════════════════════════════════════
  //  SETTINGS — Notifications
  // ═══════════════════════════════════════════════════════
  bool getNotifyTrades() => _store['noah_notify_trades'] != 'false';
  void setNotifyTrades(bool v) { _store['noah_notify_trades'] = v.toString(); _persist(); }

  bool getNotifySignals() => _store['noah_notify_signals'] != 'false';
  void setNotifySignals(bool v) { _store['noah_notify_signals'] = v.toString(); _persist(); }

  bool getNotifyRisk() => _store['noah_notify_risk'] != 'false';
  void setNotifyRisk(bool v) { _store['noah_notify_risk'] = v.toString(); _persist(); }

  bool getNotifyVibrate() => _store['noah_notify_vibrate'] != 'false';
  void setNotifyVibrate(bool v) { _store['noah_notify_vibrate'] = v.toString(); _persist(); }

  bool getNotifySound() => _store['noah_notify_sound'] != 'false';
  void setNotifySound(bool v) { _store['noah_notify_sound'] = v.toString(); _persist(); }

  // ── Price Cache ──────────────────────────────────────────
  static const _pricesKey = 'noah_cached_prices';
  static const _pctsKey = 'noah_cached_pcts';
  static const _pricesTimestampKey = 'noah_prices_timestamp';

  void cachePrices() {
    try {
      _store[_pricesKey] = jsonEncode(prices.map((k, v) => MapEntry(k, v)));
      _store[_pctsKey] = jsonEncode(pcts.map((k, v) => MapEntry(k, v)));
      _store[_pricesTimestampKey] = DateTime.now().toIso8601String();
      _persist();
    } catch (_) {}
  }

  void loadCachedPrices() {
    try {
      final pricesData = _store[_pricesKey];
      if (pricesData != null) {
        final map = jsonDecode(pricesData) as Map<String, dynamic>;
        for (final e in map.entries) {
          prices[e.key] = (e.value as num).toDouble();
        }
      }
      final pctsData = _store[_pctsKey];
      if (pctsData != null) {
        final map = jsonDecode(pctsData) as Map<String, dynamic>;
        for (final e in map.entries) {
          pcts[e.key] = (e.value as num).toDouble();
        }
      }
    } catch (_) {}
  }

  DateTime? get pricesTimestamp {
    final ts = _store[_pricesTimestampKey];
    if (ts == null) return null;
    try { return DateTime.parse(ts); } catch (_) { return null; }
  }
}

const _fontKey = 'noah_font';
const _profitThresholdKey = 'noah_profit_threshold';
const _boldKey = 'noah_bold';
const _agentMemoryKey = 'noah_agent_memory';

const _defaultAgentMemory = '''TECHNIQUES DE TRADING ENREGISTRÉES :

1. SUIVI DE TENDANCE (Trend Following)
   - Entrer dans la direction de la tendance (SMA5 > SMA20 = hausse)
   - Ajouter en position gagnante, ne pas moyenne à la baisse
   - Sortir quand la tendance casse (SMA5 croise SMA20 à la baisse)

2. RSI (Momentum)
   - RSI < 30 = survendu → potentiel rebuy (acheter)
   - RSI > 70 = surachat → potentiel retournement (vendre)
   - RSI 30-70 = zone neutre, attendre confirmation

3. GESTION DE RISQUE
   - Stop loss à 3-5% en dessous de l'entrée
   - Take profit à 8-15% pour garder un ratio R/R > 2
   - Ne jamais risquer plus de 2% du portefeuille sur un trade
   - Positions size = 10-20% maximum par symbole
   - Sortir 50% à l'objectif, laisser courir le reste

4. VOLUME
   - Volume croissant confirme le mouvement
   - Volume faible = signal faible, ignorer
   - Volume > 1.5x moyenne = mouvement fort

5. DIVERSIFICATION
   - Ne pas concentrer plus de 30% sur un seul trade
   - Répartir sur 3-5 symboles maximum
   - Pas plus de 2 trades par jour

6. MARCHÉS FAVORIS
   - BTC, ETH, SOL pour les moves stables
   - Altcoins pour les opportunités à fort momentum
   - Éviter les coins avec < 50M de volume

7. RÈGLES D'OR
   - Ne pas trader par ennui
   - Attendre la confirmation (2 indicateurs alignés minimum)
   - Couper les pertes vite, laisser courir les gains
   - En mode démo: tester les nouvelles stratégies
   - En mode réel: rester conservateur''';
