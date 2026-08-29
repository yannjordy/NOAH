import 'dart:convert';
import '../services/storage_service.dart';

class LearningCache {
  final StorageService _storage;
  
  // Pattern tracking: key = "symbol_signalType_regime" -> {wins, losses, avgPnl}
  Map<String, Map<String, dynamic>> _patterns = {};
  
  // Strategy effectiveness: key = strategy name -> {uses, wins, avgConfidence}
  Map<String, Map<String, dynamic>> _strategies = {};
  
  // Recent failures: last N failed trades for quick reference
  List<Map<String, dynamic>> _recentFailures = [];
  
  // Adaptive thresholds
  double _minConfidence = 0.35;
  double _positionSizeMultiplier = 1.0;

  static const int _maxFailures = 20;

  LearningCache(this._storage) {
    _load();
  }

  void _load() {
    try {
      final data = _storage.getLearningCache();
      if (data.isNotEmpty) {
        final decoded = jsonDecode(data);
        _patterns = Map<String, dynamic>.from(decoded['patterns'] ?? {}).map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
        );
        _strategies = Map<String, dynamic>.from(decoded['strategies'] ?? {}).map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
        );
        _recentFailures = (decoded['failures'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];
        _minConfidence = (decoded['minConfidence'] as num?)?.toDouble() ?? 0.35;
        _positionSizeMultiplier = (decoded['posMultiplier'] as num?)?.toDouble() ?? 1.0;
      }
    } catch (_) {}
  }

  void _save() {
    _storage.setLearningCache(jsonEncode({
      'patterns': _patterns,
      'strategies': _strategies,
      'failures': _recentFailures,
      'minConfidence': _minConfidence,
      'posMultiplier': _positionSizeMultiplier,
    }));
  }

  /// Record a trade result and learn from it
  void recordTrade({
    required String symbol,
    required String action,
    required String signalType,
    required String regime,
    required double pnlPct,
    required double confidence,
    String? reason,
  }) {
    final isWin = pnlPct > 0;
    
    // Update pattern stats
    final patternKey = '${symbol}_${action}_$regime';
    _patterns.putIfAbsent(patternKey, () => {'wins': 0, 'losses': 0, 'totalPnl': 0.0, 'count': 0});
    final p = _patterns[patternKey]!;
    if (isWin) p['wins'] = (p['wins'] as int) + 1;
    else p['losses'] = (p['losses'] as int) + 1;
    p['totalPnl'] = (p['totalPnl'] as double) + pnlPct;
    p['count'] = (p['count'] as int) + 1;

    // Update strategy stats
    final strat = signalType.isNotEmpty ? signalType : 'AI_DECISION';
    _strategies.putIfAbsent(strat, () => {'uses': 0, 'wins': 0, 'totalConfidence': 0.0});
    final s = _strategies[strat]!;
    s['uses'] = (s['uses'] as int) + 1;
    if (isWin) s['wins'] = (s['wins'] as int) + 1;
    s['totalConfidence'] = (s['totalConfidence'] as double) + confidence;

    // Track failures
    if (!isWin) {
      _recentFailures.insert(0, {
        'symbol': symbol,
        'action': action,
        'pnl': pnlPct,
        'confidence': confidence,
        'regime': regime,
        'reason': reason ?? '',
        'time': DateTime.now().toIso8601String(),
      });
      if (_recentFailures.length > _maxFailures) {
        _recentFailures = _recentFailures.sublist(0, _maxFailures);
      }
    }

    // Adapt thresholds based on recent performance
    _adaptThresholds();
    _save();
  }

  void _adaptThresholds() {
    // Look at last 10 trades
    final recent = _recentFailures.take(10).toList();
    if (recent.isEmpty) return;

    final avgFailConfidence = recent.fold(0.0, (sum, f) => sum + (f['confidence'] as double)) / recent.length;
    
    // If recent failures had high confidence, raise the threshold
    if (avgFailConfidence > 0.6) {
      _minConfidence = (_minConfidence + 0.05).clamp(0.35, 0.75);
    } else if (avgFailConfidence < 0.4) {
      _minConfidence = (_minConfidence - 0.02).clamp(0.25, 0.65);
    }

    // Win rate based position sizing
    final totalTrades = _patterns.values.fold(0, (sum, p) => sum + (p['count'] as int));
    final totalWins = _patterns.values.fold(0, (sum, p) => sum + (p['wins'] as int));
    if (totalTrades >= 5) {
      final winRate = totalWins / totalTrades;
      if (winRate > 0.6) _positionSizeMultiplier = (_positionSizeMultiplier + 0.1).clamp(0.5, 1.5);
      else if (winRate < 0.4) _positionSizeMultiplier = (_positionSizeMultiplier - 0.1).clamp(0.5, 1.5);
    }
  }

  /// Get adapted confidence threshold
  double get minConfidence => _minConfidence;

  /// Get adapted position size multiplier
  double get positionSizeMultiplier => _positionSizeMultiplier;

  /// Get pattern stats for a symbol+regime combination
  Map<String, dynamic>? getPattern(String symbol, String action, String regime) {
    return _patterns['${symbol}_${action}_$regime'];
  }

  /// Get strategy win rate
  double getStrategyWinRate(String strategy) {
    final s = _strategies[strategy];
    if (s == null || (s['uses'] as int) == 0) return 0.5;
    return (s['wins'] as int) / (s['uses'] as int);
  }

  /// Get summary for LLM context
  String getLearningSummary() {
    final buf = StringBuffer();
    buf.writeln('## Cache d\'apprentissage');
    buf.writeln('Seuil min confiance: ${(_minConfidence * 100).toStringAsFixed(0)}%');
    buf.writeln('Multiplicateur position: ${_positionSizeMultiplier.toStringAsFixed(1)}x');

    if (_recentFailures.isNotEmpty) {
      buf.writeln('\n### Echecs recents (a eviter):');
      for (final f in _recentFailures.take(5)) {
        buf.writeln('- ${f['symbol']} ${f['action']} (${f['regime']}) -> PnL: ${(f['pnl'] as double).toStringAsFixed(1)}% | Conf: ${((f['confidence'] as double) * 100).toStringAsFixed(0)}%');
      }
    }

    // Best/worst patterns
    String? bestPattern;
    double bestWinRate = 0;
    String? worstPattern;
    double worstWinRate = 1;
    for (final entry in _patterns.entries) {
      final wins = entry.value['wins'] as int;
      final losses = entry.value['losses'] as int;
      final total = wins + losses;
      if (total < 2) continue;
      final wr = wins / total;
      if (wr > bestWinRate) { bestWinRate = wr; bestPattern = entry.key; }
      if (wr < worstWinRate) { worstWinRate = wr; worstPattern = entry.key; }
    }
    if (bestPattern != null) buf.writeln('\nMeilleur pattern: $bestPattern (${(bestWinRate * 100).toStringAsFixed(0)}% WR)');
    if (worstPattern != null && worstWinRate < 0.4) buf.writeln('Pattern a eviter: $worstPattern (${(worstWinRate * 100).toStringAsFixed(0)}% WR)');

    return buf.toString();
  }
}
