import 'notification_stream.dart';

class NotificationService {
  static bool suppressTradeNotifications = false;

  static void init() {}

  static void onTradingEnabled() {
    _push('Trading IA', 'Le mode trading a été activé', NotificationType.system);
  }

  static void onTradingDisabled() {
    _push('Trading IA', 'Le mode trading a été désactivé', NotificationType.system);
  }

  static void onTradeExecuted(String symbol, String side, double qty, double balance) {
    if (suppressTradeNotifications) return;
    final sideText = side.toUpperCase() == 'BUY' ? 'Achat' : 'Vente';
    _push(
      '$sideText $symbol',
      '$qty $symbol — Solde: ${balance.toStringAsFixed(2)} USDT',
      NotificationType.trade,
    );
  }

  static void show(String title, String body, {String? tag}) {
    _push(title, body, NotificationType.system);
  }

  static void showTradeAlert({
    required String symbol,
    required String action,
    required double confidence,
    required String reason,
  }) {
    _push(
      'Signal: $action $symbol',
      'Confiance: ${(confidence * 100).toStringAsFixed(0)}% — $reason',
      NotificationType.signal,
    );
  }

  static void _push(String title, String body, NotificationType type) {
    NotificationStream.instance.push(AppNotification(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
    ));
  }
}
