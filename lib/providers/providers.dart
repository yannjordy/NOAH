import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/deerflow_service.dart';
import '../services/trading_api_service.dart';
import '../services/llm_service.dart';
import '../services/opencode_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/ai_tools.dart';
import '../services/market_service.dart';
import '../services/binance_service.dart';
import '../agents/agents.dart' hide fmt;
import '../agents/risk_manager.dart';

const _uuid = Uuid();

// ─── Auth Provider ───────────────────────────────────
class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  SupabaseService? _supabase;
  bool _isLoggedIn = false;
  UserAccount? _currentUser;
  bool _banned = false;
  bool _needsUpdate = false;

  static const String appVersion = '1.0.0';

  AuthProvider(this._storage) {
    _restore();
  }

  void setSupabase(SupabaseService s) => _supabase = s;

  bool get isLoggedIn => _isLoggedIn;
  UserAccount? get currentUser => _currentUser;
  bool get banned => _banned;
  bool get needsUpdate => _needsUpdate;

  void bypassUpdate() {
    _needsUpdate = false;
    notifyListeners();
  }

  Future<void> checkBanStatus() async {
    final sb = _supabase;
    final u = _currentUser;
    if (sb == null || u == null) return;
    final banned = await sb.isBanned(u.email);
    if (banned != _banned) {
      _banned = banned;
      notifyListeners();
    }
  }

  Future<void> checkAppVersion() async {
    final sb = _supabase;
    if (sb == null) return;
    final minVersion = await sb.getMinVersion();
    if (minVersion != null && _compareVersion(appVersion, minVersion) < 0) {
      _needsUpdate = true;
      notifyListeners();
    }
  }

  int _compareVersion(String a, String b) {
    final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (int i = 0; i < len; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  void _restore() {
    // Set default admin password if none exists
    if (!_storage.hasAdminPassword()) {
      _storage.setAdminPassword('1234');
    }
    final email = _storage.getLoggedEmail();
    if (email != null) {
      final users = _storage.getUsers();
      final user = users.where((u) => u.email == email).firstOrNull;
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        notifyListeners();
      }
    }
  }

  String get displayName => _currentUser?.name ?? (_isLoggedIn ? 'Utilisateur' : 'Invité');
  String get displayEmail => _currentUser?.email ?? 'Non connecté';

  Future<bool> loginWithEmail(SupabaseService supabase, String email, String password) async {
    try {
      await supabase.signInWithPassword(email, password);
      finalizeLogin(supabase);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerWithEmail(SupabaseService supabase, String email, String password, String name) async {
    try {
      final hasSession = await supabase.signUp(email, password, name);
      if (hasSession) {
        finalizeLogin(supabase);
        return true;
      }
      // Supabase requires email confirmation — create local account as fallback
      _currentUser = UserAccount(email: email, password: '', name: name);
      _isLoggedIn = true;
      _storage.setLoggedEmail(email);
      final users = _storage.getUsers();
      users.add(_currentUser!);
      _storage.saveUsers(users);
      notifyListeners();
      return true;
    } catch (_) {
      // Fallback: create local account
      _currentUser = UserAccount(email: email, password: '', name: name);
      _isLoggedIn = true;
      _storage.setLoggedEmail(email);
      final users = _storage.getUsers();
      users.add(_currentUser!);
      _storage.saveUsers(users);
      notifyListeners();
      return true;
    }
  }

  Future<bool> loginWithForgotPassword(SupabaseService supabase, String email) async {
    try {
      await supabase.sendOtp(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyForgotPasswordOtp(SupabaseService supabase, String email, String code) async {
    try {
      await supabase.verifyOtp(email, code);
      finalizeLogin(supabase);
      return true;
    } catch (_) {
      return false;
    }
  }

  void finalizeLogin(SupabaseService supabase) {
    final email = supabase.userEmail;
    if (email == null) return;
    final users = _storage.getUsers();
    final existing = users.where((u) => u.email == email).firstOrNull;
    if (existing != null) {
      _currentUser = existing;
    } else {
      final newUser = UserAccount(email: email, password: '', name: email.split('@').first);
      users.add(newUser);
      _storage.saveUsers(users);
      _currentUser = newUser;
    }
    _isLoggedIn = true;
    _storage.setLoggedEmail(email);
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _storage.setLoggedEmail(null);
    notifyListeners();
  }

  bool hasAdminPassword() => _storage.hasAdminPassword();

  Future<bool> setupAdminPassword(String password) async {
    try {
      _storage.setAdminPassword(password);
      _currentUser = UserAccount(email: 'admin@noah.local', password: '', name: 'Admin');
      _isLoggedIn = true;
      _storage.setLoggedEmail('admin@noah.local');
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithAdminPassword(String password) async {
    final storedPassword = _storage.getAdminPassword();
    if (storedPassword == null || storedPassword != password) {
      return false;
    }
    _currentUser = UserAccount(email: 'admin@noah.local', password: '', name: 'Admin');
    _isLoggedIn = true;
    _storage.setLoggedEmail('admin@noah.local');
    notifyListeners();
    return true;
  }

  Future<bool> loginWithBiometrics() async {
    try {
      final localAuth = LocalAuthentication();
      final isAvailable = await localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Authentifiez-vous en tant qu\'admin',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (didAuthenticate) {
        _currentUser = UserAccount(email: 'admin@noah.local', password: '', name: 'Admin');
        _isLoggedIn = true;
        _storage.setLoggedEmail('admin@noah.local');
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final localAuth = LocalAuthentication();
      return await localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }
}

// ─── Settings Provider ───────────────────────────────
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  bool _isDark = false;
  bool _isDemo = true;
  bool _termsAccepted = false;
  bool _notifyTrades = false;
  bool _notifySignals = true;
  bool _notifyRisk = true;
  bool _notifyVibrate = true;
  bool _notifySound = true;
  String _defaultModel = 'DeepSeek';
  String _responseMode = 'Précis (recommandé)';
  String _fontFamily = 'Inter';
  bool _useBold = false;
  double _profitOnlyThreshold = 0;
  String _profileIcon = 'assets/icons/icon-noire-admin.jpg';

  // Ensure profile icon path always includes 'assets/icons/' prefix
  String _normalizeIconPath(String icon) {
    if (icon.startsWith('assets/icons/')) return icon;
    return 'assets/icons/$icon';
  }

  SettingsProvider(this._storage) {
    _isDark = _storage.getDarkMode();
    _isDemo = _storage.getDemoMode();
    _termsAccepted = _storage.getTermsAccepted();
    _fontFamily = _storage.getFont();
    if (!_validFonts.contains(_fontFamily)) _fontFamily = 'Inter';
    _useBold = _storage.getBold();
    _profitOnlyThreshold = _storage.getProfitThreshold();
    _profileIcon = _normalizeIconPath(_storage.getProfileIcon());
  }

  static const _validFonts = ['Inter', 'PlayfairDisplay', 'JetBrainsMono'];

  bool get isDark => _isDark;
  bool get isDemo => _isDemo;
  bool get hasAcceptedTerms => _termsAccepted;
  bool get notifyTrades => _notifyTrades;
  bool get notifySignals => _notifySignals;
  bool get notifyRisk => _notifyRisk;
  bool get notifyVibrate => _notifyVibrate;
  bool get notifySound => _notifySound;
  String get defaultModel => _defaultModel;
  String get responseMode => _responseMode;
  String get fontFamily => _fontFamily;
  bool get useBold => _useBold;
  double get profitOnlyThreshold => _profitOnlyThreshold;
  String get profileIcon => _profileIcon;

  void acceptTerms() {
    _termsAccepted = true;
    _storage.setTermsAccepted(true);
    notifyListeners();
  }

  void toggleDark() {
    _isDark = !_isDark;
    _storage.setDarkMode(_isDark);
    notifyListeners();
  }

  void toggleMode() {
    _isDemo = !_isDemo;
    _storage.setDemoMode(_isDemo);
    notifyListeners();
  }

  void setNotifyTrades(bool v) {
    _notifyTrades = v;
    NotificationService.suppressTradeNotifications = !v;
    notifyListeners();
  }
  void setNotifySignals(bool v) { _notifySignals = v; notifyListeners(); }
  void setNotifyRisk(bool v) { _notifyRisk = v; notifyListeners(); }
  void setNotifyVibrate(bool v) { _notifyVibrate = v; notifyListeners(); }
  void setNotifySound(bool v) { _notifySound = v; notifyListeners(); }
  void setProfitThreshold(double v) { _profitOnlyThreshold = v; _storage.setProfitThreshold(v); notifyListeners(); }
  void setDefaultModel(String v) { _defaultModel = v; notifyListeners(); }
  void setResponseMode(String v) { _responseMode = v; notifyListeners(); }
  void setFontFamily(String v) { _fontFamily = v; _storage.setFont(v); notifyListeners(); }
  void setUseBold(bool v) { _useBold = v; _storage.setBold(v); notifyListeners(); }
  void setProfileIcon(String icon) { _profileIcon = _normalizeIconPath(icon); _storage.setProfileIcon(icon); notifyListeners(); }
}

// ─── Chat Provider ───────────────────────────────────
typedef AgentContextBuilder = AgentContext Function();

class ChatProvider extends ChangeNotifier {
  final StorageService _storage;
  final AuthProvider _auth;
  final AgentContextBuilder _buildContext;
  final MainAgent _mainAgent = MainAgent();
  List<ChatMessage> _messages = [];
  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  bool _isTyping = false;
  bool _generationCancelled = false;
  bool _welcomeVisible = true;
  bool _aiRunning = false;
  bool _tradingEnabled = false;
  bool _pendingTradingRequest = false;
  String _lastTradingAction = '';

  PortfolioProvider? _portfolio;
  RiskProvider? _risk;

  // Connected models: provider name -> model name
  Map<String, String> _connectedModels = {};
  String _currentModel = 'noah-agent';
  final BinanceService _binance;
  bool _binanceWorking = false;
  final DeerFlowService _deerFlow;
  final TradingApiService _tradingApi;
  final LlmService _llm;
  final OpenCodeService _openCode;

  OpenCodeService get openCode => _openCode;

  // Provider base URLs for OpenAI-compatible APIs
  static const Map<String, String> providerBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'DeepSeek': 'https://api.deepseek.com/v1',
    'DeepSeek Flash': 'https://api.deepseek.com/v1',
    'Anthropic Claude': 'https://api.anthropic.com/v1',
    'Google Gemini': 'https://generativelanguage.googleapis.com/v1beta',
    'Meta LLaMA': 'https://api.meta.ai/v1',
    'Mistral AI': 'https://api.mistral.ai/v1',
    'xAI Grok': 'https://api.x.ai/v1',
    'Perplexity': 'https://api.perplexity.ai',
    'Cohere': 'https://api.cohere.ai/v1',
    'AI21 Labs': 'https://api.ai21.com/v1',
    'Groq': 'https://api.groq.com/openai/v1',
    'Together AI': 'https://api.together.xyz/v1',
    'Fireworks AI': 'https://api.fireworks.ai/inference/v1',
    'Replicate': 'https://api.replicate.com/v1',
    'OpenRouter': 'https://openrouter.ai/api/v1',
    'Lepton AI': 'https://api.lepton.ai/v1',
    'Novita AI': 'https://api.novita.ai/v1',
    'Hugging Face': 'https://api-inference.huggingface.co/v1',
    'OpenCode Local': 'http://localhost:3000',
  };

  ChatProvider(this._storage, this._auth, {AgentContextBuilder? buildContext})
      : _buildContext = buildContext ?? (() => AgentContext(
            prices: prices,
            pcts: pcts,
            klines: {},
            bids: {},
            asks: {},
            usdtBalance: 10000,
            positions: [],
            history: [],
          )),
        _deerFlow = DeerFlowService(),
        _tradingApi = TradingApiService(),
        _llm = LlmService(),
        _openCode = OpenCodeService(baseUrl: _storage.getOpenCodeUrl()),
        _binance = BinanceService() {
    _connectedModels = _storage.getConnectedModels();
    if (!_connectedModels.containsKey('NOAH Trading Core')) {
      _connectedModels['NOAH Trading Core'] = 'trading-core';
    }
    _restoreBinance();
    // Set OpenCode as the brain for the main trading agent
    _mainAgent.setBrain((prompt, {String? systemContext}) {
      return _openCode.sendMessage(prompt, systemContext: systemContext);
    });
    initBackgroundAgents();
  }

  void initBackgroundAgents() {
    Future(() => _refreshBackground());
    Timer.periodic(const Duration(minutes: 5), (_) => _refreshBackground());
  }

  Future<void> _refreshBackground() async {
    final symbols = prices.keys.toList();
    if (symbols.isEmpty) return;

    final emilienne = MacroResearchAgent(thinker: _aiThinker());
    final junior = BacktestAgent(thinker: _aiThinker());
    final optimizer = OptimizerAgent();
    final clients = <Future>[];

    for (final sym in symbols.take(5)) {
      clients.add(emilienne.refresh(sym));
      final ctx = _buildContext();
      final klines = ctx.klines[sym];
      if (klines != null && klines.length >= 30) {
        clients.add(junior.compute(sym, klines));
      }
      if (klines != null && klines.length >= 100) {
        clients.add(optimizer.optimize(sym, klines));
      }
    }

    await Future.wait(clients);
  }

  void _restoreBinance() {
    final apiKey = _storage.getBinanceApiKey();
    final secretKey = _storage.getBinanceSecretKey();
    if (apiKey != null && secretKey != null) {
      final testnet = _storage.getBinanceTestnet();
      _binance.configure(apiKey, secretKey, testnet: testnet);
      _connectedModels['Binance API'] = 'binance';
      _storage.saveConnectedModels(_connectedModels);
    }
  }

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get welcomeVisible => _welcomeVisible;

  void cancelResponse() {
    _generationCancelled = true;
    _messages.removeWhere((m) => m.isTyping);
    _isTyping = false;
    _pendingTradingRequest = false;
    notifyListeners();
  }

  String get currentSessionId => _currentSessionId;
  Map<String, String> get connectedModels => Map.unmodifiable(_connectedModels);
  String get currentModel => _currentModel;

  String getSavedApiKey(String providerName) => _storage.getApiKeys()[providerName] ?? '';

  void updateOpenCodeUrl(String url) {
    _openCode.baseUrl = url;
    _storage.setOpenCodeUrl(url);
  }

  String getSavedOpenCodeUrl() => _storage.getOpenCodeUrl();

  Future<bool> testOpenCodeConnection() async {
    try {
      final ok = await _openCode.healthCheck();
      notifyListeners();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> fetchOpenCodeModels() async {
    try {
      final models = await _openCode.listModels();
      notifyListeners();
      return models;
    } catch (_) {
      return [];
    }
  }

  void connectModel(String providerName, String model, {String apiKey = '', String secretKey = ''}) {
    _connectedModels[providerName] = model;
    _storage.saveConnectedModels(_connectedModels);
    if (providerName == 'Binance API') {
      if (apiKey.isNotEmpty && secretKey.isNotEmpty) {
        _binance.configure(apiKey, secretKey);
        _storage.saveBinanceCredentials(apiKey, secretKey);
        _binanceWorking = false;
      }
    } else if (providerName == 'OpenCode Local') {
      final keys = Map<String, String>.from(_storage.getApiKeys());
      if (apiKey.isNotEmpty) keys[providerName] = apiKey;
      _storage.saveApiKeys(keys);
      _openCode.baseUrl = _storage.getOpenCodeUrl();
      _openCode.model = model;
      if (apiKey.isNotEmpty) {
        final parts = apiKey.split(':');
        _openCode.setAuth(parts.length > 1 ? parts[0] : null, parts.length > 1 ? parts[1] : apiKey);
      }
    } else if (providerBaseUrls.containsKey(providerName)) {
      final keys = Map<String, String>.from(_storage.getApiKeys());
      if (apiKey.isNotEmpty) keys[providerName] = apiKey;
      _storage.saveApiKeys(keys);
      final baseUrl = providerBaseUrls[providerName]!;
      _llm.updateConfig(baseUrl: baseUrl, apiKey: apiKey.isNotEmpty ? apiKey : (keys[providerName] ?? ''), model: model);
    }
    _currentModel = model;
    notifyListeners();
  }

  BinanceService get binance => _binance;
  bool get binanceConnected => _binance.isConnected;
  bool get binanceWorking => _binanceWorking;

  Future<bool> testBinanceConnection() async {
    _binanceWorking = await _binance.testConnection();
    notifyListeners();
    return _binanceWorking;
  }

  void disconnectModel(String providerName) {
    _connectedModels.remove(providerName);
    _storage.saveConnectedModels(_connectedModels);
    if (providerName == 'Binance API') {
      _binance.disconnect();
      _storage.clearBinanceCredentials();
      _binanceWorking = false;
    } else if (_connectedModels.isNotEmpty) {
      _currentModel = _connectedModels.values.first;
    } else {
      _currentModel = 'deepseek-chat-free';
    }
    notifyListeners();
  }

  void setCurrentModel(String model) {
    _currentModel = model;
    // If this is a known LLM provider, pre-configure the LLM service
    for (final entry in _connectedModels.entries) {
      if (entry.value == model && providerBaseUrls.containsKey(entry.key)) {
        final keys = _storage.getApiKeys();
        final apiKey = keys[entry.key] ?? '';
        final baseUrl = providerBaseUrls[entry.key] ?? 'https://api.openai.com/v1';
        _llm.updateConfig(baseUrl: baseUrl, apiKey: apiKey, model: model);
        break;
      }
    }
    notifyListeners();
  }

  List<String> get availableModels => _connectedModels.values.toList();

  void hideWelcome() {
    _welcomeVisible = false;
    notifyListeners();
  }

  PortfolioProvider? get portfolio => _portfolio;

  void attachProviders(PortfolioProvider portfolio, RiskProvider risk, MarketService market) {
    _portfolio = portfolio;
    _risk = risk;
  }

  bool get aiRunning => _aiRunning;
  void setAiRunning(bool v) { _aiRunning = v; notifyListeners(); }

  bool get tradingEnabled => _tradingEnabled;
  bool get pendingTradingRequest => _pendingTradingRequest;
  String get lastTradingAction => _lastTradingAction;

  void setTradingEnabled(bool v) {
    _tradingEnabled = v;
    _pendingTradingRequest = false;
    _lastTradingAction = v ? '✅ Trading IA activé' : '🔒 Trading IA désactivé';
    _aiRunning = v;
    if (_messages.isNotEmpty) {
      for (var i = 0; i < _messages.length; i++) {
        if (_messages[i].blocks.any((b) => b.type == BlockType.tradingToggle)) {
          final msg = _messages[i];
          final newBlocks = msg.blocks.map((b) =>
            b.type == BlockType.tradingToggle
                ? MessageBlock.tradingToggle(isActive: v)
                : b).toList();
          _messages[i] = msg.copyWith(blocks: newBlocks);
        }
      }
    }
    notifyListeners();
    if (v) {
      NotificationService.init();
      NotificationService.onTradingEnabled();
    } else {
      NotificationService.onTradingDisabled();
    }
  }

  void requestTradingAccess() {
    _pendingTradingRequest = true;
    notifyListeners();
  }

  void cancelTradingRequest() {
    _pendingTradingRequest = false;
    notifyListeners();
  }

  AiThinker _aiThinker() {
    return (String prompt, {String? systemContext}) {
      if (_currentModel.startsWith('opencode/')) {
        return _openCode.sendMessage(prompt, systemContext: systemContext);
      }
      return _llm.sendMessage(prompt, systemContext: systemContext);
    };
  }

  /// Ask the configured AI model for a trading decision on a symbol.
  /// Returns null when using the built-in agent system ('noah-agent').
  Future<Map<String, dynamic>?> getAiTradingDecision(String symbol, AgentContext ctx) async {
    if (_currentModel == 'noah-agent') return null;

    final marketAgent = MarketAgent();
    final riskAgent = RiskAgent();
    final portfolioAgent = PortfolioAgent();
    final tradingAgent = TradingAgent();
    final macroAgent = MacroResearchAgent(thinker: _currentModel == 'noah-agent' ? null : _aiThinker());
    final backtestAgent = BacktestAgent(thinker: _currentModel == 'noah-agent' ? null : _aiThinker());
    final jordyAgent = JordyAgent();
    final regimeAgent = RegimeAgent();
    final onchainAgent = OnchainAgent();
    final liquidityAgent = LiquidityAgent();
    final attributionAgent = AttributionAgent();

    final marketReport = marketAgent.analyze(symbol, ctx);
    final riskReport = riskAgent.analyze(symbol, ctx);
    final portfolioReport = portfolioAgent.analyze(symbol, ctx);
    final tradingReport = tradingAgent.analyze(symbol, ctx);
    final macroReport = macroAgent.analyze(symbol, ctx);
    final backtestReport = backtestAgent.analyze(symbol, ctx);
    final jordyReport = jordyAgent.analyze(symbol, ctx);
    final regimeReport = regimeAgent.analyze(symbol, ctx);
    final onchainReport = onchainAgent.analyze(symbol, ctx);
    final liquidityReport = liquidityAgent.analyze(symbol, ctx);
    final attributionReport = attributionAgent.analyze(symbol, ctx);

    final circuitBreaker = riskReport.details['circuitBreaker'] as bool? ?? false;
    final riskScore = riskReport.details['riskScore'] as double? ?? 0;
    if (circuitBreaker || riskScore > 0.7) return null;

    final price = ctx.prices[symbol] ?? 0;
    final pct = ctx.pcts[symbol] ?? 0;
    final usdtBalance = ctx.usdtBalance;
    final positionsCount = ctx.positions.length;

    final prompt = '''
Tu es un trader professionnel avec des années d'expérience. Analyse $symbol (prix: \$${price.toStringAsFixed(2)}, variation 24h: ${pct.toStringAsFixed(2)}%).

Données techniques du moment :
- Farida (Marché): ${marketReport.recommendation} (confiance: ${(marketReport.confidence * 100).toStringAsFixed(0)}%, score: ${(marketReport.details['score'] as double? ?? 0).toStringAsFixed(2)})
- RSI: ${(marketReport.details['rsi'] as double? ?? 0).toStringAsFixed(0)}
- SMA20: \$${(marketReport.details['sma20'] as double? ?? 0).toStringAsFixed(0)}
- Volatilité: ${((marketReport.details['volatility'] as double? ?? 0) * 100).toStringAsFixed(1)}%
- Volume relatif: ${(marketReport.details['volRatio'] as double? ?? 0).toStringAsFixed(2)}x

Risque (Henri): score ${(riskScore * 100).toStringAsFixed(0)}%, niveau ${riskReport.details['riskLevel'] as String? ?? 'LOW'}

Portefeuille: USDT dispo = \$${usdtBalance.toStringAsFixed(0)}, ${positionsCount} position(s) ouverte(s)

Macro & Web (Emmilienne): Fear & Greed ${macroReport.details['fearGreed'] ?? 'N/A'}/100, ${macroReport.details['webResults'] ?? 0} résultats web — ${macroReport.summary.length > 120 ? macroReport.summary.substring(0, 120) : macroReport.summary}

Backtest (Junior): ${backtestReport.details['trainTrades'] ?? 0} trades train, Sharpe ${backtestReport.details['trainSharpe'] ?? 'N/A'}, WR ${backtestReport.details['trainWinRate'] != null ? ((backtestReport.details['trainWinRate'] as double) * 100).toStringAsFixed(0) : 'N/A'}%

Supervision (Jordy): ${jordyReport.details['healthScore'] ?? 'N/A'}% santé, ${(jordyReport.details['flags'] as List?)?.length ?? 0} alertes
Régime (Marché): ${regimeReport.details['regime'] ?? 'N/A'}
Onchain (Chaîne): activité ${onchainReport.details['whaleActivity'] ?? 'N/A'}, flux ${onchainReport.details['exchangeFlow'] ?? 'N/A'}
Liquidité (Liquidité): spread ${liquidityReport.details['spread'] ?? 'N/A'}%, slippage estimé ${liquidityReport.details['slippage'] ?? 'N/A'}%
Attribution: ${attributionReport.details['totalTrades'] ?? 0} trades historiques, meilleur ${attributionReport.details['bestSymbol'] ?? 'N/A'}

Ta mémoire de trading (utilise ces techniques comme un trader expert, pas comme des règles automatiques) :
${_storage.getAgentMemory()}

Maintenant réfléchis comme un trader :
1. Regarde les données. Est-ce que tu vois une VRAIE opportunité ou c'est du bruit ?
2. Applique les techniques de ta mémoire avec ton jugement. Un indicateur ne fait pas un trade.
3. Si c'est une opportunité solide → dis BUY ou SELL. Sinon → HOLD sans forcer.
4. Taille de la position : utilise ton expérience. 5-10% si t'as un doute, 15-20% si t'es confiant, 20-30% si t'es très sûr.
5. N'entre PAS par ennui ou parce que les données sont neutres. Attends la bonne config.
6. Les techniques sont des GUIDES, pas des règles absolues. Parfois le marché va à l'encontre des indicateurs.

Réponds UNIQUEMENT JSON : {"action":"BUY/SELL/HOLD","confidence":0.0-1.0,"positionSizePct":5-30,"reason":"phrase"}
''';

    try {
      String reply;
      if (_currentModel.startsWith('opencode/')) {
        reply = await _openCode.sendMessage(prompt, systemContext: 'Tu es un trader IA professionnel. Réponds en JSON uniquement.');
      } else {
        reply = await _llm.sendMessage(prompt, systemContext: 'Tu es un trader IA professionnel. Réponds en JSON uniquement.');
      }

      final jsonStart = reply.indexOf('{');
      final jsonEnd = reply.lastIndexOf('}');
      if (jsonStart < 0 || jsonEnd < 0) return null;

      final jsonStr = reply.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final action = (decoded['action'] as String?)?.toUpperCase();
      final confidence = (decoded['confidence'] as num?)?.toDouble() ?? 0;
      final posSize = (decoded['positionSizePct'] as num?)?.toDouble() ?? 10;

      if (action == null || action == 'HOLD' || confidence < 0.4) return null;

      return {
        'action': action,
        'confidence': confidence,
        'positionSizePct': posSize.clamp(5.0, 30.0),
      };
    } catch (_) {
      return null;
    }
  }

  /// Build system context with multi-agent analysis for AI models.
  /// Orchestrates NOAH agents (Market, Risk, Portfolio, Trading) and
  /// provides their analysis as context to the AI model.
  String _buildSystemContext({String symbol = 'BTC'}) {
    if (_portfolio == null || _risk == null) return '';

    final p = _portfolio!.data;
    final r = _risk!;
    final exposure = r.exposurePct;

    // Build full AgentContext from current state
    final ctx = _buildContext();

    // Run multi-agent analysis
    final marketAgent = MarketAgent();
    final riskAgent = RiskAgent();
    final portfolioAgent = PortfolioAgent();
    final tradingAgent = TradingAgent();
    final macroAgent = MacroResearchAgent(thinker: _currentModel == 'noah-agent' ? null : _aiThinker());
    final backtestAgent = BacktestAgent(thinker: _currentModel == 'noah-agent' ? null : _aiThinker());
    final jordyAgent = JordyAgent();
    final regimeAgent = RegimeAgent();
    final onchainAgent = OnchainAgent();
    final liquidityAgent = LiquidityAgent();
    final attributionAgent = AttributionAgent();

    final marketReport = marketAgent.analyze(symbol, ctx);
    final riskReport = riskAgent.analyze(symbol, ctx);
    final portfolioReport = portfolioAgent.analyze(symbol, ctx);
    final tradingReport = tradingAgent.analyze(symbol, ctx);
    final macroReport = macroAgent.analyze(symbol, ctx);
    final backtestReport = backtestAgent.analyze(symbol, ctx);
    final jordyReport = jordyAgent.analyze(symbol, ctx);
    final regimeReport = regimeAgent.analyze(symbol, ctx);
    final onchainReport = onchainAgent.analyze(symbol, ctx);
    final liquidityReport = liquidityAgent.analyze(symbol, ctx);
    final attributionReport = attributionAgent.analyze(symbol, ctx);

    final buf = StringBuffer();

    buf.writeln(AITools.buildSystemContext(
      prices: Map.from(prices),
      pcts: Map.from(pcts),
      portfolio: PortfolioData.fromJson(p.toJson()),
      riskScore: riskReport.details['riskScore'] as double? ?? exposure / 100,
      exposure: exposure,
      circuitBreaker: riskReport.details['circuitBreaker'] as bool? ?? r.circuitBreaker,
      riskLevel: riskReport.details['riskLevel'] as String? ?? r.statusLabel,
      signals: signals,
      isDemo: _storage.getDemoMode(),
    ));

    // Append agent reports
    buf.writeln('\n## Analyse de ton équipe');
    buf.writeln('');

    buf.writeln('### Farida (Analyse Marché)');
    buf.writeln(marketReport.summary);
    buf.writeln('Recommandation: ${marketReport.recommendation} (confiance: ${(marketReport.confidence * 100).toStringAsFixed(0)}%)');
    buf.writeln('');

    buf.writeln('### Henri (Gestion Risque)');
    buf.writeln(riskReport.summary);
    buf.writeln('Confiance: ${(riskReport.confidence * 100).toStringAsFixed(0)}%');
    buf.writeln('');

    buf.writeln('### Alexendra (Gestion Portefeuille)');
    buf.writeln(portfolioReport.summary);
    buf.writeln('');

    buf.writeln('### Dylan (Préparation Ordres)');
    buf.writeln(tradingReport.summary);
    buf.writeln('');

    buf.writeln('### Emmilienne (Recherche Web & Macro)');
    buf.writeln(macroReport.summary);
    buf.writeln('Fear & Greed: ${macroReport.details['fearGreed'] ?? 'N/A'}/100');
    buf.writeln('');

    buf.writeln('### Junior (Backtest)');
    buf.writeln(backtestReport.summary);
    buf.writeln('Sharpe train: ${backtestReport.details['trainSharpe'] ?? 'N/A'}, test: ${backtestReport.details['testSharpe'] ?? 'N/A'}');
    buf.writeln('');

    buf.writeln('### Jordy (Supervision)');
    buf.writeln(jordyReport.summary);
    buf.writeln('Santé portefeuille: ${jordyReport.details['healthScore'] ?? 'N/A'}%, ${(jordyReport.details['flags'] as List?)?.length ?? 0} drapeaux');
    buf.writeln('');

    buf.writeln('### Régime (Marché)');
    buf.writeln('Régime actuel: ${regimeReport.details['regime'] ?? 'N/A'}');
    buf.writeln(regimeReport.summary);
    buf.writeln('');

    buf.writeln('### Chaîne (Onchain)');
    buf.writeln(onchainReport.summary);
    buf.writeln('');

    buf.writeln('### Liquidité (Liquidité)');
    buf.writeln(liquidityReport.summary);
    buf.writeln('');

    buf.writeln('### Attribution');
    buf.writeln(attributionReport.summary);
    buf.writeln('');

    buf.writeln('## Ton rôle');
    buf.writeln('Tu es NOAH, le coordinateur de l\'équipe. Farida, Henri, Alexendra, Dylan, Emmilienne, Junior, Jordy, Régime, Chaîne, Liquidité et Attribution travaillent pour toi.');
    buf.writeln('Cite leurs noms quand tu te réfères à leurs analyses (Farida dit que..., Henri recommande..., Emmilienne a trouvé..., Junior a backtesté...).');
    buf.writeln('Ne dis pas "l\'agent" ou "mon agent" — dis directement leur prénom.');
    buf.writeln('Synthétise les informations, donne ton avis, et utilise les actions [ACTION:...] si nécessaire.');
    buf.writeln('N\'exécute JAMAIS un trade si Henri a activé le circuit breaker ou si son score de risque est > 0.7.');
    buf.writeln('');
    buf.writeln(_storage.getDemoMode()
        ? '⚠️ Mode DÉMO : les montants sont fictifs. Tu peux trader sans risque, mais reste professionnel.'
        : '🔴 Mode RÉEL : l\'argent est réel. Redouble de prudence, vérifie tout deux fois, et mentionne "en réel" dans tes conseils.');

    buf.writeln('');
    buf.writeln('## Mémoire des Techniques de Trading');
    buf.writeln(_storage.getAgentMemory());

    return buf.toString();
  }

  /// Ask the AI to scan a list of symbols and pick the best opportunities.
  Future<List<String>?> scanMarkets(String prompt) async {
    if (_currentModel == 'noah-agent') return null;
    try {
      String reply;
      if (_currentModel.startsWith('opencode/')) {
        reply = await _openCode.sendMessage(prompt, systemContext: 'Tu es un trader. Réponds en JSON.');
      } else {
        reply = await _llm.sendMessage(prompt, systemContext: 'Tu es un trader. Réponds en JSON.');
      }
      final start = reply.indexOf('{');
      final end = reply.lastIndexOf('}');
      if (start < 0 || end < 0) return null;
      final decoded = jsonDecode(reply.substring(start, end + 1)) as Map;
      final picks = decoded['picks'] as List?;
      return picks?.cast<String>();
    } catch (_) {
      return null;
    }
  }

  /// Save a new technique to agent memory.
  void addAgentTechnique(String technique) {
    final memory = _storage.getAgentMemory();
    final lines = memory.split('\n');
    final newEntry = '\n${lines.length + 1}. $technique';
    _storage.setAgentMemory('$memory$newEntry');
  }

  /// Execute actions parsed from AI response.
  String _executeActions(List<Map<String, dynamic>> actions) {
    final results = <String>[];
    for (final action in actions) {
      final type = action['type'] as String? ?? '';
      if (type == 'trade') {
        final result = _executeTradeAction(action);
        if (result != null) {
          results.add(result);
          _lastTradingAction = result;
          notifyListeners();
        }
      } else if (type == 'deposit') {
        final result = _executeDepositAction(action);
        if (result != null) {
          results.add(result);
          _lastTradingAction = result;
          notifyListeners();
        }
      } else if (type == 'stop') {
        _aiRunning = false;
        _tradingEnabled = false;
        notifyListeners();
        NotificationService.onTradingDisabled();
        results.add('⏹ Trading automatique désactivé.');
        _lastTradingAction = '⏹ Trading automatique désactivé';
        notifyListeners();
      }
    }
    return results.join('\n');
  }

  String? _executeTradeAction(Map<String, dynamic> action) {
    if (_portfolio == null) return null;
    if (!_tradingEnabled) return '⛔ Trading désactivé. Activez-le via le bouton dans le chat.';
    final side = (action['side'] as String?)?.toLowerCase();
    final symbol = action['symbol'] as String? ?? _portfolio!.currentSymbol;
    final qty = (action['qty'] as num?)?.toDouble() ?? 0;
    if (side == null || qty <= 0) return null;

    final sl = (action['stopLoss'] as num?)?.toDouble();
    final tp = (action['takeProfit'] as num?)?.toDouble();

    final isDemo = _storage.getDemoMode();
    final useBinance = !isDemo && _binance.isConnected && _binanceWorking;

    if (useBinance) {
      return _executeRealTrade(side, symbol, qty, sl, tp);
    }

    _portfolio!.executeTrade(side, qty, symbol: symbol, stopLoss: sl, takeProfit: tp);

    NotificationService.onTradeExecuted(symbol, side, qty, _portfolio!.data.usdt);
    return '✅ ${side.toUpperCase()} $qty $symbol exécuté${sl != null ? ' (SL: \$${sl.toStringAsFixed(2)})' : ''}${tp != null ? ' (TP: \$${tp.toStringAsFixed(2)})' : ''}';
  }

  String? _executeRealTrade(String side, String symbol, double qty, double? sl, double? tp) {
    _binance.placeMarketOrder(symbol, side, qty).then((result) {
      final fillPrice = result.avgPrice;
      final filledQty = result.executedQty;
      if (fillPrice <= 0 || filledQty <= 0) {
        _lastTradingAction = '⚠️ Ordre $side $symbol partiel ou non exécuté (${result.status}). Vérifiez Binance.';
        notifyListeners();
        return;
      }
      _portfolio!.executeTrade(side, filledQty, symbol: symbol, stopLoss: sl, takeProfit: tp);
      NotificationService.onTradeExecuted(symbol, side, filledQty, fillPrice);
      _lastTradingAction = '✅ ${side.toUpperCase()} $filledQty $symbol exécuté sur Binance @ \$${fillPrice.toStringAsFixed(2)}${sl != null ? ' (SL: \$${sl.toStringAsFixed(2)})' : ''}${tp != null ? ' (TP: \$${tp.toStringAsFixed(2)})' : ''}';
      notifyListeners();
    }).catchError((e) {
      _lastTradingAction = '❌ Erreur Binance: $e';
      notifyListeners();
    });
    return '🔄 Ordre $side $symbol en cours d\'exécution sur Binance...';
  }

  String? _executeDepositAction(Map<String, dynamic> action) {
    if (_portfolio == null) return null;
    if (!_tradingEnabled) return '⛔ Trading désactivé. Activez-le via le bouton dans le chat.';
    final amount = (action['amount'] as num?)?.toDouble() ?? 0;
    if (amount <= 0) return null;
    _portfolio!.deposit(amount, label: 'Dépôt IA');
    return '✅ Dépôt de \$${amount.toStringAsFixed(2)} effectué.';
  }

  void initChat() {
    _messages = [
      ChatMessage(
        id: _uuid.v4(),
        role: 'noah',
        text: '👋 Bonjour, je suis **NOAH**.\n\nVotre copilote de trading IA. Je peux analyser les marchés, identifier des signaux, et évaluer les risques en temps réel.\n\nDonnez-moi un ordre direct comme "achète 0.01 BTC" ou "vend 10 SOL", et j\'exécute immédiatement.\n\nActivez le trading automatique ci-dessous pour une gestion 24/7 :',
        blocks: [MessageBlock.tradingToggle(isActive: false)],
      ),
    ];
    _welcomeVisible = false;
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Restore OpenCode connection from storage
    final savedUrl = _storage.getOpenCodeUrl();
    if (savedUrl.isNotEmpty && savedUrl != 'http://localhost:3000') {
      _openCode.baseUrl = savedUrl;
    }
    final savedModels = _storage.getConnectedModels();
    if (savedModels.containsKey('OpenCode Local')) {
      _currentModel = savedModels['OpenCode Local']!;
      _openCode.model = _currentModel;
      _connectedModels = savedModels;
    }

    notifyListeners();
  }

  void _saveMsgToSession(String role, String text) {
    if (!_auth.isLoggedIn) return;
    final sessions = _storage.getSessions();
    var session = sessions.where((s) => s.id == _currentSessionId).firstOrNull;
    if (session == null) {
      session = ChatSession(
        id: _currentSessionId,
        title: text.length > 40 ? text.substring(0, 40) : text,
      );
      sessions.insert(0, session);
    }
    session.msgs.add(ChatMessage(
      id: _uuid.v4(),
      role: role,
      text: text,
    ));
    session.date = DateTime.now().millisecondsSinceEpoch;
    _storage.saveSessions(sessions);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty || _isTyping) return;
    _generationCancelled = false;
    _welcomeVisible = false;

    // Check for stop command
    final stopDetected = AITools.isStopCommand(text);
    if (stopDetected) {
      _aiRunning = false;
      _tradingEnabled = false;
      notifyListeners();
    }

    // Detect direct trade command: "achète/vente/buy/sell QUANTITÉ SYMBOLE"
    final normalized = text.trim().replaceAll(',', '.');
    final directTrade = RegExp(r'^\s*(achète|achte|buy|achat)\s+([\d.]+)\s+(\w+)\s*$', caseSensitive: false).firstMatch(normalized);
    final directSell = RegExp(r'^\s*(vend|sell|vente)\s+([\d.]+)\s+(\w+)\s*$', caseSensitive: false).firstMatch(normalized);

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: text.trim(),
    );
    _messages.add(userMsg);
    _saveMsgToSession('user', text.trim());
    notifyListeners();

    _isTyping = true;
    final typingId = _uuid.v4();
    _messages.add(ChatMessage(id: typingId, role: 'noah', text: '', isTyping: true));
    notifyListeners();

    // Execute direct trade command immediately
    if (directTrade != null || directSell != null) {
      final isBuy = directTrade != null;
      final match = directTrade ?? directSell!;
      final qty = double.tryParse(match.group(2)!) ?? 0;
      final sym = match.group(3)!.toUpperCase();
      if (qty > 0 && _portfolio != null) {
        _portfolio!.executeTrade(isBuy ? 'buy' : 'sell', qty, symbol: sym);
        final actionText = isBuy ? 'ACHAT' : 'VENTE';
        final price = prices[sym] ?? 0;
        NotificationService.onTradeExecuted(sym, isBuy ? 'buy' : 'sell', qty, price);
        _messages.removeWhere((m) => m.id == typingId);
        final msg = ChatMessage(
          id: _uuid.v4(),
          role: 'noah',
          text: '✅ **$actionText $qty $sym exécuté** à \$${price.toStringAsFixed(2)}\n\nOrdre direct traité sans analyse.',
          blocks: [MessageBlock.tradingToggle(isActive: _tradingEnabled)],
        );
        _messages.add(msg);
        _saveMsgToSession('noah', msg.text);
        _isTyping = false;
        notifyListeners();
        return;
      }
    }

    // Auto-detect trading intent → request confirmation
    final tradingIntent = RegExp(r'\b(trade|trade|achète|achte|vend|achat|vente|investis|entre|position|order|ordre)\b', caseSensitive: false).hasMatch(text);
    if (tradingIntent && !_tradingEnabled && !stopDetected) {
      _pendingTradingRequest = true;
      notifyListeners();
    }

    final symbol = _detectSymbol(text);
    final systemCtx = _buildSystemContext(symbol: symbol);

    if (_currentModel == 'deerflow-agent') {
      _deerFlow.sendMessage(text.trim()).then((resp) {
        _finishResponse(typingId, resp.content);
      });
      return;
    }

    if (_currentModel == 'trading-core') {
      _tradingApi.sendMessage(text.trim(), symbol: symbol).then((resp) {
        if (_generationCancelled) return;
        final reply = resp.response;
        final parsed = AITools.parseResponse(reply, symbol: symbol);
        final actionResults = _executeActions(AITools.parseActions(reply));
        final finalText = actionResults.isNotEmpty
            ? '${parsed.cleanText}\n\n$actionResults'
            : parsed.cleanText;
        final noahMsg = ChatMessage(
          id: _uuid.v4(),
          role: 'noah',
          text: finalText,
          signal: resp.asSignal,
          blocks: parsed.blocks.isNotEmpty ? parsed.blocks : const [],
        );
        _messages.removeWhere((m) => m.id == typingId);
        _messages.add(noahMsg);
        _saveMsgToSession('noah', finalText);
        _isTyping = false;
        notifyListeners();
      });
      return;
    }

    // OpenAI-compatible LLM or OpenCode (all other connected models)
    if (_currentModel != 'noah-agent') {
      final Future<String> replyFuture;
      if (_currentModel.startsWith('opencode/')) {
        replyFuture = _openCode.sendMessage(text.trim(), systemContext: systemCtx.isNotEmpty ? systemCtx : null);
      } else {
        replyFuture = _llm.sendMessage(text.trim(), systemContext: systemCtx.isNotEmpty ? systemCtx : null);
      }
      replyFuture.then((reply) {
        final parsed = AITools.parseResponse(reply, symbol: symbol);
        final actionResults = _executeActions(AITools.parseActions(reply));
        final finalText = actionResults.isNotEmpty
            ? '${parsed.cleanText}\n\n$actionResults'
            : parsed.cleanText;
        _finishResponse(typingId, finalText, blocks: parsed.blocks.isNotEmpty ? parsed.blocks : null);
      });
      return;
    }

    // Use multi-agent system — with AI brain when available
    final ctx = _buildContext();
    if (_mainAgent.hasBrain && _currentModel.startsWith('opencode/')) {
      // AI-powered analysis: OpenCode is the brain
      _mainAgent.fullAnalysisWithAI(symbol, ctx).then((result) {
        final signal = _parseSignalFull(result);
        if (_generationCancelled) return;
        _messages.removeWhere((m) => m.id == typingId);
        final noahMsg = ChatMessage(
          id: _uuid.v4(),
          role: 'noah',
          text: result.narrative.isNotEmpty ? result.narrative : 'Analyse IA complétée',
          signal: signal,
          blocks: result.blocks,
        );
        _messages.add(noahMsg);
        _isTyping = false;
        notifyListeners();
      });
      return;
    }

    // Fallback: rule-based analysis
    final result = _mainAgent.fullAnalysis(symbol, ctx);
    final signal = _parseSignalFull(result);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_generationCancelled) return;
      _messages.removeWhere((m) => m.id == typingId);
      final noahMsg = ChatMessage(
        id: _uuid.v4(),
        role: 'noah',
        text: '',
        signal: signal,
        blocks: result.blocks,
      );
      _messages.add(noahMsg);
      _isTyping = false;
      notifyListeners();
    });
  }

  void _finishResponse(String typingId, String text, {List<MessageBlock>? blocks}) {
    if (_generationCancelled) return;
    _messages.removeWhere((m) => m.id == typingId);
    final noahMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'noah',
      text: text,
      blocks: blocks ?? const [],
    );
    _messages.add(noahMsg);
    _saveMsgToSession('noah', text);
    _isTyping = false;
    notifyListeners();
  }

  void sendImageMessage(String imageBase64) {
    _welcomeVisible = false;
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: '📷 Image',
      imageBase64: imageBase64,
    );
    _messages.add(userMsg);
    notifyListeners();

    _isTyping = true;
    final typingId = _uuid.v4();
    _messages.add(ChatMessage(id: typingId, role: 'noah', text: '', isTyping: true));
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      _messages.removeWhere((m) => m.id == typingId);
      final noahMsg = ChatMessage(
        id: _uuid.v4(),
        role: 'noah',
        text: 'Image reçue. Que souhaitez-vous analyser ?',
      );
      _messages.add(noahMsg);
      _isTyping = false;
      notifyListeners();
    });
  }

  void sendMessageWithImage(String text, String imageBase64) {
    _welcomeVisible = false;
    final msgText = text.trim().isEmpty ? '📷 Image' : text.trim();
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: msgText,
      imageBase64: imageBase64,
    );
    _messages.add(userMsg);
    _saveMsgToSession('user', msgText);
    notifyListeners();

    _isTyping = true;
    final typingId = _uuid.v4();
    _messages.add(ChatMessage(id: typingId, role: 'noah', text: '', isTyping: true));
    notifyListeners();

    // Route through current AI model instead of hardcoded response
    final prompt = msgText == '📷 Image'
        ? 'Analyse cette image et donne-moi tes impressions sur son contenu.'
        : msgText;

    if (_currentModel != 'noah-agent') {
      final ctx = _buildSystemContext();
      final Future<String> replyFuture;
      if (_currentModel.startsWith('opencode/')) {
        replyFuture = _openCode.sendMessage(prompt, systemContext: ctx.isNotEmpty ? ctx : null);
      } else {
        replyFuture = _llm.sendMessage(prompt, systemContext: ctx.isNotEmpty ? ctx : null);
      }
      replyFuture.then((reply) {
        final parsed = AITools.parseResponse(reply);
        final actionResults = _executeActions(AITools.parseActions(reply));
        final finalText = actionResults.isNotEmpty ? '${parsed.cleanText}\n\n$actionResults' : parsed.cleanText;
        _finishResponse(typingId, finalText, blocks: parsed.blocks.isNotEmpty ? parsed.blocks : null);
      });
      return;
    }

    // fallback: multi-agent
    Future.delayed(Duration(milliseconds: 800 + Random().nextInt(600)), () {
      _messages.removeWhere((m) => m.id == typingId);
      final noahMsg = ChatMessage(
        id: _uuid.v4(),
        role: 'noah',
        text: 'Image reçue. Que souhaitez-vous analyser ?',
      );
      _messages.add(noahMsg);
      _saveMsgToSession('noah', 'Image reçue. Que souhaitez-vous analyser ?');
      _isTyping = false;
      notifyListeners();
    });
  }

  String _detectSymbol(String text) {
    final lower = text.toLowerCase();
    for (final s in symbols) {
      if (lower.contains(s.toLowerCase())) return s;
    }
    return 'BTC';
  }

  Signal? _parseSignalFull(AnalysisResult result) {
    final action = result.consensus['action'] as String? ?? 'HOLD';
    final confidence = result.consensus['confidence'] as double? ?? 0.5;
    return Signal(type: action, sym: 'BTC', conf: confidence);
  }

  List<ChatSession> getSessions() => _storage.getSessions();

  void loadSession(String id) {
    final sessions = _storage.getSessions();
    final session = sessions.where((s) => s.id == id).firstOrNull;
    if (session == null) return;
    _currentSessionId = id;
    _messages = session.msgs.map((m) => m).toList();
    _welcomeVisible = false;
    notifyListeners();
  }

  void deleteSession(String id) {
    var sessions = _storage.getSessions();
    sessions.removeWhere((s) => s.id == id);
    _storage.saveSessions(sessions);
    if (id == _currentSessionId) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _messages.clear();
      _welcomeVisible = true;
    }
    notifyListeners();
  }

  void newChat() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.clear();
    _welcomeVisible = true;
    notifyListeners();
  }
}

