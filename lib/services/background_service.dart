import 'dart:async';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}
}

class BackgroundService {
  static bool _running = false;
  static bool get isRunning => _running;

  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'noah_trading',
        channelName: 'NOAH Trading Service',
        channelDescription: 'Exécute le trading automatique en arrière-plan',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    if (_running) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());

    final serviceRequest = await FlutterForegroundTask.startService(
      notificationTitle: 'NOAH Trading Actif',
      notificationText: 'Le trading automatique est en cours...',
    );

    _running = serviceRequest is ServiceRequestSuccess;
    return _running;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    _running = false;
  }

  static Future<bool> get isServiceRunning async {
    return await FlutterForegroundTask.isRunningService;
  }

  static void sendData(Object data) {
    FlutterForegroundTask.sendDataToTask(data);
  }
}
