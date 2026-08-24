import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_stream.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool vibrateEnabled = true;
  static bool soundEnabled = true;

  static const _channelId = 'noah_trading';
  static const _channelName = 'NOAH Trading';
  static const _channelDesc = 'Notifications de trading et alertes';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Request POST_NOTIFICATIONS permission on Android 13+ (API 33)
    if (Platform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    await androidPlugin
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));
  }

  static void show(String title, String body, {String? tag}) {
    if (!_initialized) return;

    NotificationStream.instance.push(AppNotification(
      id: tag ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
    ));

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: vibrateEnabled,
      playSound: soundEnabled,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _plugin.show(
      id: tag?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: tag,
    );
  }
}
