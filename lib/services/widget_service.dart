import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const _marketWidget = 'NoahWidgetProvider';
  static const _portfolioWidget = 'NoahWidgetPortfolio';
  static const _historyWidget = 'NoahWidgetHistory';

  static const _trackedSymbols = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP'];

  static Future<void> init() async {
    await HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  /// Push market data to the market widget
  static Future<void> pushMarketData({
    required List<Map<String, dynamic>> assets,
    required double portfolioValue,
    required double portfolioPnl,
    required int positionsCount,
  }) async {
    final data = jsonEncode({
      'assets': assets,
      'portfolioValue': portfolioValue,
      'portfolioPnl': portfolioPnl,
      'positionsCount': positionsCount,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await HomeWidget.saveWidgetData('cached_data', data);
    await HomeWidget.updateWidget(
      name: _marketWidget,
      androidName: _marketWidget,
    );
  }

  /// Push portfolio data to the portfolio widget
  static Future<void> pushPortfolioData({
    required double portfolioValue,
    required double portfolioPnl,
    required int positionsCount,
  }) async {
    final data = jsonEncode({
      'portfolioValue': portfolioValue,
      'portfolioPnl': portfolioPnl,
      'positionsCount': positionsCount,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'assets': const <Map<String, dynamic>>[],
    });

    await HomeWidget.saveWidgetData('cached_data', data);
    await HomeWidget.updateWidget(
      name: _portfolioWidget,
      androidName: _portfolioWidget,
    );
  }

  /// Push trade history to the history widget
  static Future<void> pushHistoryData({
    required List<Map<String, dynamic>> trades,
  }) async {
    final data = jsonEncode({
      'trades': trades.take(3).toList(),
    });

    await HomeWidget.saveWidgetData('history_data', data);
    await HomeWidget.updateWidget(
      name: _historyWidget,
      androidName: _historyWidget,
    );
  }

  /// Called by WorkManager / background task to refresh widget data
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.binance.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (_) => true,
      ));

      final resp = await dio.get('/api/v3/ticker/24hr');
      if (resp.statusCode == 200 && resp.data is List) {
        final items = resp.data as List;
        final assets = <Map<String, dynamic>>[];

        for (final item in items) {
          final symbol = (item['symbol'] as String? ?? '').replaceAll('USDT', '');
          if (!_trackedSymbols.contains(symbol)) continue;
          final price = double.tryParse(item['lastPrice']?.toString() ?? '') ?? 0;
          final pct = double.tryParse(item['priceChangePercent']?.toString() ?? '') ?? 0;
          if (price > 0) {
            assets.add({
              'symbol': symbol,
              'price': price,
              'change24h': pct,
            });
          }
        }

        // Read cached portfolio data if available
        final cachedStr = await HomeWidget.getWidgetData<String>('cached_data');
        double portfolioValue = 0;
        double portfolioPnl = 0;
        int positionsCount = 0;
        if (cachedStr != null) {
          try {
            final cached = jsonDecode(cachedStr) as Map;
            portfolioValue = (cached['portfolioValue'] as num?)?.toDouble() ?? 0;
            portfolioPnl = (cached['portfolioPnl'] as num?)?.toDouble() ?? 0;
            positionsCount = (cached['positionsCount'] as num?)?.toInt() ?? 0;
          } catch (_) {}
        }

        final data = jsonEncode({
          'assets': assets,
          'portfolioValue': portfolioValue,
          'portfolioPnl': portfolioPnl,
          'positionsCount': positionsCount,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        await HomeWidget.saveWidgetData('cached_data', data);
      }
    } catch (_) {}

    // Update all widgets
    await HomeWidget.updateWidget(name: _marketWidget, androidName: _marketWidget);
    await HomeWidget.updateWidget(name: _portfolioWidget, androidName: _portfolioWidget);
    await HomeWidget.updateWidget(name: _historyWidget, androidName: _historyWidget);
  }
}
