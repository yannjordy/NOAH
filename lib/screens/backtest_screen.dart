import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/market_service.dart';
import '../theme/noah_theme.dart';
import '../agents/backtest_agent.dart';
import '../theme/glass_theme.dart';

/// Backtesting screen with glass morphism design
class BacktestScreen extends StatefulWidget {
  final PortfolioProvider portfolio;
  final MarketService market;

  const BacktestScreen({
    super.key,
    required this.portfolio,
    required this.market,
  });

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  String _selectedSymbol = 'BTC';
  String _selectedInterval = '1h';
  bool _isRunning = false;
  Map<String, dynamic>? _results;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);

    return Container(
      color: bg0,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Header
          GlassTheme.cardFlat(
            context: context,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_outlined, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Backtesting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Teste les stratégies sur les données historiques',
                  style: TextStyle(fontSize: 11, color: t2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Symbol selector
          GlassTheme.cardFlat(
            context: context,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Symbole', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: symbols.take(12).map((s) {
                    return GlassTheme.chip(
                      context: context,
                      label: s,
                      isActive: s == _selectedSymbol,
                      onTap: () => setState(() => _selectedSymbol = s),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Interval selector
          GlassTheme.cardFlat(
            context: context,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intervalle', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['5m', '15m', '1h', '4h', '1d'].map((i) {
                    return GlassTheme.chip(
                      context: context,
                      label: i,
                      isActive: i == _selectedInterval,
                      onTap: () => setState(() => _selectedInterval = i),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Run button
          GlassTheme.button(
            context: context,
            isPrimary: true,
            onTap: _isRunning ? () {} : _runBacktest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRunning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isRunning ? 'Test en cours...' : 'Lancer le Backtest',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results
          if (_results != null) ...[
            _buildResults(isDark, t0, t1, t2, accent, green, red),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark, Color t0, Color t1, Color t2, Color accent, Color green, Color red) {
    final trainTrades = _results!['trainTrades'] ?? 0;
    final trainWinRate = (_results!['trainWinRate'] ?? 0.0) * 100;
    final trainSharpe = _results!['trainSharpe'] ?? 0.0;
    final testTrades = _results!['testTrades'] ?? 0;
    final testWinRate = (_results!['testWinRate'] ?? 0.0) * 100;
    final testSharpe = _results!['testSharpe'] ?? 0.0;
    final overfit = _results!['overfit'] ?? false;

    return Column(
      children: [
        // Train results
        GlassTheme.cardFlat(
          context: context,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Entraînement', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statItem('Trades', '$trainTrades', t0, t2),
                  _statItem('Win Rate', '${trainWinRate.toStringAsFixed(1)}%', trainWinRate > 50 ? green : red, t2),
                  _statItem('Sharpe', trainSharpe.toStringAsFixed(2), trainSharpe > 1 ? green : t0, t2),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Test results
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
                  Text('Test', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statItem('Trades', '$testTrades', t0, t2),
                  _statItem('Win Rate', '${testWinRate.toStringAsFixed(1)}%', testWinRate > 50 ? green : red, t2),
                  _statItem('Sharpe', testSharpe.toStringAsFixed(2), testSharpe > 1 ? green : t0, t2),
                ],
              ),
            ],
          ),
        ),
        if (overfit) ...[
          const SizedBox(height: 10),
          GlassTheme.cardFlat(
            context: context,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Overfitting détecté — les résultats sur données de test diffèrent significativement de l\'entraînement.',
                    style: TextStyle(fontSize: 11, color: red, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _statItem(String label, String value, Color valueColor, Color labelColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
        ],
      ),
    );
  }

  Future<void> _runBacktest() async {
    setState(() {
      _isRunning = true;
      _results = null;
    });

    // Build context
    final ctx = AgentContext(
      prices: Map.from(prices),
      pcts: Map.from(pcts),
      klines: Map.from(widget.market.klinesMap),
      bids: Map.from(widget.market.bids),
      asks: Map.from(widget.market.asks),
      usdtBalance: widget.portfolio.data.usdt,
      positions: widget.portfolio.data.positions.map((p) => PositionSnapshot(
        symbol: p.sym, qty: p.qty, entryPrice: p.entry,
      )).toList(),
      history: widget.portfolio.data.history.map((t) => TradeSnapshot(
        side: t.side, symbol: t.sym, qty: t.qty, price: t.price, time: t.time,
      )).toList(),
    );

    try {
      final agent = BacktestAgent();
      final report = agent.analyze(_selectedSymbol, ctx);
      setState(() {
        _results = report.details;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _results = {'trainTrades': 0, 'trainWinRate': 0.0, 'trainSharpe': 0.0, 'testTrades': 0, 'testWinRate': 0.0, 'testSharpe': 0.0, 'overfit': false};
        _isRunning = false;
      });
    }
  }
}
