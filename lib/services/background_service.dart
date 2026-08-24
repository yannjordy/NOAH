import 'dart:async';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  static const _channelId = 'noah_monitoring';
  static const _channelName = 'NOAH Trading';
  static const _channelDesc = 'Trading actif en arrière-plan';

  static bool _running = false;

  static bool get isRunning => _running;

  static void start() {
    if (_running) return;
    if (!Platform.isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: _channelDesc,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        showWhen: false,
        showBadge: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.startService(
      notificationTitle: 'NOAH Trading',
      notificationText: 'Trading actif — surveillance des marchés',
    );
    _running = true;
  }

  static Future<void> stop() async {
    if (!_running) return;
    await FlutterForegroundTask.stopService();
    _running = false;
  }

  @pragma('vm:entry-point')
  static void startCallback() {
    FlutterForegroundTask.setTaskHandler(_BackgroundTaskHandler());
  }
}

class _BackgroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _updateNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateNotification();
  }

  void _updateNotification() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'NOAH Trading',
      notificationText: 'Trading actif — ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