// ─── Portfolio Provider ──────────────────────────────
class PortfolioProvider extends ChangeNotifier {
  PortfolioData _data = PortfolioData();
  String _currentSymbol = 'BTC';
  VoidCallback? _marketListener;
  SupabaseService? _supabase;
  StorageService? _storage;
  final _riskManager = RiskManager(data: PortfolioData(), prices: prices);
  PerformanceAnalyzer? _analyzer;
  double _dailyLoss = 0;
  bool _circuitBreakerActive = false;

  PortfolioData get data => _data;
  String get currentSymbol => _currentSymbol;
  RiskManager get riskManager => _riskManager;
  PerformanceAnalyzer? get analyzer => _analyzer;
  double get dailyLoss => _dailyLoss;
  bool get circuitBreakerActive => _circuitBreakerActive;

  void setSupabase(SupabaseService s) => _supabase = s;
  void setStorage(StorageService s) {
    _storage = s;
    _data = s.loadPortfolio();
    _rebuildRisk();
    notifyListeners();
  }

  void _rebuildRisk() {
    _riskManager.updateData(_data);
    _analyzer = PerformanceAnalyzer(_data.history, _data.initialUsdt);
  }

  void _persist() {
    _storage?.savePortfolio(_data);
  }

  void syncFromBinance(List<BinanceBalance> balances) {
    final usdt = balances.where((b) => b.asset == 'USDT').firstOrNull;
    if (usdt != null) {
      _data.usdt = usdt.free;
      final deposits = _data.totalDeposits;
      if (deposits <= 0) {
        _data.totalDeposits = usdt.free;
        _data.initialUsdt = usdt.free;
        _data.peakCapital = usdt.free;
      }
      _syncBgt();
      _persist();
    }
    notifyListeners();
  }

