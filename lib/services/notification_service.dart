import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showTradeAlert({
    required String symbol,
    required String action,
    required double confidence,
    required String reason,
  }) async {
    if (!_initialized) await init();

    final title = action == 'BUY' ? '🟢 Signal d\'achat' : '🔴 Signal de vente';
    final body = '$symbol — Confiance: ${(confidence * 100).toStringAsFixed(0)}%\n$reason';

    const androidDetails = AndroidNotificationDetails(
      'noah_trades',
      'Signaux Trading',
      channelDescription: 'Alertes de trading NOAH',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch.remainder(100000), title, body, details);
  }

  Future<void> showProfitAlert(double profitPct) async {
    if (!_initialized) await init();

    final title = '🎯 Profit atteint!';
    final body = '+${profitPct.toStringAsFixed(1)}% de profit';

    const androidDetails = AndroidNotificationDetails(
      'noah_profits',
      'Alertes Profit',
      channelDescription: 'Alertes de profit NOAH',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch.remainder(100000), title, body, details);
  }
}
