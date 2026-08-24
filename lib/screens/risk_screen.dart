import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import '../theme/noah_theme.dart';
import '../theme/glass_theme.dart';

class RiskScreen extends StatelessWidget {
  final RiskProvider risk;
  final PortfolioProvider portfolio;

  const RiskScreen({super.key, required this.risk, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final bg3 = isDark ? const Color(0xFF323232) : const Color(0xFFE8E3D8);
    final bg4 = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFDDD6C8);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = accent.withOpacity( 0.1);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final greenBg = green.withOpacity( 0.1);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final redBg = red.withOpacity( 0.1);

    final rm = portfolio.riskManager;
    final perf = portfolio.analyzer;
    final cbActive = portfolio.circuitBreakerActive;
    final rmData = rm.toJson();

    return Container(
      color: bg0,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Risk status + Kelly score
          Row(
            children: [
              Expanded(
                child: _statusCard(
                  rmData['riskLabel'] as String,
                  'Niveau de risque',
                  (rmData['riskLabel'] == 'CRITIQUE') ? red : (rmData['riskLabel'] == 'ÉLEVÉ' ? const Color(0xFFD4A84B) : green),
                  bg1, border, t2, isDark, (rmData['exposurePct'] as double) / 100,
                ),
              ),
              const SizedBox(width: 10),
              if (cbActive)
                GestureDetector(
                  onTap: () => portfolio.resetCircuitBreaker(),
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: redBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: red.withOpacity( 0.3))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, size: 18, color: red),
                        Text('Reset', style: TextStyle(fontSize: 8, color: red, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Risk metrics grid
          _section('Métriques de Risque', bg1, border, accent, t2, isDark, [
            _metricRow('Exposition', '${(rmData['exposurePct'] as double).toStringAsFixed(1)}%', 'Limite: 70%', t0, t2, accent),
            _metricRow('Drawdown Max', '${(rmData['maxDrawdown'] as double).toStringAsFixed(1)}%', 'Limite: 30%', t0, t2, (rmData['maxDrawdown'] as double) > 15 ? red : green),
            _metricRow('Risque Corrélation', '${((rmData['correlationRisk'] as double) * 100).toStringAsFixed(0)}%', 'Limite: 40%', t0, t2, (rmData['correlationRisk'] as double) > 0.4 ? red : green),
            _metricRow('Kelly Suggéré', '${((rmData['kellySuggested'] as double) * 100).toStringAsFixed(1)}%', 'Taille optimale par trade', t0, t2, accent),
          ]),
          const SizedBox(height: 10),
          // Daily loss + Circuit breaker
          _section('Protections', bg1, border, accent, t2, isDark, [
            _metricRow('Perte du jour', '\$${(portfolio.dailyLoss).toStringAsFixed(2)}', circuitBreakerStatus(portfolio.dailyLoss, portfolio.data.totalDeposits), t0, t2, portfolio.dailyLoss > 0 ? red : green),
            _toggleRow('Circuit Breaker', 'Arrêt si perte > ${risk.maxDailyLossPct.toInt()}%', risk.circuitBreaker, (v) => risk.setCircuitBreaker(v), accent, bg3, t0, t2),
          ]),
          const SizedBox(height: 10),

          // Performance metrics
          if (perf != null && perf.totalTrades > 0) ...[
            _section('Performance', bg1, border, accent, t2, isDark, [
              _metricRow('Win Rate', '${(perf.winRate * 100).toStringAsFixed(1)}%', '${perf.wins} G / ${perf.losses} P', t0, t2, perf.winRate > 0.5 ? green : red),
              _metricRow('Avg Gain', '\$${perf.avgWin.toStringAsFixed(2)}', 'Avg Perte: \$${perf.avgLoss.toStringAsFixed(2)}', t0, t2, perf.avgWin > perf.avgLoss ? green : red),
              _metricRow('Profit Factor', perf.profitFactor.toStringAsFixed(2), '>1.5 = bon', t0, t2, perf.profitFactor > 1.5 ? green : red),
              _metricRow('Expectancy', '\$${perf.expectancy.toStringAsFixed(2)}', 'Espérance par trade', t0, t2, perf.expectancy > 0 ? green : red),
              _metricRow('Sharpe Ratio', perf.sharpeRatio.toStringAsFixed(2), '>1 = bon, >2 = excellent', t0, t2, perf.sharpeRatio > 1 ? green : red),
              _metricRow('Sortino Ratio', perf.sortinoRatio.toStringAsFixed(2), 'Downside risk ajusté', t0, t2, perf.sortinoRatio > 1 ? green : red),
            ]),
            const SizedBox(height: 10),
          ],

          // Portfolio stats
          _section('Statistiques Portefeuille', bg1, border, accent, t2, isDark, [
            _metricRow('Total Trades', '${perf?.totalTrades ?? 0}', 'Dont ${perf?.wins ?? 0} gagnants', t0, t2, accent),
            _metricRow('Plus gros Gain', '\$${portfolio.data.bestTrade.toStringAsFixed(2)}', 'Best trade', t0, t2, green),
            _metricRow('Plus grosse Perte', '\$${portfolio.data.worstTrade.toStringAsFixed(2)}', 'Worst trade', t0, t2, red),
            _metricRow('P&L Non Réalisé', '\$${(rmData['unrealizedPnl'] as double).toStringAsFixed(2)}', '${(rmData['unrealizedPnlPct'] as double).toStringAsFixed(1)}%', t0, t2, (rmData['unrealizedPnl'] as double) >= 0 ? green : red),
          ]),
          const SizedBox(height: 10),

          // Limits
          _section('Limites', bg1, border, accent, t2, isDark, [
            _riskSlider('Taille max / trade', '${risk.maxTradePct.toInt()}%', risk.maxTradePct, 1, 50, accent, bg3, t0, t2, (v) => risk.setMaxTradePct(v)),
            _riskSlider('Stop loss défaut', '${risk.stopLossPct.toInt()}%', risk.stopLossPct, 1, 20, red, bg3, t0, t2, (v) => risk.setStopLossPct(v)),
            _riskSlider('Perte journalière max', '${risk.maxDailyLossPct.toInt()}%', risk.maxDailyLossPct, 5, 50, red, bg3, t0, t2, (v) => risk.setMaxDailyLossPct(v)),
            const SizedBox(height: 8),
            _sectionLine(bg3),
            _toggleRow('Auto-trading', 'Exécution automatique des signaux', risk.autoTrade, (v) => risk.setAutoTrade(v), accent, bg3, t0, t2),
            _toggleRow('Circuit Breaker', "Arrêt d'urgence si perte > limite", risk.circuitBreaker, (v) => risk.setCircuitBreaker(v), accent, bg3, t0, t2),
          ]),
          const SizedBox(height: 10),
          // Lock button
          GestureDetector(
            onTap: () => portfolio.closeAll(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Lock All Positions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String circuitBreakerStatus(double loss, double deposits) {
    if (loss <= 0) return 'Aucune perte';
    final pct = deposits > 0 ? loss / deposits * 100 : 0;
    return '$pct% du capital';
  }

  Widget _statusCard(String label, String subtitle, Color color, Color bg1, Color border, Color t2, bool isDark, double fill) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity( 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(color: bg1.withOpacity( 0.3), borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fill.clamp(0.0, 1.0),
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, String sub, Color t0, Color t2, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t0)),
              Text(sub, style: TextStyle(fontSize: 9, color: t2)),
            ],
          ),
          Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w700, color: valColor)),
        ],
      ),
    );
  }

  Widget _section(String title, Color bg1, Color border, Color accent, Color t2, bool isDark, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg1.withOpacity( isDark ? 0.5 : 0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLine(Color bg3) {
    return Container(height: 1, color: bg3.withOpacity( 0.3), margin: const EdgeInsets.symmetric(vertical: 4));
  }

  Widget _riskSlider(String label, String value, double val, double min, double max, Color valColor, Color bg3, Color t0, Color t2, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
                  Text('% du portefeuille', style: TextStyle(fontSize: 10, color: t2)),
                ],
              ),
              Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w600, color: valColor)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: valColor,
              inactiveTrackColor: bg3,
              thumbColor: valColor,
              overlayColor: valColor.withOpacity( 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: val, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, String sub, bool value, ValueChanged<bool> onChanged, Color accent, Color bg3, Color t0, Color t2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              Text(sub, style: TextStyle(fontSize: 10, color: t2)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
            inactiveTrackColor: bg3,
          ),
        ],
      ),
    );
  }
}
