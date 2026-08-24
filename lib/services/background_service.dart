import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
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
        eventAction: ForegroundTaskEventAction.repeat(60000), // every 60s
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.startService(
      notificationTitle: 'NOAH Trading',
      notificationText: 'Démarrage du monitoring...',
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
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.binance.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    validateStatus: (_) => true,
  ));

  // Track prices for alert detection
  final Map<String, double> _lastPrices = {};
  DateTime _lastAlertCheck = DateTime.now();

  static const _trackedSymbols = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'ADA', 'DOGE', 'DOT'];

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _updateNotification('Démarrage...');
    await _fetchAndNotify();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _fetchAndNotify();
  }

  Future<void> _fetchAndNotify() async {
    try {
      final resp = await _dio.get('/api/v3/ticker/24hr');
      if (resp.statusCode == 200 && resp.data is List) {
        final items = resp.data as List;
        final Map<String, double> currentPrices = {};
        final Map<String, double> currentPcts = {};

        for (final item in items) {
          final symbol = (item['symbol'] as String? ?? '').replaceAll('USDT', '');
          if (!_trackedSymbols.contains(symbol)) continue;
          final price = double.tryParse(item['lastPrice']?.toString() ?? '') ?? 0;
          final pct = double.tryParse(item['priceChangePercent']?.toString() ?? '') ?? 0;
          if (price > 0) {
            currentPrices[symbol] = price;
            currentPcts[symbol] = pct;
          }
        }

        // Detect significant price movements (> 3% since last check)
        final alerts = <String>[];
        for (final sym in _trackedSymbols) {
          final prev = _lastPrices[sym];
          final curr = currentPrices[sym];
          if (prev != null && curr != null && prev > 0) {
            final change = ((curr - prev) / prev) * 100;
            if (change.abs() >= 3) {
              final dir = change > 0 ? '📈' : '📉';
              alerts.add('$dir $sym: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%');
            }
          }
        }

        _lastPrices.clear();
        _lastPrices.addAll(currentPrices);

        // Build notification text
        final top3 = _trackedSymbols.take(3).map((s) {
          final p = currentPrices[s];
          final pct = currentPcts[s];
          if (p == null) return '';
          final sign = (pct ?? 0) >= 0 ? '+' : '';
          return '$s \$${p >= 1000 ? p.toStringAsFixed(0) : p.toStringAsFixed(2)} ($sign${(pct ?? 0).toStringAsFixed(1)}%)';
        }).where((s) => s.isNotEmpty).join(' | ');

        String notifText = top3.isNotEmpty ? top3 : 'Monitoring actif';

        // If there are alerts, show them
        if (alerts.isNotEmpty) {
          notifText = alerts.first;
        }

        _updateNotification(notifText);

        // Write data to a temp file for the main app to read
        await _writeTickerData(currentPrices, currentPcts);
      }
    } catch (_) {
      _updateNotification('Monitoring — en attente de connexion...');
    }
  }

  void _updateNotification(String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'NOAH Trading',
      notificationText: text,
    );
  }

  Future<void> _writeTickerData(Map<String, double> prices, Map<String, double> pcts) async {
    try {
      final data = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'prices': prices.map((k, v) => MapEntry(k, v)),
        'pcts': pcts.map((k, v) => MapEntry(k, v)),
      };
      final file = File('/data/data/com.noahtrading.app/noah_ticker.json');
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