  void listenToMarket(ChangeNotifier market) {
    _marketListener?.call();
    final cb = () => notifyListeners();
    market.addListener(cb);
    _marketListener = () => market.removeListener(cb);
  }

  Future<void> _syncToSupabase() async {
    if (_supabase == null) return;
    final email = _supabase!.userEmail ?? 'user';
    try {
      await _supabase!.saveWallet(email, _data.usdt, _data.initialUsdt, _data.totalDeposits);
      await _supabase!.savePositions(email, _data.positions);
      if (_data.history.isNotEmpty) {
        for (final t in _data.history.take(20)) {
          await _supabase!.addTrade(email, t);
        }
      }
    } catch (_) {}
  }

  void _syncBgt() {
    _syncToSupabase();
  }

  void setSymbol(String s) {
    _currentSymbol = s;
    notifyListeners();
  }

  double get pnlPercent {
    final total = _data.usdt + _data.positionsValue;
    if (total <= 0 || _data.totalDeposits <= 0) return 0;
    return ((total - _data.totalDeposits) / _data.totalDeposits) * 100;
  }

  void updatePeakCapital() {
    if (_data.totalValue > _data.peakCapital) {
      _data.peakCapital = _data.totalValue;
    }
  }

  void deposit(double amount, {String label = 'Dépôt'}) {
    if (amount <= 0) return;
    _data.usdt += amount;
    _data.totalDeposits += amount;
    _data.peakCapital += amount;
    _data.walletHistory.insert(0, WalletTransaction(
      type: 'deposit',
      amount: amount,
      label: label,
    ));
    _syncToSupabase();
    _persist();
    notifyListeners();
  }

