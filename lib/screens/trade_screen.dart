import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/market_service.dart';
import '../theme/noah_theme.dart';
import '../services/strategy_engine.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/order_book.dart';

class TradeScreen extends StatefulWidget {
  final PortfolioProvider portfolio;
  final AuthProvider auth;
  final RiskProvider risk;
  final MarketService market;
  final SettingsProvider settings;
  final ChatProvider chat;
  final void Function(int) openLogin;
  final VoidCallback navigateToChat;

  const TradeScreen({
    super.key,
    required this.portfolio,
    required this.auth,
    required this.risk,
    required this.market,
    required this.settings,
    required this.chat,
    required this.openLogin,
    required this.navigateToChat,
  });

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final _qtyCtrl = TextEditingController(text: '0.001');
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  String _currentSymbol = 'BTC';

  @override
  void initState() {
    super.initState();
    _currentSymbol = widget.portfolio.currentSymbol;
    widget.market.fetchKlines(_currentSymbol);
    widget.market.fetchDepth(_currentSymbol);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _slCtrl.dispose();
    _tpCtrl.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _price => prices[_currentSymbol] ?? 0;
  double get _est => _qty * _price;
  bool get _insufficient => _est > widget.portfolio.data.usdt;

  double? get _stopLoss {
    final v = double.tryParse(_slCtrl.text) ?? 0;
    return v > 0 ? _price * (1 - v / 100) : null;
  }

  double? get _takeProfit {
    final v = double.tryParse(_tpCtrl.text) ?? 0;
    return v > 0 ? _price * (1 + v / 100) : null;
  }

  Widget _slTpField(String label, TextEditingController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: t2)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w600, color: t0),
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: TextStyle(color: t2, fontSize: 13),
            border: InputBorder.none,
            filled: true,
            fillColor: bg2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _setPct(double pct) {
    final qty = (widget.portfolio.data.usdt * pct) / _price;
    _qtyCtrl.text = qty > 1 ? qty.toStringAsFixed(3) : qty.toStringAsFixed(6);
    setState(() {});
  }

  void _selectSymbol(String s) {
    setState(() => _currentSymbol = s);
    widget.portfolio.setSymbol(s);
    widget.market.fetchKlines(s);
    widget.market.fetchDepth(s);
  }

