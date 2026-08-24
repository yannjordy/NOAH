import 'dart:async';
import 'dart:io';

class BackgroundService {
  static bool _running = false;
  static bool get isRunning => _running;
  static Timer? _timer;

  static void start() {
    if (_running) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Periodic background task placeholder
    });
  }

  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }
}