  void reset() {
    _data = PortfolioData();
    _dailyLoss = 0;
    _circuitBreakerActive = false;
    _rebuildRisk();
    _syncBgt();
    _persist();
    notifyListeners();
  }

  @override
  void dispose() {
    _marketListener?.call();
    super.dispose();
  }

  void closeAll() {
    for (final pos in List<Position>.from(_data.positions)) {
      final cur = prices[pos.sym] ?? 0;
      _data.usdt += pos.qty * cur;
      final pnl = (cur - pos.entry) * pos.qty;
      _data.history.insert(0, TradeOrder(side: 'sell', sym: pos.sym, qty: pos.qty, price: cur, pnl: pnl, time: 'Lock All'));
      _trackDailyPnl(pnl);
    }
    _data.positions.clear();
    _rebuildRisk();
    _syncToSupabase();
    _persist();
    notifyListeners();
  }

  void _trackDailyPnl(double pnl) {
    if (pnl < 0) _dailyLoss += pnl.abs();
    final maxDailyLossPct = 15;
    final maxLoss = _data.totalDeposits * (maxDailyLossPct / 100);
    if (_dailyLoss >= maxLoss) {
      _circuitBreakerActive = true;
    }
  }

  void resetCircuitBreaker() {
    _circuitBreakerActive = false;
    _dailyLoss = 0;
    notifyListeners();
  }

