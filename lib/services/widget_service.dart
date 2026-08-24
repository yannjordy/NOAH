import 'dart:convert';

class WidgetService {
  static Future<void> init() async {}

  static Future<void> pushMarketData({
    required List<Map<String, dynamic>> assets,
    required double portfolioValue,
    required double portfolioPnl,
    required int positionsCount,
  }) async {}

  static Future<void> pushPortfolioData({
    required double portfolioValue,
    required double portfolioPnl,
    required int positionsCount,
  }) async {}

  static Future<void> pushHistoryData({
    required List<Map<String, dynamic>> trades,
  }) async {}

  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {}
}
