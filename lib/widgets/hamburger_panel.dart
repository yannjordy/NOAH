import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/providers.dart';

class HamburgerPanel extends StatelessWidget {
  final bool isOpen;
  final double animValue;
  final int activeTab;
  final VoidCallback onClose;
  final void Function(int) onGoTab;
  final ChatProvider chatProvider;
  final AuthProvider authProvider;

  const HamburgerPanel({
    super.key,
    this.isOpen = false,
    this.animValue = 0.0,
    required this.activeTab,
    required this.onClose,
    required this.onGoTab,
    required this.chatProvider,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = isDark ? const Color(0x1AC2A878) : const Color(0x1AB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final t3 = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final redBg = isDark ? const Color(0x14E07060) : const Color(0x14B8453A);
    final glassBg = isDark
        ? const Color(0x1A1E1E1E)
        : const Color(0x1AFFFFFF);
    final glassBorder = isDark
        ? const Color(0x22FFFFFF)
        : const Color(0x22000000);

    final items = [
      ('NOAH Core', 'Dashboard global & résumé marché', 0),
      ('NOAH Chat', 'Analyse IA & décisions trading', 1),
      ('Trading Hub', 'Positions, ordres, signaux IA', 2),
      ('Connections', 'IA providers & Binance API', 3),
      ('Portfolio', 'Balance, P&L, historique', 4),
      ('Risk Engine', 'Limites, sécurité, stop trading', 5),
      ('Settings', 'Compte, thème, IA, notifications', 6),
      ('About NOAH', 'Version, vision, support', 7),
    ];

    return Positioned(
      left: -300 + 300 * animValue,
      top: 0,
      bottom: 0,
      width: 300,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Color.fromRGBO(24, 24, 24, 0.92)
                  : Color.fromRGBO(252, 250, 245, 0.92),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              border: Border(
                right: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 50, 18, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: glassBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('NOAH', style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 28,
                            letterSpacing: 4,
                            color: accent,
                            shadows: [
                              Shadow(color: accent.withValues(alpha: 0.3), blurRadius: 8),
                            ],
                          )),
                          const SizedBox(width: 10),
                          Image.asset('assets/logo-remove.png', height: 32, width: 32,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text('Neural Operator for Autonomous Holdings',
                            style: TextStyle(fontSize: 11, color: t2, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      ...items.map((item) {
                        final active = item.$3 == activeTab;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: GestureDetector(
                            onTap: () {
                              onGoTab(item.$3);
                              onClose();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                              decoration: BoxDecoration(
                                color: active ? accentBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                border: Border(
                                  left: BorderSide(
                                    color: active ? accent : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: active
                                          ? accent.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                    ),
                                    child: Center(child: _menuIcon(item.$3, active ? accent : t1)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.$1, style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: active ? t0 : t1,
                                        )),
                                        const SizedBox(height: 1),
                                        Text(item.$2, style: TextStyle(
                                          fontSize: 11,
                                          color: t2,
                                        )),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 16, color: t3),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(height: 1, color: glassBorder),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
                        child: Text('Historique', style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: t2,
                        )),
                      ),
                      // New chat button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GestureDetector(
                          onTap: () {
                            chatProvider.newChat();
                            onGoTab(1);
                            onClose();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              border: Border.all(color: glassBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 16, color: accent),
                                const SizedBox(width: 8),
                                Text('Nouvelle conversation', style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // History list
                      _buildHistoryList(context, isDark, t0, t2, t3, red, redBg, accent, accentBg, glassBorder),
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

  Widget _buildHistoryList(
      BuildContext context, bool isDark, Color t0, Color t2, Color t3,
      Color red, Color redBg, Color accent, Color accentBg, Color glassBorder) {
    final sessions = chatProvider.getSessions();
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Aucune conversation\nCommencez à discuter avec NOAH',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: t2, height: 1.5)),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        itemCount: sessions.length > 20 ? 20 : sessions.length,
        itemBuilder: (context, i) {
          final s = sessions[i];
          final isActive = s.id == chatProvider.currentSessionId;
          final dt = DateTime.fromMillisecondsSinceEpoch(s.date);
          final dateStr = '${dt.day}/${dt.month < 10 ? '0${dt.month}' : dt.month}';
          final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          return GestureDetector(
            onTap: () {
              chatProvider.loadSession(s.id);
              onGoTab(1);
              onClose();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? accentBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.chat_bubble_outline, size: 16, color: t2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t0),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 1),
                        Text('$dateStr à $timeStr · ${s.msgs.length} msg',
                            style: TextStyle(fontSize: 10, color: t2)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => chatProvider.deleteSession(s.id),
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.close, size: 14, color: t3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _menuIcon(int tab, Color color) {
    final icons = {
      0: Icons.dashboard_outlined,
      1: Icons.chat_bubble_outline,
      2: Icons.bar_chart_outlined,
      3: Icons.link,
      4: Icons.account_balance_wallet_outlined,
      5: Icons.shield_outlined,
      6: Icons.settings_outlined,
      7: Icons.info_outline,
    };
    return Icon(icons[tab] ?? Icons.circle_outlined, size: 20, color: color);
  }
}