  void executeTrade(String side, double qty, {String? symbol, double? stopLoss, double? takeProfit}) {
    if (qty <= 0) return;
    if (_circuitBreakerActive) return;
    final sym = symbol ?? _currentSymbol;

    final p = prices[sym];
    if (p == null) return;
    final cost = qty * p;

    final riskMgr = _riskManager;
    if (side == 'buy') {
      if (cost > _data.usdt) return;
      final kellySize = riskMgr.kellyPositionSize(
        winRate: _data.winRate.clamp(0.01, 0.99),
        avgWin: _data.bestTrade.clamp(0.01, double.infinity),
        avgLoss: _data.worstTrade.abs().clamp(0.01, double.infinity),
      );
      final maxAllowed = _data.usdt * (kellySize.clamp(0.1, 0.5));
      if (cost > maxAllowed && _data.history.length > 10) return;
    }
    if (side == 'sell') {
      final pos = _data.positions.where((x) => x.sym == sym).firstOrNull;
      if (pos == null || qty > pos.qty) return;
    }
    double? sellPnl;
    if (side == 'buy') {
      _data.usdt -= cost;
      final pos = _data.positions.where((x) => x.sym == sym).firstOrNull;
      if (pos != null) {
        final newQty = pos.qty + qty;
        pos.entry = (pos.entry * pos.qty + p * qty) / newQty;
        pos.qty = newQty;
        if (stopLoss != null) pos.stopLoss = stopLoss;
        if (takeProfit != null) pos.takeProfit = takeProfit;
      } else {
        _data.positions.add(Position(sym: sym, qty: qty, entry: p, stopLoss: stopLoss, takeProfit: takeProfit));
      }
    } else {
      final pos = _data.positions.where((x) => x.sym == sym).firstOrNull;
      if (pos == null) return;
      _data.usdt += cost;
      sellPnl = (p - pos.entry) * qty;
      _trackDailyPnl(sellPnl);
      pos.qty -= qty;
      if (pos.qty < 0.00001) _data.positions.remove(pos);
    }
    _data.history.insert(0, TradeOrder(side: side, sym: sym, qty: qty, price: p, pnl: sellPnl));
    updatePeakCapital();
    _rebuildRisk();
    _syncToSupabase();
    _persist();
    notifyListeners();
  }

