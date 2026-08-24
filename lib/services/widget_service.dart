import 'dart:convert';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const _marketWidget = 'NoahWidgetProvider';
  static const _portfolioWidget = 'NoahWidgetPortfolio';
  static const _historyWidget = 'NoahWidgetHistory';

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

  /// Called by WorkManager in background to refresh widget data
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    await HomeWidget.updateWidget(
      name: _marketWidget,
      androidName: _marketWidget,
    );
    await HomeWidget.updateWidget(
      name: _portfolioWidget,
      androidName: _portfolioWidget,
    );
    await HomeWidget.updateWidget(
      name: _historyWidget,
      androidName: _historyWidget,
    );
  }
}
