import 'dart:math';
import 'agent_base.dart';
import '../models/models.dart' show Kline;
import '../services/backtest_service.dart';

class BacktestAgent extends BaseAgent {
  final AiThinker? _thinker;

  static final Map<String, BacktestResult> _results = {};
  static final Map<String, String> _aiAdvice = {};
  static final Set<String> _computing = {};

  static const _pending = '🔄 Backtest en cours...';

  BacktestAgent({AiThinker? thinker}) : _thinker = thinker;

  @override
  String get name => 'Junior';

  /// Returns cached result instantly. If no result yet, returns pending message.
  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final cached = _results[symbol];

    if (cached == null) {
      return AgentReport(
        agentName: name,
        confidence: 0,
        summary: _pending,
        recommendation: 'HOLD',
        details: {'status': 'computing'},
      );
    }

    final buf = StringBuffer();
    buf.writeln('**📊 Backtest $symbol**\n');
    buf.writeln('**Données:** --- (pré-calculé)');
    buf.writeln('');
    buf.writeln('- Trades: ${cached.totalTrades} (${cached.winningTrades}W / ${cached.losingTrades}L)');
    buf.writeln('- Win Rate: ${(cached.winRate * 100).toStringAsFixed(1)}%');
    buf.writeln('- PnL: ${cached.totalPnlPct >= 0 ? '+' : ''}${cached.totalPnlPct.toStringAsFixed(2)}%');
    buf.writeln('- Profit Factor: ${cached.profitFactor == double.infinity ? '∞' : cached.profitFactor.toStringAsFixed(2)}');
    buf.writeln('- Sharpe: ${cached.sharpeRatio.toStringAsFixed(2)}');
    buf.writeln('- Max Drawdown: ${cached.maxDrawdown.toStringAsFixed(1)}%');
    buf.writeln('');

    final advice = _aiAdvice[symbol];
    if (advice != null) {
      buf.writeln('**🧠 Junior réfléchit...**\n');
      buf.writeln('$advice\n');
    }

    final confidence = min(cached.sharpeRatio / 3, 1.0) * 0.5 + cached.winRate * 0.3;

    return AgentReport(
      agentName: name,
      confidence: clampConfidence(confidence),
      summary: buf.toString(),
      recommendation: cached.profitFactor > 1.5 && cached.winRate > 0.5
          ? (cached.totalPnlPct > 0 ? 'BUY' : 'SELL') : 'HOLD',
      details: {
        'totalTrades': cached.totalTrades,
        'winRate': cached.winRate,
        'pnl': cached.totalPnlPct,
        'sharpe': cached.sharpeRatio,
        'drawdown': cached.maxDrawdown,
        'status': 'ready',
      },
    );
  }

  /// Background computation — non-blocking, stores result for next analyze().
  Future<void> compute(String symbol, List<Kline> klines) async {
    if (_computing.contains(symbol) || klines.length < 30) return;
    _computing.add(symbol);
    try {
      final bt = BacktestService();
      final splitIdx = (klines.length * 0.7).round();
      final train = klines.sublist(0, splitIdx);
      final test = klines.sublist(splitIdx);

      final trainSignals = _generateSignals(train);
      final trainResult = bt.run(train, trainSignals, positionSizePct: 0.1);

      final testSignals = _generateSignals(test);
      final testResult = bt.run(test, testSignals, positionSizePct: 0.1);

      final merged = BacktestResult(
        trades: [...trainResult.trades, ...testResult.trades],
        totalTrades: trainResult.totalTrades + testResult.totalTrades,
        winningTrades: trainResult.winningTrades + testResult.winningTrades,
        losingTrades: trainResult.losingTrades + testResult.losingTrades,
        winRate: trainResult.totalTrades + testResult.totalTrades > 0
            ? (trainResult.winningTrades + testResult.winningTrades) /
                (trainResult.totalTrades + testResult.totalTrades) : 0,
        totalPnl: trainResult.totalPnl + testResult.totalPnl,
        totalPnlPct: trainResult.totalPnlPct + testResult.totalPnlPct,
        maxDrawdown: max(trainResult.maxDrawdown, testResult.maxDrawdown),
        sharpeRatio: (trainResult.sharpeRatio + testResult.sharpeRatio) / 2,
        profitFactor: trainResult.profitFactor == double.infinity
            ? testResult.profitFactor : (trainResult.profitFactor + testResult.profitFactor) / 2,
        expectancy: (trainResult.expectancy + testResult.expectancy) / 2,
        avgTradePnl: (trainResult.avgTradePnl + testResult.avgTradePnl) / 2,
        avgTradePnlPct: (trainResult.avgTradePnlPct + testResult.avgTradePnlPct) / 2,
      );

      _results[symbol] = merged;

      if (_thinker != null) {
        final p = '''
Tu es Junior, analyste backtesting. Résultats pour $symbol :
Trades: ${merged.totalTrades}, WR: ${(merged.winRate * 100).toStringAsFixed(0)}%, PnL: ${merged.totalPnlPct.toStringAsFixed(1)}%, Sharpe: ${merged.sharpeRatio.toStringAsFixed(2)}
Conseillerais-tu cette stratégie ? 2 phrases max, français.
''';
        _thinker(p, systemContext: 'Tu es Junior. 2 phrases max, français.')
            .then((r) { if (!r.startsWith('❌')) _aiAdvice[symbol] = r; });
      }
    } finally {
      _computing.remove(symbol);
    }
  }

  List<BacktestSignal> _generateSignals(List<Kline> klines) {
    final signals = <BacktestSignal>[];
    if (klines.length < 50) return signals;
    final closes = klines.map((k) => k.close).toList();
    for (int i = 20; i < klines.length; i++) {
      final rsi = BaseAgent.computeRSI(closes.sublist(0, i + 1));
      final sma20 = BaseAgent.ma(closes.sublist(0, i + 1), 20);
      final sma50 = BaseAgent.ma(closes.sublist(0, i + 1), 50);
      final price = klines[i].open;
      String action = 'HOLD';
      double conf = 0;
      if (sma20 > sma50 && closes[i - 1] < sma20 && price > sma20) {
        action = 'BUY'; conf = 0.6 + (rsi < 40 ? 0.2 : 0);
      } else if (sma20 < sma50 && closes[i - 1] > sma20 && price < sma20) {
        action = 'SELL'; conf = 0.6 + (rsi > 60 ? 0.2 : 0);
      }
      if (rsi < 30 && action == 'HOLD') { action = 'BUY'; conf = 0.5; }
      else if (rsi > 70 && action == 'HOLD') { action = 'SELL'; conf = 0.5; }
      signals.add(BacktestSignal(index: i, action: action, confidence: conf));
    }
    return signals.where((s) => s.action != 'HOLD').toList();
  }
}
