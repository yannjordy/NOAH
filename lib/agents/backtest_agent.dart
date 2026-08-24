import 'dart:math';
import 'agent_base.dart';

class BacktestReport {
  final Map<String, dynamic> details;

  BacktestReport({required this.details});
}

class BacktestAgent extends BaseAgent {
  final AiThinker? thinker;

  BacktestAgent({this.thinker});

  @override
  String get name => 'Junior';

  Future<void> compute(String symbol, List klines) async {
    // Background computation stub
  }

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final klines = ctx.klines[symbol] ?? [];
    final closes = klines.map((k) => k.close).toList();

    if (closes.length < 30) {
      return AgentReport(
        agentName: name,
        confidence: 0.3,
        summary: 'Données insuffisantes pour backtest ($symbol: ${closes.length} candles)',
        details: {
          'trainTrades': 0, 'trainWinRate': 0.0, 'trainSharpe': 0.0,
          'testTrades': 0, 'testWinRate': 0.0, 'testSharpe': 0.0,
          'overfit': false, 'totalCandles': closes.length,
        },
      );
    }

    final mid = closes.length ~/ 2;
    final trainCloses = closes.sublist(0, mid);
    final testCloses = closes.sublist(mid);

    final trainResult = _simulate(trainCloses);
    final testResult = _simulate(testCloses);

    final diff = (trainResult['winRate']! - testResult['winRate']!).abs();
    final overfit = diff > 0.15;

    return AgentReport(
      agentName: name,
      confidence: overfit ? 0.3 : 0.7,
      summary: 'Backtest: Train WR ${(trainResult['winRate']! * 100).toStringAsFixed(0)}%, '
          'Test WR ${(testResult['winRate']! * 100).toStringAsFixed(0)}% '
          '${overfit ? "(Overfit détecté)" : ""}',
      details: {
        'trainTrades': trainResult['trades'],
        'trainWinRate': trainResult['winRate'],
        'trainSharpe': trainResult['sharpe'],
        'testTrades': testResult['trades'],
        'testWinRate': testResult['winRate'],
        'testSharpe': testResult['sharpe'],
        'overfit': overfit,
        'totalCandles': closes.length,
      },
    );
  }

  Map<String, double> _simulate(List<double> closes) {
    int trades = 0, wins = 0;
    final returns = <double>[];

    for (int i = 5; i < closes.length; i++) {
      final sma5 = closes.sublist(i - 5, i).fold(0.0, (a, b) => a + b) / 5;
      final prev = closes[i - 1];

      if (prev < sma5 && closes[i] > sma5) {
        final entry = closes[i];
        if (i + 3 < closes.length) {
          final exit = closes[i + 3];
          final pnl = (exit - entry) / entry;
          trades++;
          if (pnl > 0) wins++;
          returns.add(pnl);
        }
      }
    }

    final winRate = trades > 0 ? wins / trades : 0.0;
    double sharpe = 0;
    if (returns.length >= 2) {
      final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
      final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
      final std = sqrt(variance);
      sharpe = std > 0 ? (mean / std) : 0;
    }

    return {
      'trades': trades.toDouble(),
      'winRate': winRate,
      'sharpe': sharpe,
    };
  }
}
