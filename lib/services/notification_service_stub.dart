import 'local_notification_service.dart';

class NotificationService {
  static bool suppressTradeNotifications = true;

  static void init() {
    LocalNotificationService.init();
  }

  static void show(String title, String body, {String? tag}) {
    LocalNotificationService.show(title, body, tag: tag);
  }

  static void onTradingEnabled() {
    show('NOAH - Trading IA Actif',
        'Les agents gèrent votre portefeuille en temps réel.', tag: 'trading-active');
  }

  static void onTradingDisabled() {
    show('NOAH - Trading IA Désactivé',
        'Le trading automatique a été désactivé.', tag: 'trading-active');
  }

  static void onTradeExecuted(String symbol, String side, double qty, double price) {
    if (suppressTradeNotifications) return;
    show('Trade Exécuté - $symbol',
        '${side.toUpperCase()} $qty $symbol à \$${price.toStringAsFixed(2)}',
        tag: 'trade-$symbol');
  }

  static void onSignalDetected(String symbol, String type, double confidence) {
    show('Signal $type - $symbol',
        '${(confidence * 100).toInt()}% de confiance. Consultez NOAH.',
        tag: 'signal-$symbol');
  }
}
