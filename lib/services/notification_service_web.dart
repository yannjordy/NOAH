import 'dart:js' as js;
import 'notification_stream.dart';

class NotificationService {
  static bool _initialized = false;
  static bool suppressTradeNotifications = true;

  static bool get _isSupported {
    try {
      return js.context.hasProperty('Notification');
    } catch (_) {
      return false;
    }
  }

  static void init() {
    if (_initialized) return;
    _initialized = true;
    if (_isSupported) _requestPermission();
  }

  static void _requestPermission() {
    try {
      js.context["Notification"].callMethod("requestPermission");
    } catch (e) {
      final notif = js.context['Notification'];
      final p = notif['permission'];
      if (p == 'granted') {
      } else if (p != 'denied') {
        notif.callMethod('requestPermission');
      }
    }
  }

  static void show(String title, String body, {String? tag}) {
    NotificationStream.instance.push(AppNotification(
      id: tag ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
    ));
    if (!_isSupported) return;
    try {
      final perm = js.context['Notification']['permission'];
      if (perm != 'granted') {
        js.context['Notification'].callMethod('requestPermission');
        return;
      }
    } catch (_) {
      return;
    }
    _fire(title, body, tag: tag);
  }

  static void _fire(String title, String body, {String? tag}) {
    try {
      final opts = js.JsObject.jsify({
        'body': body,
        'icon': '/favicon.png',
        'tag': tag ?? 'noah-trading',
        'renotify': true,
        'requireInteraction': true,
        'silent': false,
      });
      js.JsObject(js.context['Notification'], [title, opts]);
    } catch (_) {}
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
