import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/providers.dart';
import '../models/models.dart';


class CoreScreen extends StatefulWidget {
  final ChatProvider chat;
  final void Function(int) goTab;
  final PortfolioProvider? portfolio;
  final RiskProvider? risk;

  const CoreScreen({super.key, required this.chat, required this.goTab, this.portfolio, this.risk});

  @override
  State<CoreScreen> createState() => _CoreScreenState();
}

class _CoreScreenState extends State<CoreScreen> with TickerProviderStateMixin {
  String _greeting = '';
  String _greetingEmoji = '';
  String _date = '';

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  late final AnimationController _chartCtrl;
  late final Animation<double> _chartAnim;

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  Timer? _refreshTimer;

  int _activeTab = 0;
  int _perfTimeframe = 0;
  final _tabLabels = ['Aperçu', 'Performance', 'Trades'];
  final _tabIcons = [Icons.dashboard_rounded, Icons.trending_up_rounded, Icons.receipt_long_rounded];

  final _agentIcons = <String, IconData>{
    'NOAH': Icons.psychology,
    'Farida': Icons.insights,
    'Henri': Icons.shield,
    'Dylan': Icons.account_balance_wallet,
    'Alexendra': Icons.swap_vert,
    'Junior': Icons.history,
    'Emmilienne': Icons.public,
    'Jordy': Icons.health_and_safety,
  };

  final _agentRoles = <String, String>{
    'NOAH': 'Orchestrateur',
    'Farida': 'Analyse Technique',
    'Henri': 'Gestion Risques',
    'Dylan': 'Portefeuille',
    'Alexendra': 'Ordres',
    'Junior': 'Backtesting',
    'Emmilienne': 'Recherche Macro',
    'Jordy': 'Supervision',
  };

  final _agentPersonalities = <String, String>{
    'NOAH': 'Leader visionnaire, calme sous pression.',
    'Farida': 'Analytique et méthodique. Ses analyses sont toujours justes.',
    'Henri': 'Prudent et strict. Il dit non quand tout le monde dit oui.',
    'Dylan': 'Organisé et pragmatique. Pas de folie, pas de panique.',
    'Alexendra': 'Rapide et décisive. Quand elle voit une entrée, elle fonce.',
    'Junior': 'Curieux et studieux. Teste des stratégies dans le passé.',
    'Emmilienne': 'Cultivée et connectée. Rien ne lui échappe.',
    'Jordy': 'Vigilant et rigoureux. Surveille tout le monde.',
  };

  final _agentGenders = <String, String>{
    'NOAH': 'male', 'Farida': 'female', 'Henri': 'male',
    'Dylan': 'male', 'Alexendra': 'female', 'Junior': 'male',
    'Emmilienne': 'female', 'Jordy': 'male',
  };

