import 'dart:async';

class PendingSignal {
  final String symbol;
  final String action;
  final double confidence;
  final double positionSizePct;
  final String reason;
  final DateTime createdAt;
  final Map<String, dynamic> technicals;
  final Map<String, dynamic> agentReport;

  PendingSignal({
    required this.symbol,
    required this.action,
    required this.confidence,
    required this.positionSizePct,
    required this.reason,
    required this.technicals,
    required this.agentReport,
  }) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt).inMinutes > 5;
}

class SignalService {
  final _pendingSignals = <PendingSignal>[];
  final _signalController = StreamController<List<PendingSignal>>.broadcast();
  final _alertController = StreamController<PendingSignal>.broadcast();

  Stream<List<PendingSignal>> get pendingSignals => _signalController.stream;
  Stream<PendingSignal> get onAlert => _alertController.stream;

  List<PendingSignal> get currentPending => List.unmodifiable(_pendingSignals);

  void addSignal({
    required String symbol,
    required String action,
    required double confidence,
    required double positionSizePct,
    required String reason,
    required Map<String, dynamic> technicals,
    required Map<String, dynamic> agentReport,
  }) {
    // Remove expired signals
    _pendingSignals.removeWhere((s) => s.isExpired);

    // Don't add duplicate for same symbol
    _pendingSignals.removeWhere((s) => s.symbol == symbol);

    final signal = PendingSignal(
      symbol: symbol,
      action: action,
      confidence: confidence,
      positionSizePct: positionSizePct,
      reason: reason,
      technicals: technicals,
      agentReport: agentReport,
    );

    _pendingSignals.add(signal);
    _signalController.add(_pendingSignals);
    _alertController.add(signal);
  }

  void approveSignal(PendingSignal signal) {
    _pendingSignals.remove(signal);
    _signalController.add(_pendingSignals);
  }

  void rejectSignal(PendingSignal signal) {
    _pendingSignals.remove(signal);
    _signalController.add(_pendingSignals);
  }

  void clearAll() {
    _pendingSignals.clear();
    _signalController.add(_pendingSignals);
  }

  void dispose() {
    _signalController.close();
    _alertController.close();
  }
}
