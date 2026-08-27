class NotificationService {
  static bool suppressTradeNotifications = false;

  static void init() {}
  static void onTradingEnabled() {}
  static void onTradingDisabled() {}
  static void onTradeExecuted(String symbol, String side, double qty, double balance) {}
  static void show(String title, String body, {String? tag}) {}
  static void showTradeAlert({
    required String symbol,
    required String action,
    required double confidence,
    required String reason,
  }) {}
}
