import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:io';

class BackgroundService {
  static final Map<String, Timer> _tasks = {};
  static final Map<String, Duration> _intervals = {};
  static bool _running = false;
  static Isolate? _isolate;
  static ReceivePort? _receivePort;

  static bool get isRunning => _running;

  static void start() {
    if (_running) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _running = true;
    _receivePort = ReceivePort();

    _receivePort!.listen((message) {
      if (message is String) {
        dev.log('BackgroundService: $message');
      }
    });

    _spawnIsolate();
    dev.log('BackgroundService: started');
  }

  static void _spawnIsolate() async {
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort?.sendPort);
  }

  static void _isolateEntry(SendPort? sendPort) {
    Timer.periodic(const Duration(seconds: 5), (_) {
      sendPort?.send('isolate heartbeat ${DateTime.now()}');
    });
  }

  static void registerTask(String name, Duration interval, Function callback) {
    if (_tasks.containsKey(name)) {
      _tasks[name]!.cancel();
    }
    _intervals[name] = interval;
    _tasks[name] = Timer.periodic(interval, (_) {
      try {
        callback();
      } catch (e, stackTrace) {
        dev.log(
          'BackgroundService: error in task "$name"',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
    dev.log('BackgroundService: registered task "$name" every ${interval.inSeconds}s');
  }

  static void unregisterTask(String name) {
    _tasks[name]?.cancel();
    _tasks.remove(name);
    _intervals.remove(name);
    dev.log('BackgroundService: unregistered task "$name"');
  }

  static List<String> get registeredTasks => _tasks.keys.toList();

  static Future<void> stop() async {
    if (!_running) return;
    _running = false;

    for (final entry in _tasks.entries) {
      entry.value.cancel();
      dev.log('BackgroundService: cancelled task "${entry.key}"');
    }
    _tasks.clear();
    _intervals.clear();

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    _receivePort?.close();
    _receivePort = null;

    dev.log('BackgroundService: stopped');
  }
}
