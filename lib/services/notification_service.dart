class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> showTradeAlert({
    required String symbol,
    required String action,
    required double confidence,
    required String reason,
  }) async {
    // In-app alerts handled by SignalService + PendingSignalsScreen
  }

  Future<void> showProfitAlert(double profitPct) async {
    // In-app alerts handled by SignalService
  }
}
