import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NoahBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const NoahBottomNav({super.key, required this.currentIndex, required this.onTap});

  static final _items = [
    ('CORE', Icons.dashboard_outlined),
    ('CHAT', Icons.chat_bubble_outline),
    ('TRADE', Icons.bar_chart_outlined),
    ('PORTFOLIO', Icons.account_balance_wallet_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x1A1E1E1E)
                : const Color(0x1AFFFFFF),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0x22FFFFFF)
                    : const Color(0x22000000),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(_items.length, (i) {
                final active = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Container(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _items[i].$2,
                            size: 20,
                            color: active ? accent : t2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].$1,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: active ? accent : t2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
