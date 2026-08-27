import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NoahBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final int pendingCount;

  const NoahBottomNav({super.key, required this.currentIndex, required this.onTap, this.pendingCount = 0});

  static const _items = [
    ('CORE', Icons.dashboard_outlined),
    ('CHAT', Icons.chat_bubble_outline),
    ('TRADE', Icons.bar_chart_outlined),
    ('NEWS', Icons.newspaper_outlined),
    ('PORTFOLIO', Icons.account_balance_wallet_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Color.fromRGBO(18, 18, 18, 0.88)
                : Color.fromRGBO(247, 244, 238, 0.90),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                width: 0.5,
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                _items[i].$2,
                                size: 20,
                                color: active ? accent : t2,
                              ),
                              if (i == 0 && pendingCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE07060),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$pendingCount',
                                      style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
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
