import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:local_auth/local_auth.dart';
import 'theme/noah_theme.dart';
import 'services/storage_service.dart';
import 'services/market_service.dart';
import 'services/cache_service.dart';
import 'services/supabase_service.dart';
import 'services/crypto_news_service.dart';
import 'services/technical_analysis.dart';
import 'services/signal_service.dart';
import 'providers/providers.dart';
import 'models/models.dart';
import 'agents/agents.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/hamburger_panel.dart';
import 'widgets/login_modal.dart';
import 'widgets/account_sheet.dart';
import 'widgets/ticker_strip.dart';
import 'screens/core_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/connections_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/risk_screen.dart';
import 'screens/pending_signals_screen.dart';
import 'screens/ai_router_config_screen.dart';
import 'screens/llm_chat_screen.dart';
import 'services/multi_llm_coordinator.dart';
import 'screens/settings_screen.dart';
import 'screens/news_screen.dart';
import 'screens/about_screen.dart';
import 'widgets/notification_bar.dart';
import 'widgets/notification_overlay.dart';
import 'widgets/blocking_overlay.dart';
import 'services/widget_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

class AppShell extends StatefulWidget {
  final StorageService storage;
  final CacheService cache;
  final SupabaseService supabase;

  const AppShell({
    super.key,
    required this.storage,
    required this.cache,
    required this.supabase,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AuthProvider _auth;
  late final SettingsProvider _settings;
  late final ChatProvider _chat;
  late final PortfolioProvider _portfolio;
  late final RiskProvider _risk;
  late final MarketService _market;

  int _currentTab = 0;

  // Hamburger animation
  late AnimationController _hamburgerCtrl;
  late Animation<double> _hamburgerAnim;

  // Overlay animation
  late AnimationController _overlayCtrl;
  late Animation<double> _overlayAnim;

  bool _hamburgerOpen = false;
  bool _accountOpen = false;
  bool _loginOpen = false;
  int _prevNavIndex = 0;
  Timer? _priceTimer;
  Timer? _binanceTimer;
  StreamSubscription? _authSub;
  final _lastTradeTime = <String, DateTime>{};
  int _lastProfitMilestone = 0;
  bool _isLocked = false;
  final MainAgent _mainAgent = MainAgent();
  Map<String, dynamic> _lastSentiment = {};
  final CryptoNewsService _newsService = CryptoNewsService();
  final _decisionCache = <String, Map<String, dynamic>>{};
  final _priceSnapshots = <String, double>{};
  final _signalService = SignalService();

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider(widget.storage);
    _auth.setSupabase(widget.supabase);
    // Admin password must be set by user during setup — no default backdoor
    if (!_auth.hasAdminPassword()) {
      // Will prompt user to create one via login modal
    }
    _settings = SettingsProvider(widget.storage);
    _portfolio = PortfolioProvider();
    _portfolio.setSupabase(widget.supabase);
    _portfolio.setStorage(widget.storage);
    _portfolio.setOnTradeClosed((symbol, exitPrice, pnl) {
      _chat.recordTradeClose(symbol, exitPrice, pnl);
    });
    _risk = RiskProvider(storage: widget.storage);
    _market = MarketService();

    // Auto-lock on startup if biometric lock is enabled
    if (_settings.biometricLock) {
      _isLocked = true;
    }
    _chat = ChatProvider(widget.storage, _auth, buildContext: () {
      final pos = _portfolio.data.positions.map((p) => PositionSnapshot(
        symbol: p.sym,
        qty: p.qty,
        entryPrice: p.entry,
        stopLoss: p.stopLoss,
        takeProfit: p.takeProfit,
      )).toList();
      final hist = _portfolio.data.history.map((t) => TradeSnapshot(
        side: t.side,
        symbol: t.sym,
        qty: t.qty,
        price: t.price,
        time: t.time,
      )).toList();
      return AgentContext(
        prices: Map.from(prices),
        pcts: Map.from(pcts),
        klines: Map.from(_market.klinesMap),
        bids: Map.from(_market.bids),
        asks: Map.from(_market.asks),
        usdtBalance: _portfolio.data.usdt,
        positions: pos,
        history: hist,
      );
    });
    _risk.attachStorage(widget.storage);
    _risk.attachPortfolio(_portfolio);
    _portfolio.listenToMarket(_market);
    _chat.attachProviders(_portfolio, _risk, _market);

    // Load cached prices before connecting (shows last known prices immediately)
    widget.storage.loadCachedPrices();

    _market.connect();
    _chat.initChat();
    _auth.checkBanStatus();
    _auth.checkAppVersion();

    // Auto-connect to OpenCode (Termux/proot-distro)
    _chat.autoConnectOpenCode();

    // Set OpenCode as the brain for the main trading agent
    _mainAgent.setBrain((prompt, {String? systemContext}) {
      return _chat.openCode.sendMessage(prompt, systemContext: systemContext);
    });

    // Listen for Supabase auth state changes
    _authSub = widget.supabase.onAuthChange.listen((event) {
      if (event.session != null && !_auth.isLoggedIn) {
        _auth.finalizeLogin(widget.supabase);
      }
    });

    _hamburgerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hamburgerAnim = CurvedAnimation(
      parent: _hamburgerCtrl,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _overlayAnim = CurvedAnimation(
      parent: _overlayCtrl,
      curve: Curves.easeIn,
    );

    _hamburgerAnim.addListener(() => setState(() {}));
    _overlayAnim.addListener(() => setState(() {}));
    _priceTimer = Timer.periodic(const Duration(seconds: 2), (_) => _portfolio.checkStopLosses());
    _binanceTimer = Timer.periodic(const Duration(seconds: 60), (_) => _syncBinance());
    Timer.periodic(const Duration(seconds: 30), (_) => widget.storage.cachePrices());
    Timer.periodic(const Duration(seconds: 120), (_) => _auth.checkBanStatus());
    try { WidgetService.init(); } catch (_) {}
    _pushWidgetData();
    try {
      Timer.periodic(const Duration(seconds: 30), (_) => _pushWidgetData());
    } catch (_) {}
    Timer.periodic(const Duration(seconds: 60), (_) => _runAgentCycle());
    Timer.periodic(const Duration(seconds: 60), (_) => _chat.checkOpenCodeHealth());
    Timer.periodic(const Duration(minutes: 5), (_) => _fetchSentiment());
    _fetchSentiment(); // Initial fetch
    WidgetsBinding.instance.addObserver(this);
    _authenticateBiometric();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Always try to authenticate when coming back to foreground
      if (_isLocked) {
        _authenticateBiometric();
      }
    } else if (state == AppLifecycleState.paused) {
      // Save prices before going to background
      widget.storage.cachePrices();
      // Auto-lock when app goes to background
      if (_settings.biometricLock) {
        setState(() => _isLocked = true);
      }
      BackgroundService.start();
      _runAgentCycle();
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final localAuth = LocalAuthentication();
      final canBiometric = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      if (!canBiometric && !isSupported) {
        setState(() => _isLocked = false);
        return;
      }
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à NOAH',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false, sensitiveTransaction: true),
      );
      setState(() => _isLocked = !didAuthenticate);
      if (didAuthenticate) {
        BackgroundService.start();
      }
    } catch (_) {
      setState(() => _isLocked = false);
    }
  }

