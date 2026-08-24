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
      ('Backtesting', 'Tester stratégies sur données historiques', 8),
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
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              border: Border(
                right: BorderSide(color: glassBorder, width: 0.5),
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
                              Shadow(color: accent.withOpacity( 0.3), blurRadius: 8),
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
                                          ? accent.withOpacity( 0.15)
                                          : Colors.transparent,
                                    ),
                                    child: Center(child: Icon(_menuIcon(item.$3, active ? accent : t1), size: 18, color: active ? accent : t1)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: accentBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: accent.withOpacity( 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_comment_outlined, size: 16, color: accent),
                                const SizedBox(width: 10),
                                Text('Nouveau chat', style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: accent,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: glassBorder)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentBg,
                          border: Border.all(color: accent.withOpacity( 0.3)),
                        ),
                        child: Icon(Icons.person, size: 18, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(authProvider.displayName, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: t0,
                            )),
                            Text(authProvider.isLoggedIn ? authProvider.displayEmail : 'Mode démo',
                                style: TextStyle(fontSize: 11, color: t2)),
                          ],
                        ),
                      ),
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

  IconData _menuIcon(int index, Color color) {
    final icons = [
      Icons.dashboard_outlined,
      Icons.chat_bubble_outline,
      Icons.bar_chart_outlined,
      Icons.wifi_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.shield_outlined,
      Icons.settings_outlined,
      Icons.info_outline,
      Icons.science_outlined,
    ];
    return index < icons.length ? icons[index] : Icons.circle;
  }
}