import 'dart:convert';
import '../models/models.dart';

/// NOAH's learning memory — stores, analyzes, and evolves from trade history
class TradeJournalService {
  List<TradeJournalEntry> _entries = [];
  String _evolvedMemory = '';

  List<TradeJournalEntry> get entries => List.unmodifiable(_entries);
  String get evolvedMemory => _evolvedMemory;

  /// Load from persisted JSON
  void loadFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return;
    try {
      final list = jsonDecode(jsonStr) as List;
      _entries = list.map((e) => TradeJournalEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  /// Save to JSON string
  String toJson() => jsonEncode(_entries.map((e) => e.toJson()).toList());

  /// Load evolved memory
  void loadMemory(String? memory) {
    _evolvedMemory = memory ?? '';
  }

  String memoryToJson() => _evolvedMemory;

  /// Add a new trade entry (called when a trade is opened)
  void recordTradeOpen({
    required String symbol,
    required String side,
    required double entryPrice,
    required double quantity,
    required String signalType,
    double signalConfidence = 0.5,
    String? marketRegime,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    final entry = TradeJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      side: side,
      entryPrice: entryPrice,
      quantity: quantity,
      signalType: signalType,
      signalConfidence: signalConfidence,
      marketRegime: marketRegime,
      reason: reason,
      entryTime: DateTime.now(),
      metadata: metadata,
    );
    _entries.add(entry);
  }

  /// Close a trade and record outcome (called when a trade is closed)
  TradeJournalEntry? closeTrade({
    required String symbol,
    required double exitPrice,
    required double pnl,
    required DateTime exitTime,
  }) {
    // Find the most recent open trade for this symbol
    final idx = _entries.lastIndexWhere((e) =>
        e.symbol == symbol && e.exitPrice == null);
    if (idx < 0) return null;

    final original = _entries[idx];
    final closed = original.close(exitPrice: exitPrice, pnl: pnl, exitTime: exitTime);
    _entries[idx] = closed;
    return closed;
  }

  /// Add a lesson to a trade (after LLM analysis)
  void addLesson(String tradeId, String lesson) {
    final idx = _entries.indexWhere((e) => e.id == tradeId);
    if (idx < 0) return;
    final old = _entries[idx];
    _entries[idx] = TradeJournalEntry(
      id: old.id,
      symbol: old.symbol,
      side: old.side,
      entryPrice: old.entryPrice,
      exitPrice: old.exitPrice,
      quantity: old.quantity,
      pnl: old.pnl,
      pnlPct: old.pnlPct,
      signalType: old.signalType,
      signalConfidence: old.signalConfidence,
      marketRegime: old.marketRegime,
      reason: old.reason,
      outcome: old.outcome,
      lesson: lesson,
      entryTime: old.entryTime,
      exitTime: old.exitTime,
      metadata: old.metadata,
    );
  }

  /// Update evolved memory (written by LLM after analysis)
  void updateEvolvedMemory(String memory) {
    _evolvedMemory = memory;
  }

  // ═══════════════════════════════════════════════════════
  //  PERFORMANCE ANALYTICS
  // ═══════════════════════════════════════════════════════

  /// Win rate for closed trades
  double get winRate {
    final closed = _entries.where((e) => e.outcome != null).toList();
    if (closed.isEmpty) return 0;
    final wins = closed.where((e) => e.outcome == 'WIN').length;
    return wins / closed.length;
  }

  /// Average win %
  double get avgWinPct {
    final wins = _entries.where((e) => e.outcome == 'WIN' && e.pnlPct != null).toList();
    if (wins.isEmpty) return 0;
    return wins.map((e) => e.pnlPct!).reduce((a, b) => a + b) / wins.length;
  }

  /// Average loss %
  double get avgLossPct {
    final losses = _entries.where((e) => e.outcome == 'LOSS' && e.pnlPct != null).toList();
    if (losses.isEmpty) return 0;
    return losses.map((e) => e.pnlPct!).reduce((a, b) => a + b) / losses.length;
  }

  /// Profit factor (total wins / total losses)
  double get profitFactor {
    final wins = _entries.where((e) => e.outcome == 'WIN' && e.pnl != null).fold(0.0, (s, e) => s + e.pnl!);
    final losses = _entries.where((e) => e.outcome == 'LOSS' && e.pnl != null).fold(0.0, (s, e) => s + e.pnl!.abs());
    if (losses == 0) return wins > 0 ? double.infinity : 0;
    return wins / losses;
  }

  /// Win rate by signal type
  Map<String, double> winRateBySignal() {
    final bySignal = <String, List<TradeJournalEntry>>{};
    for (final e in _entries.where((e) => e.outcome != null)) {
      bySignal.putIfAbsent(e.signalType, () => []).add(e);
    }
    return bySignal.map((k, v) {
      final wins = v.where((e) => e.outcome == 'WIN').length;
      return MapEntry(k, wins / v.length);
    });
  }

  /// Win rate by market regime
  Map<String, double> winRateByRegime() {
    final byRegime = <String, List<TradeJournalEntry>>{};
    for (final e in _entries.where((e) => e.outcome != null && e.marketRegime != null)) {
      byRegime.putIfAbsent(e.marketRegime!, () => []).add(e);
    }
    return byRegime.map((k, v) {
      final wins = v.where((e) => e.outcome == 'WIN').length;
      return MapEntry(k, wins / v.length);
    });
  }

  /// Win rate by symbol
  Map<String, double> winRateBySymbol() {
    final bySym = <String, List<TradeJournalEntry>>{};
    for (final e in _entries.where((e) => e.outcome != null)) {
      bySym.putIfAbsent(e.symbol, () => []).add(e);
    }
    return bySym.map((k, v) {
      final wins = v.where((e) => e.outcome == 'WIN').length;
      return MapEntry(k, wins / v.length);
    });
  }

  /// Total PnL
  double get totalPnl {
    return _entries.where((e) => e.pnl != null).fold(0.0, (s, e) => s + e.pnl!);
  }

  /// Last N closed trades
  List<TradeJournalEntry> recentTrades({int limit = 20}) {
    return _entries.where((e) => e.outcome != null).toList()
      ..sort((a, b) => (b.exitTime ?? b.entryTime).compareTo(a.exitTime ?? a.entryTime));
  }

  /// Generate performance summary for LLM context
  String generatePerformanceSummary() {
    final buf = StringBuffer();
    buf.writeln('## Historique de performance NOAH');
    buf.writeln('Total trades: ${_entries.length}');
    buf.writeln('Trades fermés: ${_entries.where((e) => e.outcome != null).length}');
    buf.writeln('Win rate: ${(winRate * 100).toStringAsFixed(1)}%');
    buf.writeln('Profit factor: ${profitFactor.toStringAsFixed(2)}');
    buf.writeln('PnL total: ${totalPnl >= 0 ? "+" : ""}\$${totalPnl.toStringAsFixed(2)}');
    buf.writeln('Win moyen: +${avgWinPct.toStringAsFixed(1)}% | Loss moyen: ${avgLossPct.toStringAsFixed(1)}%');
    buf.writeln('');

    final bySignal = winRateBySignal();
    if (bySignal.isNotEmpty) {
      buf.writeln('### Win rate par signal');
      for (final e in bySignal.entries) {
        buf.writeln('- ${e.key}: ${(e.value * 100).toStringAsFixed(0)}%');
      }
      buf.writeln('');
    }

    final byRegime = winRateByRegime();
    if (byRegime.isNotEmpty) {
      buf.writeln('### Win rate par régime');
      for (final e in byRegime.entries) {
        buf.writeln('- ${e.key}: ${(e.value * 100).toStringAsFixed(0)}%');
      }
      buf.writeln('');
    }

    final bySym = winRateBySymbol();
    if (bySym.isNotEmpty) {
      buf.writeln('### Win rate par symbole');
      for (final e in bySym.entries) {
        buf.writeln('- ${e.key}: ${(e.value * 100).toStringAsFixed(0)}%');
      }
      buf.writeln('');
    }

    // Last 5 trades
    final recent = recentTrades(limit: 5);
    if (recent.isNotEmpty) {
      buf.writeln('### 5 derniers trades');
      for (final e in recent) {
        final pnlStr = e.pnl != null ? "${e.pnl! >= 0 ? "+" : ""}\$${e.pnl!.toStringAsFixed(2)}" : "?";
        buf.writeln('- ${e.side} ${e.symbol} @ \$${e.entryPrice.toStringAsFixed(2)} → $pnlStr (${e.outcome}) [${e.signalType}]');
      }
    }

    if (_evolvedMemory.isNotEmpty) {
      buf.writeln('');
      buf.writeln('### Mémoire évolutive');
      buf.writeln(_evolvedMemory);
    }

    return buf.toString();
  }
}
