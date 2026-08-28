import 'dart:async';
import 'package:dio/dio.dart';

class CryptoNewsArticle {
  final String title;
  final String link;
  final String description;
  final String source;
  final String timeAgo;
  final DateTime? pubDate;
  final String? thumbnail;
  final String category;

  CryptoNewsArticle({
    required this.title,
    required this.link,
    required this.description,
    required this.source,
    required this.timeAgo,
    this.pubDate,
    this.thumbnail,
    this.category = 'Crypto',
  });

  factory CryptoNewsArticle.fromRss(Map<String, dynamic> item, String source) {
    final pubDateStr = item['pubDate'] as String? ?? '';
    DateTime? pubDate;
    if (pubDateStr.isNotEmpty) {
      try { pubDate = DateTime.parse(pubDateStr); } catch (_) {}
    }

    String timeAgo = '';
    if (pubDate != null) {
      final diff = DateTime.now().difference(pubDate);
      if (diff.inMinutes < 60) timeAgo = '${diff.inMinutes}m';
      else if (diff.inHours < 24) timeAgo = '${diff.inHours}h';
      else timeAgo = '${diff.inDays}j';
    }

    String desc = (item['description'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (desc.length > 200) desc = '${desc.substring(0, 200)}...';

    final categories = (item['categories'] as List?)?.cast<String>() ?? [];
    final category = categories.isNotEmpty ? categories.first : 'Crypto';

    return CryptoNewsArticle(
      title: item['title'] ?? '',
      link: item['link'] ?? '',
      description: desc,
      source: source,
      timeAgo: timeAgo,
      pubDate: pubDate,
      thumbnail: item['thumbnail'] as String?,
      category: category,
    );
  }
}

class CryptoNewsService {
  static const String _rss2jsonBase = 'https://api.rss2json.com/v1/api.json';
  static const Map<String, String> _feeds = {
    'CoinTelegraph': 'https://cointelegraph.com/rss',
    'CoinDesk': 'https://www.coindesk.com/arc/outboundfeeds/rss/',
  };
  static const List<String> _cryptoKeywords = [
    'bitcoin', 'btc', 'ethereum', 'eth', 'crypto', 'defi', 'nft',
    'blockchain', 'solana', 'sol', 'altcoin', 'token', 'web3',
  ];

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

  Future<List<CryptoNewsArticle>> fetchNews({int limit = 30}) async {
    final allArticles = <CryptoNewsArticle>[];

    for (final entry in _feeds.entries) {
      try {
        final resp = await _dio.get(
          '$_rss2jsonBase?rss_url=${Uri.encodeComponent(entry.value)}',
        );
        if (resp.statusCode == 200 && resp.data is Map) {
          final items = resp.data['items'] as List? ?? [];
          for (final item in items) {
            allArticles.add(CryptoNewsArticle.fromRss(
              item as Map<String, dynamic>,
              entry.key,
            ));
          }
        }
      } catch (_) {}
    }

    // Filter crypto-related only
    final cryptoArticles = allArticles.where((a) {
      final text = '${a.title} ${a.description} ${a.category}'.toLowerCase();
      return _cryptoKeywords.any((k) => text.contains(k));
    }).toList();

    // Sort by date (most recent first)
    cryptoArticles.sort((a, b) {
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    _articles = cryptoArticles.take(limit).toList();
    return _articles;
  }

  Future<Map<String, dynamic>> fetchSentiment({String asset = 'BTC'}) async {
    // Simple sentiment from recent news volume and keywords
    try {
      if (_articles.isEmpty) await fetchNews(limit: 20);

      int bullish = 0;
      int bearish = 0;
      for (final a in _articles) {
        final text = '${a.title} ${a.description}'.toLowerCase();
        if (text.contains(RegExp(r'surge|rally|gain|bull|up|rise|soar|record|high'))) {
          bullish++;
        }
        if (text.contains(RegExp(r'crash|drop|fall|bear|down|plunge|loss|low|dump'))) {
          bearish++;
        }
      }

      final total = bullish + bearish;
      if (total == 0) return {'sentiment': 'neutral', 'score': 0.0, 'confidence': 0.3};

      final score = (bullish - bearish) / total;
      final confidence = (total / _articles.length).clamp(0.0, 1.0);

      String sentiment = 'neutral';
      if (score > 0.2) sentiment = 'bullish';
      else if (score < -0.2) sentiment = 'bearish';

      return {
        'sentiment': sentiment,
        'score': score,
        'confidence': confidence,
        'bullish': bullish,
        'bearish': bearish,
        'total': _articles.length,
      };
    } catch (_) {
      return {'sentiment': 'neutral', 'score': 0.0, 'confidence': 0.0};
    }
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
