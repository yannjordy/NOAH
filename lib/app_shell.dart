import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:local_auth/local_auth.dart';
import 'theme/noah_theme.dart';
import 'services/storage_service.dart';
import 'services/market_service.dart';
import 'services/cache_service.dart';
import 'services/supabase_service.dart';
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
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/backtest_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider(widget.storage);
    _auth.setSupabase(widget.supabase);
    // Set default admin password if none exists
    if (!_auth.hasAdminPassword()) {
      _auth.setupAdminPassword('1234');
    }
    _settings = SettingsProvider(widget.storage);
    _portfolio = PortfolioProvider();
    _portfolio.setSupabase(widget.supabase);
    _portfolio.setStorage(widget.storage);
    _risk = RiskProvider();
    _market = MarketService();
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
    _market.connect();
    _chat.initChat();
    _auth.checkBanStatus();
    _auth.checkAppVersion();

    // Set OpenCode as the brain for the main trading agent
    _mainAgent.setBrain((prompt, {String? systemContext}) {
      return _chat.openCode.sendMessage(prompt, systemContext: systemContext);
    });

    // Listen for Supabase auth state changes
    _authSub = widget.supabase.onAuthChange.listen((event) {
      if (event['session'] != null && !_auth.isLoggedIn) {
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
    Timer.periodic(const Duration(seconds: 120), (_) => _auth.checkBanStatus());
    WidgetService.init();
    _pushWidgetData();
    Timer.periodic(const Duration(seconds: 30), (_) => _pushWidgetData());
    Timer.periodic(const Duration(seconds: 5), (_) => _runAgentCycle());
    WidgetsBinding.instance.addObserver(this);
    _authenticateBiometric();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only authenticate on resume if already locked (manual lock)
      if (_isLocked) {
        _authenticateBiometric();
      }
    } else if (state == AppLifecycleState.paused) {
      // Don't auto-lock - just start background service
      BackgroundService.start();
      _runAgentCycle();
    }
  }

  Future<void> _authenticateBiometric() async {
    if (kIsWeb) {
      setState(() => _isLocked = false);
      BackgroundService.start();
      return;
    }
    try {
      final localAuth = LocalAuthentication();
      final canBiometric = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      if (!canBiometric && !isSupported) {
        setState(() => _isLocked = false);
        BackgroundService.start();
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
      BackgroundService.start();
    }
  }

  void _manualLock() {
    setState(() => _isLocked = true);
    _authenticateBiometric();
  }

  void _runAgentCycle() {
    final isOpenCode = _chat.currentModel.startsWith('opencode/');
    final scanCooldown = isOpenCode ? const Duration(seconds: 30) : const Duration(seconds: 5);
    const cooldown = Duration(seconds: 10);

    // Network stability check: skip trading if data is stale
    if (!isDataFresh(maxAgeSeconds: 30)) {
      // Data too old, skip trading decisions but still run local agents
    } else if (_chat.currentModel != 'noah-agent' && _chat.tradingEnabled) {
      final lastScan = _lastTradeTime['__scan__'];
      if (lastScan != null && DateTime.now().difference(lastScan) < scanCooldown) {
        // Skip Branch A, go directly to Branch B
      } else {
        final candidates = symbols.where((s) {
          final p = prices[s];
          return p != null && p > 0 && (pcts[s]?.abs() ?? 0) > 0.1;
        }).toList();

        if (candidates.isNotEmpty) {
          final scanPrompt = '''
Tu es un trader qui scanne le marché. Voici ${candidates.length} symboles avec leurs données :

${candidates.take(15).map((s) {
  final p = prices[s] ?? 0;
  final c = pcts[s] ?? 0;
  return '- $s: \$${p.toStringAsFixed(2)} (${c.toStringAsFixed(2)}%)';
}).join('\n')}

Choisis les 2 meilleures opportunités de TRADING maintenant. Utilise ton jugement d'expert, pas des règles automatiques.
Regarde les variations, les niveaux de prix, et sense le marché.

Réponds UNIQUEMENT JSON : {"picks":["SYMBOLE1","SYMBOLE2"]}
''';

          _chat.scanMarkets(scanPrompt).then((picks) {
            _lastTradeTime['__scan__'] = DateTime.now();
            if (picks == null || !mounted) return;
            for (final sym in picks) {
              if (!symbols.contains(sym)) continue;
              final lastTrade = _lastTradeTime[sym];
              if (lastTrade != null && DateTime.now().difference(lastTrade) < cooldown) continue;
              final ctx = _buildAgentContext(sym);
              _chat.getAiTradingDecision(sym, ctx).then((result) {
                if (result == null || !mounted) return;
                _executeSignals(sym, result);
              });
            }
          });
        }
      }

      for (final pos in _portfolio.data.positions) {
        if (pos.sym == null) continue;
        final lastTrade = _lastTradeTime[pos.sym!];
        if (lastTrade != null && DateTime.now().difference(lastTrade) < cooldown) continue;
        final ctx = _buildAgentContext(pos.sym!);
        _chat.getAiTradingDecision(pos.sym!, ctx).then((result) {
          if (result == null || !mounted) return;
          if (result['action'] == 'SELL') {
            final sellPct = (result['positionSizePct'] as double?) ?? 50;
            final qty = pos.qty * (sellPct / 100);
            if (qty > 0) {
              _portfolio.executeTrade('sell', qty, symbol: pos.sym!);
              _lastTradeTime[pos.sym!] = DateTime.now();
            }
          }
        });
      }
    }

    for (final sym in symbols) {
      final lastTrade = _lastTradeTime[sym];
      if (lastTrade != null && DateTime.now().difference(lastTrade) < cooldown) continue;

      final ctx = _buildAgentContext(sym);
      final riskReport = RiskAgent().analyze(sym, ctx);
      if (riskReport.details['circuitBreaker'] as bool? ?? false) continue;
      if ((riskReport.details['riskScore'] as double? ?? 0) > 0.8) continue;

      // Use AI-powered analysis when OpenCode brain is available
      if (_mainAgent.hasBrain && _chat.currentModel.startsWith('opencode/')) {
        _mainAgent.fullAnalysisWithAI(sym, ctx).then((result) {
          if (!mounted) return;
          final action = result.consensus['action'] as String? ?? 'HOLD';
          final confidence = result.consensus['confidence'] as double? ?? 0;
          if (confidence > 0.35 && _chat.tradingEnabled) {
            _executeSignals(sym, {
              'action': action,
              'confidence': confidence,
              'positionSizePct': result.consensus['aiPositionSizePct'] as double? ?? 10,
            });
          }
        });
      } else {
        final consensus = _mainAgent.analyze(sym, ctx);
        final action = consensus.recommendation ?? 'HOLD';
        final confidence = consensus.confidence;

        if (confidence > 0.35 && _chat.tradingEnabled) {
          if (action == 'BUY') {
            if (_portfolio.data.positions.any((p) => p.sym == sym && p.qty > 0)) continue;
            final buyBudget = _tradingBudget();
            if (buyBudget <= 0) continue;
            final price = prices[sym] ?? 0;
            if (price > 0) {
              final maxTradeValue = buyBudget * 0.15;
              final qty = maxTradeValue / price;
              if (qty > 0 && maxTradeValue <= buyBudget) {
                _portfolio.executeTrade('buy', qty, symbol: sym);
                _lastTradeTime[sym] = DateTime.now();
                if (_settings.notifyTrades) NotificationService.onTradeExecuted(sym, 'buy', qty, price);
              }
            }
          } else if (action == 'SELL') {
            final pos = _portfolio.data.positions.where((p) => p.sym == sym).firstOrNull;
            if (pos != null && pos.qty > 0) {
              final qty = pos.qty * 0.5;
              _portfolio.executeTrade('sell', qty, symbol: sym);
              _lastTradeTime[sym] = DateTime.now();
              if (_settings.notifyTrades) NotificationService.onTradeExecuted(sym, 'sell', qty, prices[sym] ?? 0);
            }
          }
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

  double _tradingBudget() {
    final threshold = _settings.profitOnlyThreshold;
    if (threshold <= 0) return _portfolio.data.usdt;

    final totalValue = _portfolio.data.totalValue;
    final locked = _portfolio.data.totalDeposits;
    if (locked <= 0) return _portfolio.data.usdt;
    final profit = totalValue - locked;
    final needed = locked * (threshold / 100);
    final surplus = profit - needed;
    if (surplus <= 0) return _portfolio.data.usdt * 0.5;
    return surplus.clamp(0, _portfolio.data.usdt);
  }

  void _executeSignals(String sym, Map<String, dynamic> result) {
    final action = result['action'] as String;
    final confidence = result['confidence'] as double;
    final positionSizePct = result['positionSizePct'] as double;

    if (!_chat.tradingEnabled) return;

    // Network stability: block trades if data is stale
    if (!isDataFresh(maxAgeSeconds: 15)) return;

    if (action == 'BUY') {
      if (_portfolio.data.positions.any((p) => p.sym == sym && p.qty > 0)) return;
      final buyBudget = _tradingBudget();
      if (buyBudget <= 0) return;
      final price = prices[sym] ?? 0;
      if (price <= 0) return;
      final maxTradeValue = buyBudget * (positionSizePct / 100);
      final qty = maxTradeValue / price;
      if (qty > 0 && maxTradeValue <= buyBudget) {
        _portfolio.executeTrade('buy', qty, symbol: sym);
        _lastTradeTime[sym] = DateTime.now();
        if (_settings.notifyTrades) NotificationService.onTradeExecuted(sym, 'buy', qty, price);
      }
    } else if (action == 'SELL') {
      final pos = _portfolio.data.positions.where((p) => p.sym == sym).firstOrNull;
      if (pos == null || pos.qty <= 0) return;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    C.setDark(_settings.isDark);

    if (_auth.needsUpdate) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BlockingOverlay(
          reason: BlockReason.update,
          onBypass: () => setState(() => _auth.bypassUpdate()),
        ),
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
        home: _BiometricLockScreen(onUnlock: _authenticateBiometric, storage: widget.storage),
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
                child: Center(
                  child: SizedBox(
                    width: 430,
                    child: Stack(
                    children: [
                      // Main content
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
                          ),
                          Expanded(child: RepaintBoundary(child: _buildScreen())),
                          NoahBottomNav(
                            currentIndex: _currentTab <= 2 ? _currentTab : _currentTab == 4 ? 3 : (_prevNavIndex),
                            onTap: (i) {
                              const mapping = [0, 1, 2, 4];
                              _prevNavIndex = i;
                              _goTab(mapping[i]);
                            },
                          ),
                        ],
                      ),
                      // Hamburger overlay
                      if (_overlayCtrl.value > 0)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _closeHamburger,
                            child: IgnorePointer(
                              ignoring: !_hamburgerOpen && !_accountOpen,
                              child: AnimatedBuilder(
                                animation: _overlayCtrl,
                                builder: (context, _) {
                                  return Container(
                                    color: Colors.black.withOpacity( 0.5 * _overlayAnim.value),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      // Hamburger panel
                      HamburgerPanel(
                        isOpen: _hamburgerOpen,
                        animValue: _hamburgerAnim.value,
                        activeTab: _currentTab,
                        onClose: _closeHamburger,
                        onGoTab: _goTab,
                        chatProvider: _chat,
                        authProvider: _auth,
                      ),
                      // Account sheet
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
                      // Login overlay
                      if (_loginOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _closeLogin,
                            child: Container(color: Colors.black.withOpacity( 0.45)),
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
              ),
            ),
          );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildTopBar() {
    final c = C();
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          decoration: BoxDecoration(
            color: _settings.isDark
                ? const Color(0x1A1E1E1E)
                : const Color(0x1AFFFFFF),
            border: Border(
              bottom: BorderSide(
                color: _settings.isDark
                    ? const Color(0x22FFFFFF)
                    : const Color(0x22000000),
              ),
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
                                  boxShadow: isLive ? [BoxShadow(color: const Color(0xFF4CAF8E).withOpacity( 0.6), blurRadius: 4, spreadRadius: 1)] : null,
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
        return PortfolioScreen(portfolio: _portfolio);
      case 5:
        return RiskScreen(risk: _risk, portfolio: _portfolio);
      case 6:
        return SettingsScreen(settings: _settings, risk: _risk, auth: _auth, chat: _chat, market: _market, cache: widget.cache, storage: widget.storage, openLogin: () => _openLogin(0));
      case 7:
        return const AboutScreen();
      case 8:
        return BacktestScreen(portfolio: _portfolio, market: _market);
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
      basePaint..color = basePaint.color.withOpacity( 1.0),
    );

    // Mid line: fades out
    final midOpacity = 1.0 - progress;
    canvas.drawLine(
      Offset(cx - 9, cy),
      Offset(cx + 9, cy),
      basePaint..color = basePaint.color.withOpacity( midOpacity),
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
      basePaint..color = basePaint.color.withOpacity( 1.0),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _HamburgerPainter old) => old.progress != progress;
}

class _BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final StorageService storage;
  const _BiometricLockScreen({required this.onUnlock, required this.storage});

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
    final stored = widget.storage.getAdminPassword();
    if (stored == pin) {
      widget.onUnlock();
    } else {
      setState(() {
        _loading = false;
        _error = 'Mot de passe incorrect';
      });
    }
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
                color: accent.withOpacity( 0.15),
                border: Border.all(color: accent.withOpacity( 0.3)),
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
                Expanded(child: Divider(color: t2.withOpacity( 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: TextStyle(fontSize: 11, color: t2)),
                ),
                Expanded(child: Divider(color: t2.withOpacity( 0.3))),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _unlockWithBiometric,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: accent.withOpacity( 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: accent.withOpacity( 0.3)),
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

