import 'dart:async';
import 'package:dio/dio.dart';

class CryptoNewsArticle {
  final String title;
  final String link;
  final String description;
  final String source;
  final String timeAgo;
  final DateTime? pubDate;

  CryptoNewsArticle({
    required this.title,
    required this.link,
    required this.description,
    required this.source,
    required this.timeAgo,
    this.pubDate,
  });

  factory CryptoNewsArticle.fromJson(Map<String, dynamic> json) {
    return CryptoNewsArticle(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      description: json['description'] ?? '',
      source: json['source'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
      pubDate: json['pubDate'] != null ? DateTime.tryParse(json['pubDate']) : null,
    );
  }
}

class CryptoNewsService {
  static const String _baseUrl = 'https://free-crypto-news.vercel.app/api';
  final Dio _dio;
  List<CryptoNewsArticle> _articles = [];
  Timer? _refreshTimer;

  List<CryptoNewsArticle> get articles => _articles;

  CryptoNewsService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (_) => true,
        ));

  Future<List<CryptoNewsArticle>> fetchNews({int limit = 20}) async {
    try {
      final resp = await _dio.get('$_baseUrl/news?limit=$limit');
      if (resp.statusCode == 200 && resp.data is Map) {
        final articlesList = resp.data['articles'] as List? ?? [];
        _articles = articlesList
            .map((a) => CryptoNewsArticle.fromJson(a as Map<String, dynamic>))
            .toList();
        return _articles;
      }
    } catch (_) {}
    return _articles;
  }

  Future<List<CryptoNewsArticle>> searchNews(String query, {int limit = 10}) async {
    try {
      final resp = await _dio.get('$_baseUrl/search?q=$query&limit=$limit');
      if (resp.statusCode == 200 && resp.data is Map) {
        final articlesList = resp.data['articles'] as List? ?? [];
        return articlesList
            .map((a) => CryptoNewsArticle.fromJson(a as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<CryptoNewsArticle>> fetchBreaking({int limit = 10}) async {
    try {
      final resp = await _dio.get('$_baseUrl/breaking?limit=$limit');
      if (resp.statusCode == 200 && resp.data is Map) {
        final articlesList = resp.data['articles'] as List? ?? [];
        return articlesList
            .map((a) => CryptoNewsArticle.fromJson(a as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> fetchSentiment({String asset = 'BTC'}) async {
    try {
      final resp = await _dio.get('$_baseUrl/sentiment?asset=$asset');
      if (resp.statusCode == 200 && resp.data is Map) {
        return resp.data;
      }
    } catch (_) {}
    return {'sentiment': 'neutral', 'score': 0, 'confidence': 0};
  }

  void startAutoRefresh({Duration interval = const Duration(minutes: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchNews());
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void dispose() {
    stopAutoRefresh();
  }
}
