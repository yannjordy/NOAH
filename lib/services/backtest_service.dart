import 'dart:math';
import '../models/models.dart' show Kline;

class BacktestTrade {
  final int entryIndex;
  final double entryPrice;
  final double entryTime;
  double? exitPrice;
  double? exitTime;
  double quantity;
  bool isLong;
  double? stopLoss;
  double? takeProfit;
  double pnl = 0;
  double pnlPct = 0;
  String exitReason = '';

  BacktestTrade({
    required this.entryIndex,
    required this.entryPrice,
    required this.entryTime,
    required this.quantity,
    this.isLong = true,
    this.stopLoss,
    this.takeProfit,
  });
}

class BacktestResult {
  final List<BacktestTrade> trades;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double totalPnl;
  final double totalPnlPct;
  final double maxDrawdown;
  final double sharpeRatio;
  final double profitFactor;
  final double expectancy;
  final double avgTradePnl;
  final double avgTradePnlPct;

  BacktestResult({
    required this.trades,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.totalPnl,
    required this.totalPnlPct,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.profitFactor,
    required this.expectancy,
    required this.avgTradePnl,
    required this.avgTradePnlPct,
  });
}

class BacktestSignal {
  final int index;
  final String action; // BUY, SELL, HOLD
  final double confidence;

  BacktestSignal({required this.index, required this.action, required this.confidence});
}

class BacktestService {
  final double initialCapital;
  final double fee;
  double _peakCapital;
  double _capital;

  BacktestService({this.initialCapital = 10000, this.fee = 0.001})
      : _capital = initialCapital,
        _peakCapital = initialCapital;

  BacktestResult run(
    List<Kline> klines,
    List<BacktestSignal> signals, {
    double stopLossPct = 0.05,
    double takeProfitPct = 0.10,
    double positionSizePct = 0.1,
  }) {
    final trades = <BacktestTrade>[];
    _capital = initialCapital;
    _peakCapital = initialCapital;
    final equityCurve = <double>[initialCapital];

    int i = 0;
    while (i < klines.length) {
      final k = klines[i];
      // Check for active trade exits
      for (final trade in trades.where((t) => t.exitPrice == null)) {
        _checkExits(trade, k, i);
        if (trade.exitPrice != null) {
          trade.pnl = (trade.exitPrice! - trade.entryPrice) * trade.quantity * (trade.isLong ? 1 : -1);
          trade.pnlPct = (trade.exitPrice! / trade.entryPrice - 1) * 100 * (trade.isLong ? 1 : -1);
          _capital += trade.pnl;
          if (_capital > _peakCapital) _peakCapital = _capital;
        }
      }

      // Check for entry signals
      final signal = signals.where((s) => s.index == i).firstOrNull;
      if (signal != null && (signal.action == 'BUY' || signal.action == 'SELL') && _capital > 0) {
        final isLong = signal.action == 'BUY';
        final entryPrice = k.open;
        final qty = (_capital * positionSizePct) / entryPrice;
        trades.add(BacktestTrade(
          entryIndex: i,
          entryPrice: entryPrice,
          entryTime: k.openTime.toDouble(),
          quantity: qty,
          isLong: isLong,
          stopLoss: isLong ? entryPrice * (1 - stopLossPct) : entryPrice * (1 + stopLossPct),
          takeProfit: isLong ? entryPrice * (1 + takeProfitPct) : entryPrice * (1 - takeProfitPct),
        ));
      }

      equityCurve.add(_capital);
      i++;
    }

    // Force-close remaining open trades at last kline close
    for (final trade in trades.where((t) => t.exitPrice == null)) {
      final lastK = klines.last;
      trade.exitPrice = lastK.close;
      trade.exitTime = lastK.closeTime.toDouble();
      trade.exitReason = 'force_close';
      trade.pnl = (trade.exitPrice! - trade.entryPrice) * trade.quantity * (trade.isLong ? 1 : -1);
      trade.pnlPct = (trade.exitPrice! / trade.entryPrice - 1) * 100 * (trade.isLong ? 1 : -1);
      _capital += trade.pnl;
    }

    final winning = trades.where((t) => t.pnl > 0).length;
    final losing = trades.where((t) => t.pnl <= 0).length;
    final totalPnL = _capital - initialCapital;

    return BacktestResult(
      trades: trades,
      totalTrades: trades.length,
      winningTrades: winning,
      losingTrades: losing,
      winRate: trades.isEmpty ? 0 : winning / trades.length,
      totalPnl: totalPnL,
      totalPnlPct: initialCapital > 0 ? (totalPnL / initialCapital) * 100 : 0,
      maxDrawdown: _calcMaxDrawdown(equityCurve),
      sharpeRatio: _calcSharpe(equityCurve),
      profitFactor: _calcProfitFactor(trades),
      expectancy: trades.isEmpty ? 0 : totalPnL / trades.length,
      avgTradePnl: trades.isEmpty ? 0 : totalPnL / trades.length,
      avgTradePnlPct: trades.isEmpty ? 0 : trades.map((t) => t.pnlPct).reduce((a, b) => a + b) / trades.length,
    );
  }

  void _checkExits(BacktestTrade trade, Kline k, int index) {
    if (trade.isLong) {
      if (trade.stopLoss != null && k.low <= trade.stopLoss!) {
        trade.exitPrice = trade.stopLoss;
        trade.exitTime = k.closeTime.toDouble();
        trade.exitReason = 'stop_loss';
      } else if (trade.takeProfit != null && k.high >= trade.takeProfit!) {
        trade.exitPrice = trade.takeProfit;
        trade.exitTime = k.closeTime.toDouble();
        trade.exitReason = 'take_profit';
      }
    } else {
      if (trade.stopLoss != null && k.high >= trade.stopLoss!) {
        trade.exitPrice = trade.stopLoss;
        trade.exitTime = k.closeTime.toDouble();
        trade.exitReason = 'stop_loss';
      } else if (trade.takeProfit != null && k.low <= trade.takeProfit!) {
        trade.exitPrice = trade.takeProfit;
        trade.exitTime = k.closeTime.toDouble();
        trade.exitReason = 'take_profit';
      }
    }
  }

  double _calcMaxDrawdown(List<double> equity) {
    double peak = equity.first;
    double maxDd = 0;
    for (final v in equity) {
      if (v > peak) peak = v;
      final dd = peak > 0 ? ((peak - v) / peak).toDouble() : 0.0;
      if (dd > maxDd) maxDd = dd;
    }
    return maxDd * 100;
  }

  double _calcSharpe(List<double> equity) {
    if (equity.length < 2) return 0;
    final returns = <double>[];
    for (int i = 1; i < equity.length; i++) {
      returns.add(equity[i] / equity[i - 1] - 1);
    }
    final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
    final variance = returns.fold(0.0, (a, b) => a + (b - mean) * (b - mean)) / returns.length;
    if (variance <= 0) return 0;
    final std = sqrt(variance);
    return std > 0 ? (mean / std) * sqrt(365) : 0;
  }

  double _calcProfitFactor(List<BacktestTrade> trades) {
    double grossProfit = 0, grossLoss = 0;
    for (final t in trades) {
      if (t.pnl > 0) grossProfit += t.pnl;
      else grossLoss += t.pnl.abs();
    }
    return grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? double.infinity : 0;
  }
}