  @override
  void initState() {
    super.initState();

    final h = DateTime.now().hour;
    if (h < 6) { _greeting = 'Bonne nuit'; _greetingEmoji = '🌙'; }
    else if (h < 12) { _greeting = 'Bonjour'; _greetingEmoji = '☀️'; }
    else if (h < 18) { _greeting = 'Bon après-midi'; _greetingEmoji = '🌤'; }
    else { _greeting = 'Bonsoir'; _greetingEmoji = '🌆'; }

    final now = DateTime.now();
    final weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    _date = '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _chartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _chartAnim = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutQuart);
    _chartCtrl.forward();

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
    _slideCtrl.forward();

    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseCtrl.dispose();
    _chartCtrl.dispose();
    _glowCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _chartCtrl.forward(from: 0);
      _slideCtrl.forward(from: 0);
    });
    HapticFeedback.mediumImpact();
  }

  void _sendQuick(String text) {
    widget.chat.sendMessage(text);
    widget.goTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = isDark ? const Color(0x1AC2A878) : const Color(0x1AB08D57);
    final accentBorder = isDark ? const Color(0x2EC2A878) : const Color(0x33B08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final greenBg = isDark ? const Color(0x144CAF8E) : const Color(0x142E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final redBg = isDark ? const Color(0x14E07060) : const Color(0x14B8453A);
    final femaleBg = isDark ? const Color(0x1AC2A878) : const Color(0x18B08D57);
    final maleBg = isDark ? const Color(0x1A4A90D9) : const Color(0x184A90D9);

    return Container(
      color: bg0,
      child: ListenableBuilder(
        listenable: widget.portfolio ?? ChangeNotifier(),
        builder: (context, _) {
          final p = widget.portfolio?.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _buildHeader(isDark, t0, t2, accent, bg1, border),
              const SizedBox(height: 14),
              _buildPortfolioCard(p, isDark, bg1, border, accent, accentBg, accentBorder, t0, t1, t2, green, greenBg, red, redBg),
              const SizedBox(height: 14),
              _buildMarketTicker(isDark, bg1, border, accent, t0, t1, t2, green, red),
              const SizedBox(height: 14),
              _buildTabBar(isDark, accent, accentBg, accentBorder, t2),
              const SizedBox(height: 14),
              if (_activeTab == 0) _buildOverview(isDark, bg1, border, accent, accentBg, accentBorder, t0, t1, t2, green, greenBg, red, redBg, femaleBg, maleBg, p),
              if (_activeTab == 1) _buildPerformance(p, isDark, bg1, border, accent, t0, t1, t2, green, red),
              if (_activeTab == 2) _buildTrades(p, isDark, bg1, border, accent, t0, t1, t2, green, greenBg, red, redBg),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader(bool isDark, Color t0, Color t2, Color accent, Color bg1, Color border) {
    return SlideTransition(
      position: _slideAnim,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_greetingEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(_greeting,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t0, letterSpacing: -0.3)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_date, style: TextStyle(fontSize: 10, color: t2, letterSpacing: 0.3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.refresh_rounded, size: 16, color: accent),
              ),
            ),
          ),
        ],
      ),
    );
}

  // ═══════════════════════════════════════════════════════
  //  PORTFOLIO CARD — Premium
  // ═══════════════════════════════════════════════════════

  Widget _buildPortfolioCard(PortfolioData? p, bool isDark, Color bg1, Color border, Color accent,
      Color accentBg, Color accentBorder, Color t0, Color t1, Color t2, Color green, Color greenBg,
      Color red, Color redBg) {
    final totalVal = p?.totalValue ?? 0;
    final deposits = p?.totalDeposits ?? 0.0;
    final pnlVal = totalVal - deposits;
    final pnlPct = deposits > 0 ? ((totalVal - deposits) / deposits * 100) : 0;
    final isUp = pnlVal >= 0;
    final pnlColor = isUp ? green : red;

    return SlideTransition(
      position: _slideAnim,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Color.fromRGBO(255, 255, 255, 0.06)
                  : Color.fromRGBO(0, 0, 0, 0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: Container(
                        width: 110,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: isUp
                                ? [const Color.fromRGBO(76, 175, 142, 0.28), const Color.fromRGBO(76, 175, 142, 0.0)]
                                : [const Color.fromRGBO(224, 112, 96, 0.28), const Color.fromRGBO(224, 112, 96, 0.0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentBorder),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Argent disponible (retirable)',
                    style: TextStyle(fontSize: 10, color: t2, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                ),
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pnlColor.withValues(alpha: 0.5 + _glowAnim.value * 0.5),
                      boxShadow: [BoxShadow(color: pnlColor.withValues(alpha: _glowAnim.value * 0.4), blurRadius: 6, spreadRadius: 1)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1, fontFamily: 'JetBrainsMono')),
                const SizedBox(width: 2),
                Text(_fmt(p?.usdt ?? 0),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: t0, fontFamily: 'JetBrainsMono', height: 1)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _miniStat('Valeur totale', '\$${_fmtShort(totalVal)}', t2, t0),
                  Container(width: 1, height: 28, color: border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  _miniStat('En positions', '\$${_fmtShort(p?.positionsValue ?? 0)}', t2, t0),
                  Container(width: 1, height: 28, color: border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  _miniStat('Profit / Perte', '${isUp ? '+' : ''}\$${_fmtShort(pnlVal.abs())} (${isUp ? '+' : ''}${pnlPct.toStringAsFixed(1)}%)', t2, pnlColor),
                ],
              ),
            ),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color t2, Color valColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: t2, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valColor, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  MARKET TICKER
  // ═══════════════════════════════════════════════════════

  Widget _buildMarketTicker(bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green, Color red) {
    final topSymbols = symbols.take(5).toList();
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: topSymbols.map((s) {
            final p = prices[s] ?? 0;
            final c = pcts[s] ?? 0;
            final up = c >= 0;
            return Expanded(
              child: Column(
                children: [
                  Text(s, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: t2, letterSpacing: 0.3)),
                  const SizedBox(height: 3),
                  Text(_fmtShort(p), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: t0, fontFamily: 'JetBrainsMono')),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: up ? green.withValues(alpha: 0.15) : red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${up ? '+' : ''}${c.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: up ? green : red)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildTabBar(bool isDark, Color accent, Color accentBg, Color accentBorder, Color t2) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000)),
      ),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final selected = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTab = i;
                HapticFeedback.lightImpact();
                _chartCtrl.forward(from: 0);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? accentBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: selected ? Border.all(color: accentBorder) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_tabIcons[i], size: 14, color: selected ? accent : t2),
                    const SizedBox(width: 4),
                    Text(
                      _tabLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : t2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  OVERVIEW TAB
  // ═══════════════════════════════════════════════════════

  Widget _buildOverview(bool isDark, Color bg1, Color border, Color accent, Color accentBg,
      Color accentBorder, Color t0, Color t1, Color t2, Color green, Color greenBg,
      Color red, Color redBg, Color femaleBg, Color maleBg, PortfolioData? p) {
    return Column(
      children: [
        _buildQuickActions(isDark, bg1, border, accent, accentBg, accentBorder, t0, t1, t2, green, greenBg, red, redBg),
        const SizedBox(height: 14),
        _buildAgentStatusBar(isDark, bg1, border, accent, t0, t1, t2, green),
        const SizedBox(height: 14),
        _buildPnLChart(p, isDark, bg1, border, accent, t0, t1, t2, green, red),
        const SizedBox(height: 14),
        _buildPerformanceCards(p, isDark, bg1, border, accent, t0, t1, t2, green, greenBg, red, redBg),
        const SizedBox(height: 14),
        _buildTeamBanner(isDark, bg1, border, accent, t0, t1, t2, green),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  QUICK ACTIONS — Premium Cards
  // ═══════════════════════════════════════════════════════

  Widget _buildQuickActions(bool isDark, Color bg1, Color border, Color accent, Color accentBg,
      Color accentBorder, Color t0, Color t1, Color t2, Color green, Color greenBg,
      Color red, Color redBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Actions rapides', 'Analysez le marché en un clic', isDark, t0, t1, accent),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _actionCard(
              icon: Icons.bar_chart_rounded, label: 'Analyser BTC',
              desc: 'Analyse technique complète', color: accent, bg: accentBg, border: accentBorder,
              isDark: isDark, onTap: () => _sendQuick('Analyse BTC maintenant'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _actionCard(
              icon: Icons.language_rounded, label: 'Marché global',
              desc: 'Tendance et sentiment', color: green, bg: greenBg, border: green.withValues(alpha: 0.25),
              isDark: isDark, onTap: () => _sendQuick('Tendance du marché'),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _actionCard(
              icon: Icons.shield_rounded, label: 'Évaluer risques',
              desc: 'Analyse des risques actuels', color: const Color(0xFFD4A84B), bg: const Color(0x14D4A84B),
              border: const Color(0xFFD4A84B).withValues(alpha: 0.25),
              isDark: isDark, onTap: () => _sendQuick('Évaluation des risques'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _actionCard(
              icon: Icons.psychology_rounded, label: ' Voir équipe',
              desc: '8 agents spécialisés', color: const Color(0xFF4A90D9), bg: const Color(0x1A4A90D9),
              border: const Color(0xFF4A90D9).withValues(alpha: 0.25),
              isDark: isDark, onTap: () => _showTeamSheet(context, isDark),
            )),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon, required String label, required String desc,
    required Color color, required Color bg, required Color border,
    required bool isDark, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
                  const SizedBox(height: 1),
                  Text(desc, style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  AGENT STATUS BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildAgentStatusBar(bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green) {
    final networkOk = isNetworkStable;
    final dataAge = DateTime.now().difference(lastPriceUpdate).inSeconds;
    final networkColor = networkOk ? green : const Color(0xFFE55353);
    final networkText = networkOk
        ? 'Marché connecté'
        : dataAge > 60
            ? '⚠️ Marché déconnecté (${dataAge}s)'
            : '⚠️ Données obsolètes (${dataAge}s)';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: networkColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: networkColor.withValues(alpha: _pulseAnim.value * 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('8 agents en veille', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t0)),
                const SizedBox(height: 1),
                Text(networkText, style: TextStyle(fontSize: 9, color: networkColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text('24/7', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PNL CHART
  // ═══════════════════════════════════════════════════════

  Widget _buildPnLChart(PortfolioData? p, bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green, Color red) {
    final points = _generateChartPoints(p);
    final maxVal = points.isEmpty ? 10000.0 : points.reduce(max);
    final minVal = points.isEmpty ? 0.0 : points.reduce(min);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Évolution du capital', 'Performance dans le temps', isDark, t0, t1, accent),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Color.fromRGBO(255, 255, 255, 0.06)
                    : Color.fromRGBO(0, 0, 0, 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  width: 0.5,
                ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
              ),
              child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _chartAnim,
                  builder: (_, __) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _PnLChartPainter(
                        points: points,
                        progress: _chartAnim.value,
                        minVal: minVal,
                        range: range,
                        gridColor: t2.withValues(alpha: 0.12),
                        upColor: green,
                        downColor: red,
                      ),
                    );
                  },
                ),
              ),
              if (points.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Début', style: TextStyle(fontSize: 8, color: t2)),
                      Text('Aujourd\'hui', style: TextStyle(fontSize: 8, color: t2)),
                    ],
                  ),
                ),
            ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<double> _generateChartPoints(PortfolioData? p) {
    if (p == null) return _demoCurve(10000, 0);
    final pts = <double>[];
    var bal = 10000.0;
    pts.add(bal);
    for (final t in p.walletHistory) {
      if (t.type == 'deposit') bal += t.amount;
      else bal -= t.amount;
      pts.add(bal);
    }
    for (final t in p.history) {
      if (t.side == 'sell') bal += t.qty * t.price;
      else if (t.side == 'buy') bal -= t.qty * t.price;
      pts.add(bal);
    }
    if (pts.length <= 2) return _demoCurve(bal, pts.last - pts.first);
    return pts;
  }

  List<double> _demoCurve(double base, double delta) {
    final pts = <double>[];
    final r = Random();
    var v = base - 500;
    for (int i = 0; i < 30; i++) {
      v += r.nextDouble() * 80 - 30 + delta / 30;
      v = v.clamp(base - 1500, base + 1500);
      pts.add(v);
    }
    pts.add(base + delta);
    return pts;
  }

  // ═══════════════════════════════════════════════════════
  //  PERFORMANCE CARDS
  // ═══════════════════════════════════════════════════════

  Widget _buildPerformanceCards(PortfolioData? p, bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green, Color greenBg, Color red, Color redBg) {
    final totalVal = p?.totalValue ?? 0;
    final deposits = p?.totalDeposits ?? 0;
    final pnlVal = totalVal - deposits;
    final isUp = pnlVal >= 0;
    final sellTrades = p?.history.where((t) => t.side == 'sell') ?? <TradeOrder>[];
    final winTrades = sellTrades.where((t) => (t.pnl ?? 0) > 0).length;
    final totalClosed = sellTrades.length;
    final winRate = totalClosed > 0 ? (winTrades / totalClosed * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Résumé de performance', 'Métriques clés du portefeuille', isDark, t0, t1, accent),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _metricCard('PnL Total', '${isUp ? '+' : ''}\$${_fmtShort(pnlVal.abs())}', isUp ? green : red, isUp ? greenBg : redBg, t2, t0, bg1, border, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Win Rate', '${winRate.toStringAsFixed(0)}%', winRate >= 50 ? green : red, winRate >= 50 ? greenBg : redBg, t2, t0, bg1, border, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _metricCard('Capital investi', '\$${_fmtShort(deposits)}', t0, const Color(0x00000000), t2, t0, bg1, border, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Trades exécutés', '$totalTrades', t0, const Color(0x00000000), t2, t0, bg1, border, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _metricCard('Frais totaux', '\$${_fmtShort(p?.totalFees ?? 0)}', red, const Color(0x00000000), t2, t0, bg1, border, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Trades gagnants', '$winTrades', green, const Color(0x00000000), t2, t0, bg1, border, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color valColor, Color valBg,
      Color t2, Color t0, Color bg1, Color border, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (valBg != const Color(0x00000000))
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: valBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: valColor.withValues(alpha: 0.3)),
                  ),
                ),
              if (valBg != const Color(0x00000000)) const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 8, color: t2, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 18, fontWeight: FontWeight.w800, color: valColor, height: 1)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TEAM BANNER
  // ═══════════════════════════════════════════════════════

  Widget _buildTeamBanner(bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green) {
    return GestureDetector(
      onTap: () => _showTeamSheet(context, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.06), accent.withValues(alpha: 0.01)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.groups_rounded, size: 22, color: accent.withValues(alpha: 0.6 + _pulseAnim.value * 0.4)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Équipe NOAH', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t0)),
                  const SizedBox(height: 2),
                  Text('8 agents spécialisés — Appuyez pour découvrir', style: TextStyle(fontSize: 10, color: t1)),
                ],
              ),
            ),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accent),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TEAM SHEET
  // ═══════════════════════════════════════════════════════

  void _showTeamSheet(BuildContext context, bool isDark) {
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            decoration: BoxDecoration(
              color: isDark
                  ? Color.fromRGBO(255, 255, 255, 0.06)
                  : Color.fromRGBO(0, 0, 0, 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: t2.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Équipe NOAH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
                    const Spacer(),
                    Text('${_agentIcons.length} agents', style: TextStyle(fontSize: 11, color: t2)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Appuyez pour voir les détails', style: TextStyle(fontSize: 11, color: t2)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _agentIcons.keys.map((name) => _teamMemberTile(name, isDark)).toList(),
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamMemberTile(String name, bool isDark) {
    final isFemale = _agentGenders[name] == 'female';
    final genderColor = isFemale ? (isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57)) : const Color(0xFF4A90D9);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Color.fromRGBO(255, 255, 255, 0.06)
                  : Color.fromRGBO(0, 0, 0, 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: genderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_agentIcons[name]!, size: 18, color: genderColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t0)),
                      const SizedBox(width: 6),
                      Text(_agentRoles[name]!, style: TextStyle(fontSize: 9, color: t2)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(_agentPersonalities[name]!, style: TextStyle(fontSize: 10, color: t1, height: 1.3)),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TRADES TAB
  // ═══════════════════════════════════════════════════════

  Widget _buildTrades(PortfolioData? p, bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green, Color greenBg, Color red, Color redBg) {
    final trades = p?.history ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Transactions', 'Historique des trades exécutés', isDark, t0, t1, accent),
        const SizedBox(height: 10),
        if (trades.isEmpty)
          _emptyState(t2, accent, accent)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.fromRGBO(255, 255, 255, 0.06)
                      : Color.fromRGBO(0, 0, 0, 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
                child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4),
                    ),
                    child: Row(
                      children: [
                        _tradeHdr('Actif', t2, flex: 2),
                        _tradeHdr('Type', t2, flex: 1),
                        _tradeHdr('Qté', t2, flex: 2),
                        _tradeHdr('Prix', t2, flex: 2),
                        _tradeHdr('PnL', t2, flex: 2),
                      ],
                    ),
                  ),
                  ...trades.take(10).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    final isBuy = t.side == 'buy';
                    final tPnl = t.pnl ?? 0;
                    final animP = (_chartAnim.value - i * 0.08).clamp(0.0, 1.0);

                    return Opacity(
                      opacity: animP,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - animP)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: border, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(t.sym, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t0, fontFamily: 'JetBrainsMono'))),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isBuy ? greenBg : redBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isBuy ? 'ACHAT' : 'VENTE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: isBuy ? green : red, letterSpacing: 0.3),
                                  ),
                                ),
                              ),
                              Expanded(flex: 2, child: Text(t.qty.toStringAsFixed(4), style: TextStyle(fontSize: 10, color: t1, fontFamily: 'JetBrainsMono'))),
                              Expanded(flex: 2, child: Text('\$${t.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, color: t1, fontFamily: 'JetBrainsMono'))),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tPnl != 0 ? '${tPnl >= 0 ? '+' : ''}\$${tPnl.toStringAsFixed(2)}' : '-',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tPnl >= 0 ? green : red, fontFamily: 'JetBrainsMono'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (trades.length > 10)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text('+${trades.length - 10} trades supplémentaires', style: TextStyle(fontSize: 10, color: t2)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _tradeHdr(String label, Color t2, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(label, style: TextStyle(fontSize: 9, color: t2, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _emptyState(Color t2, Color accent, Color border) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t2.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, size: 32, color: t2.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Aucun trade pour le moment', style: TextStyle(fontSize: 13, color: t2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text('Demandez à NOAH d\'analyser le marché', style: TextStyle(fontSize: 10, color: t2.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PERFORMANCE TAB
  // ═══════════════════════════════════════════════════════

  Widget _buildPerformance(PortfolioData? p, bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green, Color red) {
    final timeFrames = ['7j', '30j', '90j', 'Tout'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Analyse détaillée', 'Performances par période', isDark, t0, t1, accent),
        const SizedBox(height: 10),
        Row(
          children: List.generate(timeFrames.length, (i) {
            final selected = i == _perfTimeframe;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() {
                  _perfTimeframe = i;
                  HapticFeedback.lightImpact();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: selected ? Border.all(color: accent.withValues(alpha: 0.3)) : null,
                  ),
                  child: Text(timeFrames[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? accent : t2, letterSpacing: 0.3)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        _buildPerfGrid(p, isDark, bg1, border, accent, t0, t1, t2, green, red),
      ],
    );
  }

  Widget _buildPerfGrid(PortfolioData? p, bool isDark, Color bg1, Color border, Color accent,
      Color t0, Color t1, Color t2, Color green, Color red) {
    final totalVal = p?.totalValue ?? 0;
    final deposits = p?.totalDeposits ?? 0;
    final pnlVal = totalVal - deposits;
    final isUp = pnlVal >= 0;
    final buys = p?.history.where((t) => t.side == 'buy').length ?? 0;
    final sellTrades = p?.history.where((t) => t.side == 'sell') ?? <TradeOrder>[];
    final winSells = sellTrades.where((t) => (t.pnl ?? 0) > 0).length;
    final loseSells = sellTrades.where((t) => (t.pnl ?? 0) < 0).length;
    final totalT = p?.history.length ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Color.fromRGBO(255, 255, 255, 0.06)
                : Color.fromRGBO(0, 0, 0, 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              width: 0.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: Column(
        children: [
          _perfRow('Capital initial', '\$${_fmtShort(deposits)}', 'Valeur actuelle', '\$${_fmtShort(totalVal)}', t0, t1, t0, t1),
          const SizedBox(height: 14),
          _perfRow('Gain / Perte', '${isUp ? '+' : ''}\$${_fmtShort(pnlVal.abs())}', 'ROI', '${isUp ? '+' : ''}${((pnlVal / deposits) * 100).toStringAsFixed(1)}%', isUp ? green : red, t1, isUp ? green : red, t1),
          const SizedBox(height: 14),
          _perfRow('Trades gagnants', '$winSells', 'Trades perdants', '$loseSells', green, t1, red, t1),
          const SizedBox(height: 14),
          _perfRow('Total trades', '$totalT', 'Positions ouvertes', '${p?.positions.length ?? 0}', t0, t1, t0, t1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _perfRow(String l1, String v1, String l2, String v2, Color c1, Color t1, Color c2, Color t1b) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l1, style: TextStyle(fontSize: 9, color: t1, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 4),
              Text(v1, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.w800, color: c1)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l2, style: TextStyle(fontSize: 9, color: t1, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 4),
              Text(v2, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.w800, color: c2)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  COMMON
  // ═══════════════════════════════════════════════════════

  Widget _sectionTitle(String title, String subtitle, bool isDark, Color t0, Color t1, Color accent) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t0, letterSpacing: -0.2)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: t1)),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }

  String _fmtShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}

// ═══════════════════════════════════════════════════════════
//  PNL CHART PAINTER
// ═══════════════════════════════════════════════════════════

class _PnLChartPainter extends CustomPainter {
  final List<double> points;
  final double progress;
  final double minVal;
  final double range;
  final Color gridColor;
  final Color upColor;
  final Color downColor;

  _PnLChartPainter({
    required this.points,
    required this.progress,
    required this.minVal,
    required this.range,
    required this.gridColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final h = size.height;
    final w = size.width;
    final count = (points.length * progress).ceil().clamp(2, points.length);
    final visible = points.sublist(0, count);

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(Offset(0, h * i / 4), Offset(w, h * i / 4), gridPaint);
    }

    final stepX = w / (visible.length - 1).clamp(1, double.infinity);

    double yVal(int i) => h - ((visible[i] - minVal) / range * h * 0.85 + h * 0.075);

    for (int i = 1; i < visible.length; i++) {
      final x0 = (i - 1) * stepX;
      final x1 = i * stepX;
      final y0 = yVal(i - 1);
      final y1 = yVal(i);
      final goingUp = visible[i] >= visible[i - 1];
      final segColor = goingUp ? upColor : downColor;

      final segPath = Path()
        ..moveTo(x0, y0)
        ..lineTo(x1, y1)
        ..lineTo(x1, h)
        ..lineTo(x0, h)
        ..close();
      canvas.drawPath(segPath, Paint()..color = segColor.withValues(alpha: 0.08));
    }

    for (int i = 1; i < visible.length; i++) {
      final x0 = (i - 1) * stepX;
      final x1 = i * stepX;
      final y0 = yVal(i - 1);
      final y1 = yVal(i);
      final goingUp = visible[i] >= visible[i - 1];
      final segColor = goingUp ? upColor : downColor;

      canvas.drawLine(
        Offset(x0, y0), Offset(x1, y1),
        Paint()
          ..color = segColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (visible.isNotEmpty) {
      final lastX = (visible.length - 1) * stepX;
      final lastY = yVal(visible.length - 1);
      final lastUp = visible.length > 1 && visible.last >= visible[visible.length - 2];
      final dotColor = lastUp ? upColor : downColor;
      canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = dotColor);
      canvas.drawCircle(Offset(lastX, lastY), 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _PnLChartPainter old) => old.progress != progress || old.points != points;
}
