import 'package:flutter/material.dart';
import '../models/models.dart';
import 'widget_card.dart';

class PortfolioWidget extends StatelessWidget {
  final PortfolioData? data;

  const PortfolioWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);

    final usdt = data?.usdt ?? 10000.0;
    final posVal = data?.positionsValue ?? 0.0;
    final total = usdt + posVal;
    final deposits = data?.totalDeposits ?? 0.0;
    final pnl = total - deposits;
    final pnlPct = deposits > 0 ? (pnl / deposits) * 100 : 0.0;
    final posCount = data?.positions.length ?? 0;

    return WidgetCard(
      title: 'Portefeuille',
      subtitle: 'Solde & positions',
      icon: Icons.account_balance_wallet,
      iconColor: const Color(0xFFC2A878),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: t0,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                pnl >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 10,
                color: pnl >= 0 ? green : red,
              ),
              const SizedBox(width: 3),
              Text(
                '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)} (${pnlPct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w600,
                  color: pnl >= 0 ? green : red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('USDT', '\$${usdt.toStringAsFixed(0)}', t2, t0),
              const SizedBox(width: 16),
              _miniStat('Positions', '$posCount', t2, t0),
              const SizedBox(width: 16),
              _miniStat('Dépôts', '\$${deposits.toStringAsFixed(0)}', t2, t0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color t2, Color t0) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: t2)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t0, fontFamily: 'JetBrainsMono')),
      ],
    );
  }
}