  void updateStopLoss(String sym, double? sl) {
    final pos = _data.positions.where((x) => x.sym == sym).firstOrNull;
    if (pos != null) { pos.stopLoss = sl; _persist(); notifyListeners(); }
  }

  void updateTakeProfit(String sym, double? tp) {
    final pos = _data.positions.where((x) => x.sym == sym).firstOrNull;
    if (pos != null) { pos.takeProfit = tp; _persist(); notifyListeners(); }
  }

  AgentContext _buildContextFromData() {
    return AgentContext(
      prices: prices,
      pcts: pcts,
      klines: {},
      bids: {},
      asks: {},
      usdtBalance: _data.usdt,
      positions: _data.positions.map((p) => PositionSnapshot(
        symbol: p.sym, qty: p.qty, entryPrice: p.entry,
        stopLoss: p.stopLoss, takeProfit: p.takeProfit,
      )).toList(),
      history: _data.history.map((t) => TradeSnapshot(
        side: t.side, symbol: t.sym, qty: t.qty, price: t.price, time: t.time,
      )).toList(),
    );
  }

  List<String> checkStopLosses() {
    final closed = <String>[];
    for (final pos in List<Position>.from(_data.positions)) {
      final cur = prices[pos.sym] ?? 0;
      final pnl = (cur - pos.entry) * pos.qty;
      if (pos.stopLoss != null && cur <= pos.stopLoss!) {
        _data.usdt += pos.qty * cur;
        _data.history.insert(0, TradeOrder(side: 'sell', sym: pos.sym, qty: pos.qty, price: cur, pnl: pnl, time: 'SL déclenché'));
        _data.positions.remove(pos);
        closed.add(pos.sym);
      } else if (pos.takeProfit != null && cur >= pos.takeProfit!) {
        _data.usdt += pos.qty * cur;
        _data.history.insert(0, TradeOrder(side: 'sell', sym: pos.sym, qty: pos.qty, price: cur, pnl: pnl, time: 'TP atteint'));
        _data.positions.remove(pos);
        closed.add(pos.sym);
      }
    }
    if (closed.isNotEmpty) {
      _rebuildRisk();
      _syncBgt();
      _persist();
      notifyListeners();
    }
    return closed;
  }
}

