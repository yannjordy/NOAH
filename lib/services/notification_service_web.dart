class NotificationService {
  static bool suppressTradeNotifications = false;

  static void init() {}
  static void onTradingEnabled() {}
  static void onTradingDisabled() {}
  static void onTradeExecuted(String symbol, String side, double qty, double price) {}
  static void show(String title, String body, {String? tag}) {}
}