  void _manualLock() {
    setState(() => _isLocked = true);
    _authenticateBiometric();
  }

  Future<void> _runAgentCycle() async {
    if (!_chat.tradingEnabled) return;

    final hasAiBrain = _chat.openCode.isConnected || _chat.isLlmConnected;
    const cooldown = Duration(seconds: 30);

    // ── BRANCH A: AI scan (only when LLM connected) ──
    if (hasAiBrain) {
      final scanCooldown = const Duration(minutes: 1);
      final lastScan = _lastTradeTime['__scan__'];
      if (lastScan == null || DateTime.now().difference(lastScan) >= scanCooldown) {
        final candidates = symbols.where((s) {
          final p = prices[s];
          return p != null && p > 0 && (pcts[s]?.abs() ?? 0) > 0.1;
        }).toList();

        if (candidates.isNotEmpty) {
          final scanPrompt = 'Scan marche: ${candidates.take(10).map((s) {
            return '$s:\$${(prices[s] ?? 0).toStringAsFixed(2)} ${(pcts[s] ?? 0).toStringAsFixed(2)}%';
          }).join(', ')}. Top 2 opportunités. JSON: {"picks":["S1","S2"]}';

          _chat.scanMarkets(scanPrompt).then((picks) {
            _lastTradeTime['__scan__'] = DateTime.now();
            if (picks == null || !mounted) return;
            for (final sym in picks.take(2)) {
              if (!symbols.contains(sym)) continue;
              final lastTrade = _lastTradeTime[sym];
              if (lastTrade != null && DateTime.now().difference(lastTrade) < cooldown) continue;
              final ctx = _buildAgentContext(sym);
              _chat.getAiTradingDecision(sym, ctx).then((result) {
                if (result != null && mounted) _executeSignals(sym, result);
              });
            }
          });
        }
      }

      // Manage existing positions with AI
      for (final pos in List<Position>.from(_portfolio.data.positions)) {
        final lastTrade = _lastTradeTime[pos.sym];
        if (lastTrade != null && DateTime.now().difference(lastTrade) < cooldown) continue;
        final ctx = _buildAgentContext(pos.sym);
        _chat.getAiTradingDecision(pos.sym, ctx).then((result) {
          if (result == null || !mounted) return;
          if (result['action'] == 'SELL') {
            // AI can only sell if position is at a LOSS (to cut losses)
            // or if price is above TP (to take profit)
            final currentPrice = prices[pos.sym] ?? 0;
            final pnlPct = pos.entry > 0 ? (currentPrice - pos.entry) / pos.entry : 0;
            final tp = pos.takeProfit;
            final isAboveTP = tp != null && currentPrice >= tp;
            final isAtLoss = pnlPct < 0;
            // Don't let AI sell small wins - let TP handle it
            if (!isAtLoss && !isAboveTP) return;
            final sellPct = (result['positionSizePct'] as double?) ?? 50;
            final qty = pos.qty * (sellPct / 100);
            if (qty > 0) _portfolio.executeTrade('sell', qty, symbol: pos.sym);
            _lastTradeTime[pos.sym] = DateTime.now();
          }
        });
      }
    }

    // ── BRANCH B: Agents intelligents (LLM) ou regles (sans LLM) ──
    final sortedSymbols = List<String>.from(symbols);
    sortedSymbols.sort((a, b) => (pcts[b]?.abs() ?? 0).compareTo(pcts[a]?.abs() ?? 0));

    for (final sym in sortedSymbols) {
      final lastTrade = _lastTradeTime[sym];
      if (lastTrade != null && DateTime.now().difference(lastTrade) < cooldown) continue;

      // Decision cache: skip if price hasn't changed >0.5%
      final currentPrice = prices[sym] ?? 0;
      final prevPrice = _priceSnapshots[sym];
      if (prevPrice != null && prevPrice > 0) {
        final priceChange = (currentPrice - prevPrice).abs() / prevPrice;
        if (priceChange < 0.005) {
          final cached = _decisionCache[sym];
          if (cached != null) {
            final cachedAction = cached['action'];
            final cachedConfidence = cached['confidence'];
            if (cachedAction != 'HOLD' && cachedConfidence > 0.25) {
              _executeSignals(sym, cached);
            }
            continue;
          }
        }
      }
      _priceSnapshots[sym] = currentPrice;

      final ctx = _buildAgentContext(sym);
      final riskReport = RiskAgent().analyze(sym, ctx);
      if (riskReport.details['circuitBreaker'] as bool? ?? false) continue;
      if ((riskReport.details['riskScore'] as double? ?? 0) > 0.8) continue;

      Map<String, dynamic> signal;

      if (hasAiBrain) {
        // OpenCode direct: chaque decision via le LLM
        final aiResult = await _chat.getAiTradingDecision(sym, ctx);
        if (aiResult == null) continue;
        signal = aiResult;
      } else {
        // Sans LLM: regles automatisees
        final consensus = _mainAgent.analyze(sym, ctx);
        signal = {
          'action': consensus.recommendation ?? 'HOLD',
          'confidence': consensus.confidence,
          'positionSizePct': 25.0,
        };
      }

      _decisionCache[sym] = signal;
      final action = signal['action'] as String;
      final confidence = (signal['confidence'] as num?)?.toDouble() ?? 0;

      if (confidence > 0.3 && action != 'HOLD') {
        final tech = ctx.technicals[sym] ?? {};
        _signalService.addSignal(
          symbol: sym,
          action: action,
          confidence: confidence,
          positionSizePct: (signal['positionSizePct'] as num?)?.toDouble() ?? 25.0,
          reason: signal['reason'] as String? ?? '',
          technicals: tech,
          agentReport: {'score': confidence, 'summary': signal['reason'] ?? ''},
        );
        // Auto-execute si confiance elevee
        if (confidence > 0.6) {
          _executeSignals(sym, signal);
        }
      }
    }

    _checkProfitMilestone();
  }

  void _checkProfitMilestone() {
    final totalValue = _portfolio.data.totalValue;
    final locked = _portfolio.data.totalDeposits;
    if (locked <= 0) return;
    final profit = totalValue - locked;
    final profitPct = (profit / locked) * 100;

    if (profitPct < 1) return;

    final int milestone;
    if (profitPct < 5) {
      milestone = 1;
    } else {
      milestone = (profitPct / 5).floor() * 5;
    }

    if (milestone > _lastProfitMilestone) {
      final milestones = <int>[];
      if (_lastProfitMilestone < 1 && milestone >= 1) milestones.add(1);
      for (int m = 5; m <= milestone; m += 5) {
        if (m > _lastProfitMilestone) milestones.add(m);
      }
      for (final m in milestones) {
        NotificationService.show(
          '💰 Bénéfice : +$m%',
          'Portefeuille à ${profitPct.toStringAsFixed(1)}%',
          tag: 'profit-milestone-$m',
        );
      }
      _lastProfitMilestone = milestone;
    }
  }

  Future<void> _fetchSentiment() async {
    try {
      final sentiment = await _newsService.fetchSentiment(asset: 'BTC');
      if (sentiment.isNotEmpty) {
        _lastSentiment = sentiment;
      }
    } catch (_) {}
    // Enrichir avec la recherche web d'Alex si disponible
    if (_chat.alexBrain.isConnected) {
      try {
        final alexNews = await _chat.alexBrain.searchMarketNews('bitcoin crypto tendance');
        if (alexNews.isNotEmpty) {
          _lastSentiment['alex_context'] = alexNews;
        }
      } catch (_) {}
    }
  }

  double _tradingBudget() {
    final usdt = _portfolio.data.usdt;
    if (usdt <= 0) return 0;
    final threshold = _settings.profitOnlyThreshold;
    if (threshold <= 0) return usdt;

    final totalValue = _portfolio.data.totalValue;
    final locked = _portfolio.data.totalDeposits;
    final profit = totalValue - locked;
    final needed = locked * (threshold / 100);
    final surplus = profit - needed;
    if (surplus <= 0) {
      // Always allow at least 25% of USDT for trading
      return (usdt * 0.25).clamp(0, usdt);
    }
    return surplus.clamp(0, usdt);
  }

  void _executeSignals(String sym, Map<String, dynamic> result) {
    final action = result['action'] as String;
    final basePositionSize = (result['positionSizePct'] as double?) ?? 15.0;
    final positionSizePct = basePositionSize * _chat.learningCache.positionSizeMultiplier;

    if (!_chat.tradingEnabled) return;

    if (action == 'BUY') {
      if (_portfolio.data.positions.any((p) => p.sym == sym && p.qty > 0)) return;
      final buyBudget = _tradingBudget();
      if (buyBudget <= 0) return;
      final price = prices[sym] ?? 0;
      if (price <= 0) return;
      final maxTradeValue = buyBudget * (positionSizePct / 100);
      if (maxTradeValue < 1.0) return; // Minimum $1 per trade
      final qty = maxTradeValue / price;
      final sl = price * 0.97; // Stop loss at 3%
      final tp = price * 1.06; // Take profit at 6%
      if (qty > 0) {
        _portfolio.executeTrade('buy', qty, symbol: sym, stopLoss: sl, takeProfit: tp);
        _lastTradeTime[sym] = DateTime.now();
        if (_settings.notifyTrades) NotificationService.onTradeExecuted(sym, 'buy', qty, price);
      }
    } else if (action == 'SELL') {
      final pos = _portfolio.data.positions.where((p) => p.sym == sym).firstOrNull;
      if (pos == null || pos.qty <= 0) return;
      // Rule-based: only sell if at a loss (cut loss) or above TP (take profit)
      final currentPrice = prices[sym] ?? 0;
      final pnlPct = pos.entry > 0 ? (currentPrice - pos.entry) / pos.entry : 0;
      final isAboveTP = pos.takeProfit != null && currentPrice >= pos.takeProfit!;
      final isAtLoss = pnlPct < 0;
      if (!isAtLoss && !isAboveTP) return; // Hold for TP
      final qty = pos.qty * (positionSizePct / 100);
      _portfolio.executeTrade('sell', qty, symbol: sym);
      _lastTradeTime[sym] = DateTime.now();
      if (_settings.notifyTrades) NotificationService.onTradeExecuted(sym, 'sell', qty, prices[sym] ?? 0);
    }
  }

  AgentContext _buildAgentContext(String symbol) {
    final pos = _portfolio.data.positions.map((p) => PositionSnapshot(
      symbol: p.sym, qty: p.qty, entryPrice: p.entry,
      stopLoss: p.stopLoss, takeProfit: p.takeProfit,
    )).toList();
    final hist = _portfolio.data.history.map((t) => TradeSnapshot(
      side: t.side, symbol: t.sym, qty: t.qty, price: t.price, time: t.time,
    )).toList();
    final technicals = <String, Map<String, dynamic>>{};
    for (final sym in symbols) {
      final k = _market.klinesMap[sym];
      if (k != null && k.length >= 30) {
        technicals[sym] = TechnicalAnalysis.analyze(sym, k);
      }
    }

    return AgentContext(
      prices: Map.from(prices),
      pcts: Map.from(pcts),
      klines: Map.from(_market.klinesMap),
      bids: Map.from(_market.bids),
      asks: Map.from(_market.asks),
      usdtBalance: _portfolio.data.usdt,
      positions: pos,
      history: hist,
      sentiment: _lastSentiment,
      technicals: technicals,
    );
  }

  void _pushWidgetData() {
    final p = _portfolio.data;
    final assets = symbols.map((s) => {
      'symbol': s,
      'price': prices[s] ?? 0.0,
      'change': pcts[s] ?? 0.0,
    }).toList();

    WidgetService.pushMarketData(
      assets: assets,
      portfolioValue: p.totalValue,
      portfolioPnl: p.pnl,
      positionsCount: p.positions.length,
    );

    WidgetService.pushPortfolioData(
      portfolioValue: p.totalValue,
      portfolioPnl: p.pnl,
      positionsCount: p.positions.length,
    );

    final trades = p.history.take(3).map((t) => {
      'side': t.side,
      'symbol': t.sym,
      'qty': t.qty,
      'price': t.price,
    }).toList();

    WidgetService.pushHistoryData(trades: trades);
  }

  Future<void> _syncBinance() async {
    if (!_chat.binanceConnected || !_chat.binanceWorking) return;
    try {
      final balances = await _chat.binance.getAccountBalances();
      if (mounted) {
        _portfolio.syncFromBinance(balances);
      }
    } catch (_) {}
  }

  void _toggleHamburger() {
    setState(() => _hamburgerOpen = !_hamburgerOpen);
    if (_hamburgerOpen) {
      _hamburgerCtrl.forward();
      _overlayCtrl.forward();
    } else {
      _hamburgerCtrl.reverse();
      _overlayCtrl.reverse();
    }
  }

  void _closeHamburger() {
    if (_hamburgerOpen) _toggleHamburger();
  }

  void _toggleAccount() {
    if (_accountOpen) {
      _overlayCtrl.reverse();
      setState(() => _accountOpen = false);
    } else {
      setState(() => _accountOpen = true);
      _overlayCtrl.forward();
    }
  }

  void _closeAccount() {
    if (_accountOpen) _toggleAccount();
  }

  void _openLogin(int tab) {
    setState(() {
      _loginOpen = true;
    });
  }

  void _closeLogin() {
    setState(() => _loginOpen = false);
  }

  void _goTab(int i) {
    setState(() => _currentTab = i);
  }

  @override
  void dispose() {
    _hamburgerCtrl.dispose();
    _overlayCtrl.dispose();
    _priceTimer?.cancel();
    _binanceTimer?.cancel();
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _market.dispose();
    _auth.dispose();
    _settings.dispose();
    _chat.dispose();
    _portfolio.dispose();
    _risk.dispose();
    _signalService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    C.setDark(_settings.isDark);

    if (_auth.needsUpdate) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BlockingOverlay(reason: BlockReason.update),
      );
    }
    if (_auth.banned) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BlockingOverlay(
          reason: BlockReason.banned,
          email: _auth.displayEmail,
        ),
      );
    }
    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _BiometricLockScreen(onUnlock: _authenticateBiometric),
      );
    }

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOAH',
      theme: _settings.isDark
          ? NoahTheme.dark(fontFamily: _settings.fontFamily, useBold: _settings.useBold)
          : NoahTheme.light(fontFamily: _settings.fontFamily, useBold: _settings.useBold),
      home: Theme(
        data: _settings.isDark
            ? NoahTheme.dark(fontFamily: _settings.fontFamily, useBold: _settings.useBold)
            : NoahTheme.light(fontFamily: _settings.fontFamily, useBold: _settings.useBold),
        child: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: _settings.isDark ? NoahColors.dkBg0 : NoahColors.bg0,
              body: NotificationOverlay(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 768;
                    if (isDesktop) {
                      return _buildDesktopLayout(constraints);
                    }
                    return _buildMobileLayout();
                  },
                ),
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(),
            TickerStrip(
              currentSymbol: _portfolio.currentSymbol,
              onSelect: (s) => _portfolio.setSymbol(s),
              isDark: _settings.isDark,
            ),
            NotificationBar(
              tradingEnabled: _chat.tradingEnabled,
              backendOnline: true,
              showReconnected: false,
              isDark: _settings.isDark,
              alexConnected: _chat.alexBrain.isConnected,
            ),
            Expanded(child: RepaintBoundary(child: _buildScreen())),
            NoahBottomNav(
              currentIndex: _currentTab <= 2 ? _currentTab : _currentTab == 7 ? 3 : _currentTab == 4 ? 4 : (_prevNavIndex),
              pendingCount: _signalService.currentPending.length,
              onTap: (i) {
                const mapping = [0, 1, 2, 7, 4];
                _prevNavIndex = i;
                _goTab(mapping[i]);
              },
            ),
          ],
        ),
        if (_overlayCtrl.value > 0)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeHamburger,
              child: IgnorePointer(
                ignoring: !_hamburgerOpen && !_accountOpen,
                child: AnimatedBuilder(
                  animation: _overlayCtrl,
                  builder: (context, _) {
                    return Container(color: Colors.black.withValues(alpha: 0.5 * _overlayAnim.value));
                  },
                ),
              ),
            ),
          ),
        HamburgerPanel(
          isOpen: _hamburgerOpen,
          animValue: _hamburgerAnim.value,
          activeTab: _currentTab,
          onClose: _closeHamburger,
          onGoTab: _goTab,
          chatProvider: _chat,
          authProvider: _auth,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AccountSheet(
            isOpen: _accountOpen,
            animValue: _overlayAnim.value,
            auth: _auth,
            settings: _settings,
            onClose: _closeAccount,
          ),
        ),
        if (_loginOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeLogin,
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
        if (_loginOpen)
          Center(
            child: LoginModal(
              auth: _auth,
              supabase: widget.supabase,
              onClose: _closeLogin,
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final isDark = _settings.isDark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final bg2 = isDark ? const Color(0xFF141414) : const Color(0xFFF0EDE5);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    final navItems = [
      (Icons.dashboard_rounded, 'Core'),
      (Icons.chat_bubble_rounded, 'Chat'),
      (Icons.candlestick_chart_rounded, 'Trade'),
      (Icons.newspaper_rounded, 'News'),
      (Icons.account_balance_wallet_rounded, 'Portfolio'),
      (Icons.settings_rounded, 'Settings'),
    ];
    final navMapping = [0, 1, 2, 7, 4, 6];
    final navIndex = _currentTab <= 2 ? _currentTab : _currentTab == 7 ? 3 : _currentTab == 4 ? 4 : _currentTab == 6 ? 5 : (_prevNavIndex);

    return Row(
      children: [
        Container(
          width: 72,
          decoration: BoxDecoration(
            color: bg2,
            border: Border(right: BorderSide(color: border, width: 0.5)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Center(child: Text('N', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
              ),
              const SizedBox(height: 24),
              ...List.generate(navItems.length, (i) {
                final active = i == navIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: GestureDetector(
                    onTap: () {
                      _prevNavIndex = i;
                      _goTab(navMapping[i]);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(navItems[i].$1, size: 20, color: active ? accent : t2),
                          const SizedBox(height: 4),
                          Text(navItems[i].$2, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? accent : t2)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  TickerStrip(
                    currentSymbol: _portfolio.currentSymbol,
                    onSelect: (s) => _portfolio.setSymbol(s),
                    isDark: _settings.isDark,
                  ),
                  NotificationBar(
                    tradingEnabled: _chat.tradingEnabled,
                    backendOnline: true,
                    showReconnected: false,
                    isDark: _settings.isDark,
                    alexConnected: _chat.alexBrain.isConnected,
                  ),
                  Expanded(child: RepaintBoundary(child: _buildScreen())),
                ],
              ),
              if (_overlayCtrl.value > 0)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeHamburger,
                    child: IgnorePointer(
                      ignoring: !_hamburgerOpen && !_accountOpen,
                      child: AnimatedBuilder(
                        animation: _overlayCtrl,
                        builder: (context, _) => Container(color: Colors.black.withValues(alpha: 0.5 * _overlayAnim.value)),
                      ),
                    ),
                  ),
                ),
              HamburgerPanel(
                isOpen: _hamburgerOpen,
                animValue: _hamburgerAnim.value,
                activeTab: _currentTab,
                onClose: _closeHamburger,
                onGoTab: _goTab,
                chatProvider: _chat,
                authProvider: _auth,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AccountSheet(
                  isOpen: _accountOpen,
                  animValue: _overlayAnim.value,
                  auth: _auth,
                  settings: _settings,
                  onClose: _closeAccount,
                ),
              ),
              if (_loginOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeLogin,
                    child: Container(color: Colors.black.withValues(alpha: 0.45)),
                  ),
                ),
              if (_loginOpen)
                Center(
                  child: LoginModal(
                    auth: _auth,
                    supabase: widget.supabase,
                    onClose: _closeLogin,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final c = C();
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          decoration: BoxDecoration(
            color: _settings.isDark
                ? Color.fromRGBO(13, 13, 13, 0.88)
                : Color.fromRGBO(247, 244, 238, 0.90),
            border: Border(
              bottom: BorderSide(
                color: (_settings.isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (_settings.isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Hamburger
                GestureDetector(
                  onTap: _toggleHamburger,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(
                      painter: _HamburgerPainter(
                        progress: _hamburgerAnim.value,
                        color: c.t1,
                        accent: c.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'NOAH',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: c.accent,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ListenableBuilder(
                        listenable: _market,
                        builder: (_, __) {
                          final isLive = _market.status == MarketStatus.live;
                          final isSimu = _market.status == MarketStatus.simulated;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive ? const Color(0xFF4CAF8E) : isSimu ? const Color(0xFFD4A84B) : const Color(0xFF6C6C6C),
                                  boxShadow: isLive ? [BoxShadow(color: const Color(0xFF4CAF8E).withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)] : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLive ? 'LIVE' : isSimu ? 'SIMU' : '...',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isLive ? const Color(0xFF4CAF8E) : isSimu ? const Color(0xFFD4A84B) : const Color(0xFF6C6C6C),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Demo/Real badge
                ListenableBuilder(
                  listenable: _settings,
                  builder: (_, __) {
                    final isDemo = _settings.isDemo;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDemo ? c.amberBg : const Color(0x1AE55353),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDemo ? c.amberBorder : const Color(0x2EE55353)),
                      ),
                      child: Text(
                        isDemo ? 'DÉMO' : 'RÉEL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDemo ? c.amber : const Color(0xFFE55353),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                // Avatar
                GestureDetector(
                  onTap: _toggleAccount,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.accentBorder),
                      image: DecorationImage(
                        image: AssetImage(_settings.profileIcon),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentTab) {
      case 0:
        return CoreScreen(chat: _chat, goTab: _goTab, portfolio: _portfolio, risk: _risk);
      case 1:
        return ChatScreen(chat: _chat, navigateToConnections: () => setState(() => _currentTab = 3));
      case 2:
        return TradeScreen(portfolio: _portfolio, auth: _auth, risk: _risk, market: _market, settings: _settings, chat: _chat, openLogin: _openLogin, navigateToChat: () => setState(() => _currentTab = 1));
      case 3:
        return ConnectionsScreen(auth: _auth, chat: _chat, openLogin: _openLogin);
      case 4:
        return PortfolioScreen(portfolio: _portfolio, isDemo: widget.storage.getDemoMode());
      case 5:
        return RiskScreen(risk: _risk, portfolio: _portfolio);
      case 6:
        return SettingsScreen(settings: _settings, auth: _auth, chat: _chat, market: _market, cache: widget.cache, storage: widget.storage, openLogin: _openLogin, onLock: _manualLock);
      case 7:
        return const NewsScreen();
      case 8:
        return const AboutScreen();
      case 9:
        return PendingSignalsScreen(signalService: _signalService);
      case 10:
        return AIRouterConfigScreen(storage: widget.storage);
      case 11:
        return LLMChatScreen(coordinator: MultiLLMCoordinator());
      default:
        return CoreScreen(chat: _chat, goTab: _goTab);
    }
  }
}

class _HamburgerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accent;

  _HamburgerPainter({required this.progress, required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Color.lerp(color, accent, progress)!
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Three lines at: y-5, y, y+5 from cx-9 to cx+9
    // Open state: top rotates 45deg + translateY(5), mid fades, bot rotates -45deg + translateY(-5)

    // Top line: rotate from 0 to 45deg around center, translateY from -5 to 0
    final topAngle = progress * 45 * math.pi / 180;
    final topDy = _lerp(-5.0, 5.0, progress);
    final topLen = _lerp(9.0, 7.0, progress);
    final topX1 = cx - topLen * math.cos(topAngle);
    final topY1 = cy + topDy - topLen * math.sin(topAngle);
    final topX2 = cx + topLen * math.cos(topAngle);
    final topY2 = cy + topDy + topLen * math.sin(topAngle);
    canvas.drawLine(
      Offset(topX1, topY1),
      Offset(topX2, topY2),
      basePaint..color = basePaint.color.withValues(alpha: 1.0),
    );

    // Mid line: fades out
    final midOpacity = 1.0 - progress;
    canvas.drawLine(
      Offset(cx - 9, cy),
      Offset(cx + 9, cy),
      basePaint..color = basePaint.color.withValues(alpha: midOpacity),
    );

    // Bottom line: rotate from 0 to -45deg around center, translateY from +5 to 0
    final botAngle = progress * -45 * math.pi / 180;
    final botDy = _lerp(5.0, -5.0, progress);
    final botLen = _lerp(9.0, 7.0, progress);
    final botX1 = cx - botLen * math.cos(botAngle);
    final botY1 = cy + botDy - botLen * math.sin(botAngle);
    final botX2 = cx + botLen * math.cos(botAngle);
    final botY2 = cy + botDy + botLen * math.sin(botAngle);
    canvas.drawLine(
      Offset(botX1, botY1),
      Offset(botX2, botY2),
      basePaint..color = basePaint.color.withValues(alpha: 1.0),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _HamburgerPainter old) => old.progress != progress;
}

class _BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const _BiometricLockScreen({required this.onUnlock});

  @override
  State<_BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<_BiometricLockScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _unlockWithBiometric() {
    widget.onUnlock();
  }

  void _unlockWithPin() {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Entrez le mot de passe');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    // Read admin password from storage
    final storage = StorageService();
    storage.init().then((_) {
      final stored = storage.getAdminPassword();
      if (stored == pin) {
        widget.onUnlock();
      } else {
        setState(() {
          _loading = false;
          _error = 'Mot de passe incorrect';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF7F4EE);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final bg2 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0ECE4);
    final border = isDark ? const Color(0x22FFFFFF) : const Color(0x22000000);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.fingerprint, size: 44, color: accent),
            ),
            const SizedBox(height: 24),
            Text('NOAH', style: TextStyle(
              fontFamily: 'PlayfairDisplay', fontSize: 28, fontWeight: FontWeight.w700,
              color: accent, letterSpacing: 3,
            )),
            const SizedBox(height: 8),
            Text('Verrouillé', style: TextStyle(fontSize: 14, color: t2)),
            const SizedBox(height: 32),
            // PIN input
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: bg2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, letterSpacing: 8, color: t0),
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: TextStyle(color: t2, letterSpacing: 8),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _unlockWithPin(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(fontSize: 12, color: const Color(0xFFE07060))),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loading ? null : _unlockWithPin,
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Déverrouiller', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: t2.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: TextStyle(fontSize: 11, color: t2)),
                ),
                Expanded(child: Divider(color: t2.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _unlockWithBiometric,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Text('Empreinte digitale', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

