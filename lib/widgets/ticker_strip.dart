import 'package:flutter/material.dart';
import '../models/models.dart';

String fmt(double v) {
  if (v >= 1000) return v.toStringAsFixed(0);
  if (v >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(4);
}

class TickerStrip extends StatelessWidget {
  final String currentSymbol;
  final void Function(String) onSelect;
  final bool isDark;

  const TickerStrip({
    super.key,
    required this.currentSymbol,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);

    return Container(
      height: 30,
      color: bg2,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: symbols.map((s) {
          final active = s == currentSymbol;
          final p = prices[s] ?? 0;
          final pc = pcts[s] ?? 0;
          final up = pc >= 0;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active ? bg2 : null,
                border: Border(right: BorderSide(color: border)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t1)),
                  const SizedBox(width: 5),
                  Text(fmt(p), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t0, fontFamily: 'JetBrainsMono')),
                  const SizedBox(width: 5),
                  Text(
                    '${up ? '+' : ''}${pc.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: up ? green : red, fontFamily: 'JetBrainsMono'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