// ─── Risk Provider ──────────────────────────────────
class RiskProvider extends ChangeNotifier {
  double maxTradePct = 10;
  double stopLossPct = 5;
  double maxDailyLossPct = 15;
  bool autoTrade = false;
  bool circuitBreaker = true;
  PortfolioProvider? _portfolio;
  StorageService? _storage;

  void attachStorage(StorageService s) {
    _storage = s;
    _loadRisk();
  }

  void _loadRisk() {
    final data = _storage?.loadRisk();
    if (data == null || data.isEmpty) return;
    maxTradePct = (data['maxTradePct'] as num?)?.toDouble() ?? 10;
    stopLossPct = (data['stopLossPct'] as num?)?.toDouble() ?? 5;
    maxDailyLossPct = (data['maxDailyLossPct'] as num?)?.toDouble() ?? 15;
    autoTrade = data['autoTrade'] as bool? ?? false;
    circuitBreaker = data['circuitBreaker'] as bool? ?? true;
    notifyListeners();
  }

  void _saveRisk() {
    _storage?.saveRisk({
      'maxTradePct': maxTradePct,
      'stopLossPct': stopLossPct,
      'maxDailyLossPct': maxDailyLossPct,
      'autoTrade': autoTrade,
      'circuitBreaker': circuitBreaker,
    });
  }

