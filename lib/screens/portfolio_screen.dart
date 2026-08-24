import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/noah_theme.dart';
import '../widgets/glass_portfolio_charts.dart';
import '../theme/glass_theme.dart';

class PortfolioScreen extends StatelessWidget {
  final PortfolioProvider portfolio;

  const PortfolioScreen({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final bg3 = isDark ? const Color(0xFF323232) : const Color(0xFFE8E3D8);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = isDark ? const Color(0x1AC2A878) : const Color(0x1AB08D57);
    final accentBorder = isDark ? const Color(0x2EC2A878) : const Color(0x33B08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final t3 = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final greenBg = isDark ? const Color(0x144CAF8E) : const Color(0x142E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final redBg = isDark ? const Color(0x14E07060) : const Color(0x14B8453A);
    final amber = isDark ? const Color(0xFFD4A84B) : const Color(0xFFA67C2E);
    final amberBg = isDark ? const Color(0x14D4A84B) : const Color(0x14A67C2E);

    final data = portfolio.data;
    final pnl = data.pnl;
    final totalVal = data.totalValue;
    final pnlPct = data.pnlPct;
    final portPnlPct = portfolio.pnlPercent;
    final isPnlUp = pnl >= 0;
    final isPortUp = portPnlPct >= 0;

    final colors = [accent, isDark ? const Color(0xFFD4A84B) : const Color(0xFFA67C2E), green, red, t3];
    final segs = <({String label, double val, Color c})>[];
    for (int i = 0; i < data.positions.length; i++) {
      final p = data.positions[i];
      segs.add((label: p.sym, val: p.qty * (prices[p.sym] ?? 0), c: colors[i % colors.length]));
    }
    segs.add((label: 'USDT', val: data.usdt, c: t3));

    return Container(
      color: bg0,
      child: ListenableBuilder(
        listenable: portfolio,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Disclaimer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: amberBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: amber.withOpacity( 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: amber),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Portefeuille fictif — Les montants sont virtuels, les résultats basés sur des données de marché réelles.',
                        style: TextStyle(fontSize: 9, color: amber, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Disponible card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg1,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: border),
                  boxShadow: NoahTheme.shadowMd(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Argent disponible (retirable)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t2)),
                        const Spacer(),
                        // ROI badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPortUp ? greenBg : redBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${isPortUp ? '+' : ''}${portPnlPct.toStringAsFixed(2)}% ROI',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isPortUp ? green : red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(fmt(data.usdt), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 30, fontWeight: FontWeight.w700, color: t0, letterSpacing: -1.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPnlUp ? greenBg : redBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isPnlUp ? '↑' : '↓', style: TextStyle(fontSize: 12, color: isPnlUp ? green : red)),
                              const SizedBox(width: 4),
                              Text(
                                '${isPnlUp ? '+' : ''}${fmt(pnl)} (${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)',
                                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: isPnlUp ? green : red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Total: ${fmt(totalVal)}', style: TextStyle(fontSize: 11, color: t2, fontFamily: 'JetBrainsMono')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _SparklinePainter(totalVal: totalVal, isUp: isPnlUp, isDark: isDark, color: isPnlUp ? green : red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Wallet actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDepositDialog(context, portfolio, isDark, bg1, bg2, borderMd, accent, t0, t2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: bg1,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 14, color: accent),
                            const SizedBox(width: 5),
                            Text('Déposer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showResetConfirm(context, portfolio, isDark, bg1, t0, t2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: bg1,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 14, color: t2),
                            const SizedBox(width: 5),
                            Text('Réinitialiser', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Allocation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg1,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border),
                  boxShadow: NoahTheme.shadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text('Allocation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: segs.map((s) => Expanded(flex: s.val.toInt() + 1, child: Container(color: s.c))).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: segs.map((s) {
                        final pct = totalVal > 0 ? (s.val / totalVal * 100) : 0.0;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 7, height: 7, decoration: BoxDecoration(color: s.c, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('${s.label} ${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: t1)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Equity curve
              GlassEquityCurve(
                dailyReturns: data.dailyReturns,
                initialCapital: data.totalDeposits > 0 ? data.totalDeposits : data.initialUsdt,
                currentCapital: totalVal,
              ),
              const SizedBox(height: 10),
              // Pie chart allocation
              GlassTheme.cardFlat(
                context: context,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text('Répartition', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassPieChart(
                      segments: segs.map((s) => (label: s.label, value: s.val, color: s.c)).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Positions
              ...data.positions.map((pos) => _positionCard(context, pos, isDark, bg1, bg2, bg3, border, t0, t2, green, greenBg, red, redBg, accent)),
              const SizedBox(height: 10),
              // USDT balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg1,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border),
                  boxShadow: NoahTheme.shadow(isDark),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: accentBorder),
                      ),
                      child: const Center(child: Text('\$', style: TextStyle(fontSize: 16, color: Color(0xFFB08D57)))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USDT Disponible', style: TextStyle(fontSize: 11, color: t2)),
                          Text(fmt(data.usdt), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 18, fontWeight: FontWeight.w700, color: t0)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        '${totalVal > 0 ? (data.usdt / totalVal * 100).toStringAsFixed(1) : '0'}%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Stats
              Row(
                children: [
                  _statCard('Total déposé', fmt(data.totalDeposits), t2, t0, bg2),
                  const SizedBox(width: 6),
                  _statCard('ROI Total', '${portPnlPct >= 0 ? '+' : ''}${portPnlPct.toStringAsFixed(2)}%', t2, isPortUp ? green : red, bg2),
                  const SizedBox(width: 6),
                  _statCard('Positions', '${data.positions.length}', t2, t0, bg2),
                ],
              ),
              const SizedBox(height: 14),
              // Wallet history
              Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Activité du portefeuille', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 8),
              ...data.walletHistory.take(5).map((t) => _walletItem(t, isDark, bg2, t0, t2, green, greenBg, red, redBg, accent)),
              const SizedBox(height: 14),
              // Trade history
              Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Historique des trades', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 8),
              ...data.history.take(8).map((o) => _historyItem(o, isDark, bg2, t0, t2, green, greenBg, red, redBg)),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, Color t2, Color valColor, Color bg2) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: valColor)),
          ],
        ),
      ),
    );
  }

  Widget _walletItem(WalletTransaction t, bool isDark, Color bg2, Color t0, Color t2, Color green, Color greenBg, Color red, Color redBg, Color accent) {
    final isDeposit = t.type == 'deposit';
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isDeposit ? greenBg : redBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: isDeposit ? green : red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t0)),
                Text(t.time, style: TextStyle(fontSize: 9, color: t2)),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'}${fmt(t.amount)}',
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: isDeposit ? green : red),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context, PortfolioProvider portfolio, bool isDark, Color bg1, Color bg2, Color borderMd, Color accent, Color t0, Color t2) {
    final ctrl = TextEditingController(text: '1000');
    GlassTheme.showModal(
      context: context,
      title: 'Dépôt fictif',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajoutez de l\'argent fictif à votre portefeuille de démonstration.',
                style: TextStyle(fontSize: 11, color: t2)),
            const SizedBox(height: 12),
            Row(
              children: [100, 500, 1000, 5000].map((v) {
                return Expanded(
                  child: GlassTheme.button(
                    context: context,
                    onTap: () => ctrl.text = v.toString(),
                    child: Text('${v}\$', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: bg2.withOpacity( 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderMd),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.w600, color: t0),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(fontSize: 14, color: t2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassTheme.button(
              context: context,
              isPrimary: true,
              onTap: () {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt > 0) {
                  portfolio.deposit(amt);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter les fonds', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showResetConfirm(BuildContext context, PortfolioProvider portfolio, bool isDark, Color bg1, Color t0, Color t2) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Réinitialiser', style: TextStyle(color: t0)),
        content: Text('Cela effacera toutes les positions et l\'historique. Revenir à 10 000 USDT fictifs.', style: TextStyle(color: t2, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: TextStyle(color: t2))),
          TextButton(
            onPressed: () {
              portfolio.reset();
              Navigator.pop(ctx);
            },
            child: Text('Réinitialiser', style: TextStyle(color: const Color(0xFFE07060))),
          ),
        ],
      ),
    );
  }

  Widget _positionCard(
      BuildContext context, Position pos, bool isDark, Color bg1, Color bg2, Color bg3, Color border, Color t0, Color t2,
      Color green, Color greenBg, Color red, Color redBg, Color accent) {
    final cur = prices[pos.sym] ?? 0;
    final pnlP = pos.qty * (cur - pos.entry);
    final up = pnlP >= 0;
    final mn = pos.entry * 0.88;
    final mx = pos.entry * 1.12;
    final rng = mx - mn;
    final entryFrac = ((pos.entry - mn) / rng * 100).clamp(0, 100);
    final curFrac = ((cur.clamp(mn, mx) - mn) / rng * 100).clamp(0, 100);
    final hasSL = pos.stopLoss != null;
    final hasTP = pos.takeProfit != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      child: GestureDetector(
        onTap: () => _showPositionEditDialog(context, pos, isDark, bg1, bg2, border, accent, t0, t2, green, red),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: bg1,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: border),
            boxShadow: NoahTheme.shadow(isDark),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: up ? greenBg : redBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(pos.sym.substring(0, 3),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: up ? green : red)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${pos.sym}/USDT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t0)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showPositionEditDialog(context, pos, isDark, bg1, bg2, border, accent, t0, t2, green, red),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: bg2,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.edit, size: 12, color: t2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text('${pos.qty.toStringAsFixed(4)} ${pos.sym} · Entrée: ${fmt(pos.entry)}',
                            style: TextStyle(fontSize: 10, color: t2, fontFamily: 'JetBrainsMono')),
                        if (hasSL || hasTP) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (hasSL)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: redBg, borderRadius: BorderRadius.circular(3)),
                                  child: Text('SL ${fmt(pos.stopLoss!)}', style: TextStyle(fontSize: 8, color: red, fontFamily: 'JetBrainsMono')),
                                ),
                              if (hasSL && hasTP) const SizedBox(width: 4),
                              if (hasTP)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: greenBg, borderRadius: BorderRadius.circular(3)),
                                  child: Text('TP ${fmt(pos.takeProfit!)}', style: TextStyle(fontSize: 8, color: green, fontFamily: 'JetBrainsMono')),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(height: 3, decoration: BoxDecoration(color: bg3, borderRadius: BorderRadius.circular(2))),
                      FractionallySizedBox(
                        widthFactor: curFrac / 100,
                        child: Container(height: 3, decoration: BoxDecoration(color: up ? green : red, borderRadius: BorderRadius.circular(2))),
                      ),
                      Positioned(
                        left: entryFrac / 100 * (MediaQuery.of(context).size.width - 84),
                        top: -2,
                        child: Container(width: 2, height: 7, color: t2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Entrée: ${fmt(pos.entry)}', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: t2)),
                      Text('Actuel: ${fmt(cur)}', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w600, color: up ? green : red)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyItem(TradeOrder o, bool isDark, Color bg2, Color t0, Color t2, Color green, Color greenBg, Color red, Color redBg) {
    final isBuy = o.side == 'buy';
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isBuy ? greenBg : redBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(isBuy ? 'BUY' : 'SELL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isBuy ? green : red, letterSpacing: 0.4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${o.sym}/USDT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t0)),
                Text('${o.qty.toStringAsFixed(4)} ${o.sym} @ ${fmt(o.price)}',
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: t2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt(o.qty * o.price), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w600, color: t0)),
              Text(o.time, style: TextStyle(fontSize: 9, color: t2)),
            ],
          ),
        ],
      ),
    );
  }

  void _showPositionEditDialog(BuildContext context, Position pos, bool isDark, Color bg1, Color bg2, Color border, Color accent, Color t0, Color t2, Color green, Color red) {
    final slCtrl = TextEditingController(text: pos.stopLoss?.toStringAsFixed(2) ?? '');
    final tpCtrl = TextEditingController(text: pos.takeProfit?.toStringAsFixed(2) ?? '');
    final slPctCtrl = TextEditingController();
    final tpPctCtrl = TextEditingController();
    final cur = prices[pos.sym] ?? 0;
    final usePrice = ValueNotifier(true);

    showModalBottomSheet(
      context: context,
      backgroundColor: bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: t2, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: accent.withOpacity( 0.15), borderRadius: BorderRadius.circular(20)),
                          child: Center(child: Text(pos.sym.substring(0, 3), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent))),
                        ),
                        const SizedBox(width: 10),
                        Text('Modifier ${pos.sym}/USDT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t0)),
                        const Spacer(),
                        Text('${pos.qty.toStringAsFixed(4)} ${pos.sym}', style: TextStyle(fontSize: 10, color: t2, fontFamily: 'JetBrainsMono')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Prix actuel: ${fmt(cur)} · Entrée: ${fmt(pos.entry)} · P&L: ${fmt(pos.qty * (cur - pos.entry))}',
                        style: TextStyle(fontSize: 10, color: t2)),
                    const SizedBox(height: 16),

                    // Mode toggle
                    Row(
                      children: [
                        _modeChip('Prix', usePrice, true, accent, bg2, t0, t2),
                        const SizedBox(width: 6),
                        _modeChip('%', usePrice, false, accent, bg2, t0, t2),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SL field
                    _editField('Stop Loss', usePrice.value ? slCtrl : slPctCtrl, usePrice, pos.entry, accent, bg2, border, t0, t2),
                    const SizedBox(height: 10),

                    // TP field
                    _editField('Take Profit', usePrice.value ? tpCtrl : tpPctCtrl, usePrice, pos.entry, accent, bg2, border, t0, t2),
                    const SizedBox(height: 18),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: bg2,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: border),
                              ),
                              child: Center(child: Text('Annuler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t2))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              double? sl, tp;
                              if (usePrice.value) {
                                sl = double.tryParse(slCtrl.text);
                                tp = double.tryParse(tpCtrl.text);
                              } else {
                                final slPct = double.tryParse(slPctCtrl.text);
                                final tpPct = double.tryParse(tpPctCtrl.text);
                                if (slPct != null && slPct > 0) sl = cur * (1 - slPct / 100);
                                if (tpPct != null && tpPct > 0) tp = cur * (1 + tpPct / 100);
                              }
                              portfolio.updateStopLoss(pos.sym, sl);
                              portfolio.updateTakeProfit(pos.sym, tp);
                              Navigator.of(ctx).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(child: Text('Enregistrer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modeChip(String label, ValueNotifier<bool> mode, bool isPrice, Color accent, Color bg2, Color t0, Color t2) {
    final active = mode.value == isPrice;
    return GestureDetector(
      onTap: () => mode.value = isPrice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent : bg2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : t2)),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, ValueNotifier<bool> usePrice, double entry, Color accent, Color bg2, Color border, Color t0, Color t2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 13, color: t0, fontFamily: 'JetBrainsMono'),
          decoration: InputDecoration(
            hintText: usePrice.value ? 'Prix en USDT' : 'Pourcentage (%)',
            hintStyle: TextStyle(fontSize: 11, color: t2),
            filled: true,
            fillColor: bg2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final double totalVal;
  final bool isUp;
  final bool isDark;
  final Color color;

  _SparklinePainter({required this.totalVal, required this.isUp, required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final vals = List.generate(30, (i) {
      return totalVal * (0.94 + i / 30 * 0.08 + sin(i * 0.5) * 0.01);
    });
    vals[vals.length - 1] = totalVal;
    final mn = vals.reduce(min);
    final mx = vals.reduce(max);
    final rng = (mx - mn).clamp(0.01, double.infinity);
    final pts = vals.asMap().entries.map((e) {
      return Offset(size.width * e.key / (vals.length - 1), size.height * (1 - (e.value - mn) / rng));
    }).toList();

    final path = Path()..moveTo(pts[0].dx, size.height);
    for (final p in pts) path.lineTo(p.dx, p.dy);
    path.lineTo(pts.last.dx, size.height);
    path.close();
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity( 0.15), color.withOpacity( 0.0)],
    );
    canvas.drawPath(path, Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) linePath.lineTo(pts[i].dx, pts[i].dy);
    canvas.drawPath(linePath, Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.totalVal != totalVal;
}
