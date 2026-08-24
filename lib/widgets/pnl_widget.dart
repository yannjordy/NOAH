import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'widget_card.dart';

class PnLWidget extends StatelessWidget {
  final PortfolioData? data;

  const PnLWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);

    final usdt = data?.usdt ?? 10000.0;
    final posVal = data?.positionsValue ?? 0.0;
    final total = usdt + posVal;
    final deposits = data?.totalDeposits ?? 0.0;
    final pnl = total - deposits;
    final pnlPct = deposits > 0 ? (pnl / deposits) * 100 : 0.0;

    // Per-position P&L
    final positions = data?.positions ?? [];
    final posPnLs = positions.map((p) {
      final cur = prices[p.sym] ?? p.entry;
      final pnl = (cur - p.entry) * p.qty;
      final pnlPct = p.entry > 0 ? ((cur - p.entry) / p.entry) * 100 : 0.0;
      return _PosPnL(sym: p.sym, pnl: pnl, pnlPct: pnlPct);
    }).toList();

    final isPositive = pnl >= 0;

    return WidgetCard(
      title: 'Gains / Pertes',
      subtitle: 'Réalisé + Non réalisé',
      icon: isPositive ? Icons.trending_up : Icons.trending_down,
      iconColor: isPositive ? green : red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrainsMono',
                  color: isPositive ? green : red,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${isPositive ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: isPositive ? green.withValues(alpha: 0.7) : red.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini bar for visual
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  Expanded(
                    flex: max(1, (pnlPct * 10).round().abs()),
                    child: Container(color: isPositive ? green : red),
                  ),
                  Expanded(
                    flex: max(1, 30 - (pnlPct * 10).round().abs()),
                    child: Container(color: t2.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Positions',
            style: TextStyle(fontSize: 8, color: t2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (posPnLs.isEmpty)
            Text('Aucune position ouverte', style: TextStyle(fontSize: 9, color: t2))
          else
            ...posPnLs.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Text(p.sym, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'JetBrainsMono', color: t0)),
                  const Spacer(),
                  Text(
                    '${p.pnl >= 0 ? '+' : ''}\$${p.pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w500,
                      color: p.pnl >= 0 ? green : red,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${p.pnl >= 0 ? '+' : ''}${p.pnlPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 8,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w600,
                        color: p.pnl >= 0 ? green : red,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _PosPnL {
  final String sym;
  final double pnl;
  final double pnlPct;
  _PosPnL({required this.sym, required this.pnl, required this.pnlPct});
}