  void _executeTrade(String side) {
    if (!widget.auth.isLoggedIn) {
      widget.openLogin(0);
      return;
    }
    final qty = _qty;
    if (qty <= 0) return;
    widget.portfolio.executeTrade(side, qty, symbol: _currentSymbol, stopLoss: _stopLoss, takeProfit: _takeProfit);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = isDark ? const Color(0x1AC2A878) : const Color(0x1AB08D57);
    final accentBorder = isDark ? const Color(0x2EC2A878) : const Color(0x33B08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final greenBg = isDark ? const Color(0x144CAF8E) : const Color(0x142E7D5E);
    final greenBorder = isDark ? const Color(0x2E4CAF8E) : const Color(0x2E2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final redBg = isDark ? const Color(0x14E07060) : const Color(0x14B8453A);
    final redBorder = isDark ? const Color(0x2EE07060) : const Color(0x2EB8453A);
    final amber = isDark ? const Color(0xFFD4A84B) : const Color(0xFFA67C2E);
    final amberBg = isDark ? const Color(0x14D4A84B) : const Color(0x14A67C2E);
    final amberBorder = isDark ? const Color(0x2ED4A84B) : const Color(0x2EA67C2E);

    final up = (pcts[_currentSymbol] ?? 0) >= 0;
    final pc = pcts[_currentSymbol] ?? 0;

    return Container(
      color: bg0,
      child: ListenableBuilder(
        listenable: widget.portfolio,
        builder: (context, _) {
          final data = widget.portfolio.data;
          final pos = data.positions.where((x) => x.sym == _currentSymbol).firstOrNull;
          final posQty = pos?.qty ?? 0;
          final posEntry = pos?.entry ?? 0;
          final posPnl = posQty * (_price - posEntry);
          final posPnlPct = posEntry > 0 ? ((_price - posEntry) / posEntry) * 100 : 0;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: amberBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.chat.binanceWorking
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 12,
                  color: widget.chat.binanceWorking
                      ? const Color(0xFF4CAF8E)
                      : amber,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.settings.isDemo
                        ? 'Trading fictif — Argent virtuel. Prix réels (Binance).'
                        : widget.chat.binanceWorking
                            ? '✅ Binance connecté — Trades réels sur Binance'
                            : 'Trading réel — Connecte Binance API dans Connexions',
                    style: TextStyle(
                      fontSize: 9,
                      color: widget.chat.binanceWorking
                          ? const Color(0xFF4CAF8E)
                          : amber,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Network instability warning
          if (!isNetworkStable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0x1AFF5252),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x33FF5252)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Réseau instable — Prix gelés, reconnexion...',
                      style: TextStyle(
                        fontSize: 9,
                        color: const Color(0xFFFF5252),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Symbol chips
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: symbols.map((s) {
                final active = s == _currentSymbol;
                return GestureDetector(
                  onTap: () => _selectSymbol(s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? accentBg : bg2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: active ? accentBorder : borderMd),
                    ),
                    child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? accent : t1)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Price hero
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
                Text('$_currentSymbol/USDT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t2, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(fmt(_price), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 26, fontWeight: FontWeight.w700, color: t0, letterSpacing: -1)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: up ? greenBg : redBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('${up ? '+' : ''}${pc.toStringAsFixed(2)}%',
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: up ? green : red)),
                    ),
                    const SizedBox(width: 8),
                    Text('Vol: ${fmtK(_price * basePrices[_currentSymbol]! * 380)}',
                        style: TextStyle(fontSize: 10, color: t2)),
                  ],
                ),
                const SizedBox(height: 10),
                // Position P&L
                if (posQty > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: posPnl >= 0 ? greenBg : redBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: posPnl >= 0 ? green.withValues(alpha: 0.3) : red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(posPnl >= 0 ? Icons.trending_up : Icons.trending_down, size: 14, color: posPnl >= 0 ? green : red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Position ${posQty.toStringAsFixed(4)} $_currentSymbol',
                                  style: TextStyle(fontSize: 10, color: t2)),
                              Text('${posPnl >= 0 ? '+' : ''}${fmt(posPnl)} (${posPnlPct >= 0 ? '+' : ''}${posPnlPct.toStringAsFixed(2)}%)',
                                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w700, color: posPnl >= 0 ? green : red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      _statCell('24H Haut', fmt(_price * 1.008), t2, t0, bg2),
                      _statCell('24H Bas', fmt(_price * 0.988), t2, t0, bg2),
                      _statCell('Spread', fmt(_price * 0.00018), t2, t0, bg2),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Chart + interval selector
          Container(
            padding: const EdgeInsets.all(14),
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
                    Text('Graphique $_currentSymbol/USDT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                    const Spacer(),
                    ...intervals.map((iv) {
                      final active = widget.market.currentInterval == iv;
                      return GestureDetector(
                        onTap: () {
                          widget.market.setInterval(iv);
                          widget.market.fetchKlines(_currentSymbol, interval: iv);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: active ? accentBg : bg2,
                            borderRadius: BorderRadius.circular(4),
                            border: active ? Border.all(color: accentBorder) : null,
                          ),
                          child: Text(iv, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: active ? accent : t2)),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: widget.market,
                  builder: (_, __) {
                    final klineData = widget.market.klines[_currentSymbol] ?? [];
                    if (klineData.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(child: Text('Chargement...', style: TextStyle(fontSize: 11, color: t2))),
                      );
                    }
                    return CandlestickChart(
                      data: klineData,
                      isDark: isDark,
                      onShareToChat: (text, imageBase64) {
                        if (imageBase64 != null) {
                          widget.chat.sendMessageWithImage(text, imageBase64);
                        } else {
                          widget.chat.sendMessage(text);
                        }
                        widget.navigateToChat();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Order book
          ListenableBuilder(
            listenable: widget.market,
            builder: (_, __) {
              final orderBids = widget.market.bids[_currentSymbol] ?? [];
              final orderAsks = widget.market.asks[_currentSymbol] ?? [];
              if (orderBids.isEmpty && orderAsks.isEmpty) return const SizedBox();
              return Column(
                children: [
                  OrderBook(bids: orderBids, asks: orderAsks, symbol: _currentSymbol),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          // Strategy signal
          ListenableBuilder(
            listenable: widget.market,
            builder: (_, __) {
              final kds = widget.market.klines[_currentSymbol] ?? [];
              if (kds.isEmpty) return const SizedBox();
              final sig = StrategyEngine.analyze(_currentSymbol, klines: kds);
              final isBull = sig.action == 'BUY' || sig.action == 'STRONG_BUY';
              final sigColor = isBull ? green : (sig.action == 'HOLD' ? amber : red);
              return Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
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
                        Text('Analyse Stratégique', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sigColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(sig.action, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sigColor, letterSpacing: 1.2)),
                        ),
                        const SizedBox(width: 8),
                        Text('${(sig.confidence * 100).toStringAsFixed(0)}% confiance', style: TextStyle(fontSize: 10, color: t1)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: sig.factors.entries.map((e) => Text(
                        '${e.key}: ${e.value}',
                        style: TextStyle(fontSize: 9, color: t2, fontFamily: 'JetBrains Mono'),
                      )).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          // Order form
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
                Text('Quantité', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.5)),
                const SizedBox(height: 5),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: _qtyCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15, fontWeight: FontWeight.w600, color: t0),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: bg2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(_currentSymbol, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [0.1, 0.25, 0.5, 0.75, 1.0].map((pct) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _setPct(pct),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: bg2,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: borderMd),
                          ),
                          child: Text('${(pct * 100).toInt()}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t1)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Valeur estimée', style: TextStyle(fontSize: 11, color: t2)),
                      Text(fmt(_est), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w600, color: t0)),
                    ],
                  ),
                ),
                if (_insufficient)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: amberBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: amberBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('⚠️ Fonds insuffisants. Besoin de ${fmt(_est)}, disponible ${fmt(widget.portfolio.data.usdt)}',
                                style: TextStyle(fontSize: 11, color: amber)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Stop Loss / Take Profit
                Row(
                  children: [
                    Expanded(
                      child: _slTpField('SL %', _slCtrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _slTpField('TP %', _tpCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _executeTrade('buy'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: greenBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: greenBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, size: 14, color: green),
                              const SizedBox(width: 5),
                              Text('ACHETER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: green, letterSpacing: 0.6)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _executeTrade('sell'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: redBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: redBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward, size: 14, color: red),
                              const SizedBox(width: 5),
                              Text('VENDRE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: red, letterSpacing: 0.6)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Balance bar
          _buildBalanceBar(isDark, bg1, border, t2, t0, green, red),
          const SizedBox(height: 12),
          // Signals
          _buildSignals(isDark, bg2, t0, t2, green, greenBg, greenBorder, red, redBg, redBorder, amber, amberBg, amberBorder),
        ],
      );
    },
  ),
    );
  }

  Widget _statCell(String label, String value, Color t2, Color t0, Color bg2) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: bg2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w600, color: t0)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBar(bool isDark, Color bg1, Color border, Color t2, Color t0, Color green, Color red) {
    final data = widget.portfolio.data;
    final posVal = data.positions.fold(0.0, (s, p) => s + p.qty * (prices[p.sym] ?? 0));
    final pnl = data.positions.fold(0.0, (s, p) => s + p.qty * ((prices[p.sym] ?? 0) - p.entry));
    final total = data.usdt + posVal;

    return Container(
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _balanceCell('USDT', fmt(data.usdt), t2, t0, green),
              _balanceCell('Positions', fmt(posVal), t2, t0, t0),
              _balanceCell('PnL', '${pnl >= 0 ? '+' : ''}${fmt(pnl)}', t2, pnl >= 0 ? green : red, pnl >= 0 ? green : red),
            ],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontSize: 10, color: t2)),
                Text(fmt(total), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w700, color: t0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCell(String label, String value, Color t2, Color valColor, Color defaultColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.transparent))),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w700, color: valColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignals(
      bool isDark, Color bg2, Color t0, Color t2,
      Color green, Color greenBg, Color greenBorder,
      Color red, Color redBg, Color redBorder,
      Color amber, Color amberBg, Color amberBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Signaux IA Récents', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        ...generateSignals().map((s) {
          final sc = s.type == 'BUY' ? green : s.type == 'SELL' ? red : amber;
          final sBg = s.type == 'BUY' ? greenBg : s.type == 'SELL' ? redBg : amberBg;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: sc, width: 3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: sBg, shape: BoxShape.circle),
                  child: Center(
                    child: Icon(
                      s.type == 'BUY' ? Icons.arrow_upward : s.type == 'SELL' ? Icons.arrow_downward : Icons.remove,
                      size: 14, color: sc,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${s.sym} · ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t0)),
                          Text(s.type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text('Confiance ${(s.conf * 100).toInt()}%', style: TextStyle(fontSize: 10, color: t2)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String fmtK(double n) {
  if (n >= 1e9) return '\$${(n / 1e9).toStringAsFixed(1)}B';
  if (n >= 1e6) return '\$${(n / 1e6).toStringAsFixed(1)}M';
  return '\$${n.toStringAsFixed(0)}';
}