  void attachPortfolio(PortfolioProvider p) {
    _portfolio = p;
    notifyListeners();
  }

  void setMaxTradePct(double v) { maxTradePct = v; _saveRisk(); notifyListeners(); }
  void setStopLossPct(double v) { stopLossPct = v; _saveRisk(); notifyListeners(); }
  void setMaxDailyLossPct(double v) { maxDailyLossPct = v; _saveRisk(); notifyListeners(); }
  void setAutoTrade(bool v) { autoTrade = v; _saveRisk(); notifyListeners(); }
  void setCircuitBreaker(bool v) { circuitBreaker = v; _saveRisk(); notifyListeners(); }

  double get exposurePct {
    final p = _portfolio?.data;
    if (p == null || p.totalValue <= 0) return 0;
    final posValue = p.positionsValue;
    return (posValue / p.totalValue * 100).clamp(0, 100);
  }

  String get statusLabel {
    final e = exposurePct;
    if (e < 40) return 'Profil sûr';
    if (e < 60) return 'Attention';
    return 'Critique';
  }

  ui.Color statusColor(bool isDark) {
    final e = exposurePct;
    if (e < 40) return isDark ? const ui.Color(0xFF4CAF8E) : const ui.Color(0xFF2E7D5E);
    if (e < 60) return isDark ? const ui.Color(0xFFD4A84B) : const ui.Color(0xFFA67C2E);
    return isDark ? const ui.Color(0xFFE07060) : const ui.Color(0xFFB8453A);
  }
}

// ─── Trade Signals ──────────────────────────────────
final signals = [
  Signal(type: 'BUY', sym: 'BTC', conf: 0.81),
  Signal(type: 'HOLD', sym: 'ETH', conf: 0.73),
  Signal(type: 'SELL', sym: 'SOL', conf: 0.68),
];

