import 'dart:math';
import 'package:dio/dio.dart';

class WebResearchResult {
  final String source;
  final String title;
  final String url;
  final String snippet;
  final double relevance;
  final String category;

  WebResearchResult({
    required this.source,
    required this.title,
    required this.url,
    required this.snippet,
    this.relevance = 0.5,
    this.category = 'general',
  });
}

class WebResearchService {
  final Dio _dio;
  int _topicIndex = 0;

  static const _curiosityTopics = [
    'new trading strategy',
    'crypto market trend',
    'trading bot open source',
    'algorithmic trading',
    'DeFi yield',
    'market making bot',
    'grid trading',
    'arbitrage strategy',
    'quantitative finance',
    'machine learning trading',
    'AI trading',
    'crypto news',
  ];

  WebResearchService({Dio? dio}) : _dio = dio ?? Dio();

  String get nextTopic {
    final topic = _curiosityTopics[_topicIndex % _curiosityTopics.length];
    _topicIndex++;
    return topic;
  }

  void resetTopicCycle() {
    _topicIndex = 0;
  }

  Future<List<WebResearchResult>> searchAll(String symbol) async {
    final results = <WebResearchResult>[];
    final topic = nextTopic;
    await Future.wait([
      _searchGitHub(symbol, results),
      _searchGitHubTrending(topic, results),
      _searchGitHubTopic(topic, results),
      _searchFreqtrade(symbol, results),
      _searchHummingbot(symbol, results),
      _searchPionex(symbol, results),
      _searchTradingView(symbol, results),
    ]);
    // Shuffle to avoid same order every time — keeps it fresh
    results.shuffle(Random());
    return results;
  }

  Future<void> _searchGitHub(String symbol, List<WebResearchResult> results) async {
    try {
      final keywords = _keywordsFor(symbol);
      final resp = await _dio.get(
        'https://api.github.com/search/repositories',
        queryParameters: {'q': '$keywords trading strategy', 'sort': 'stars', 'per_page': 5},
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );
      if (resp.statusCode == 200 && resp.data['items'] is List) {
        for (final item in (resp.data['items'] as List).take(3)) {
          results.add(WebResearchResult(
            source: 'GitHub',
            title: item['full_name'] ?? '',
            url: item['html_url'] ?? '',
            snippet: item['description'] ?? '⭐ ${item['stargazers_count']} stars',
            relevance: 0.7,
            category: 'strategy',
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _searchGitHubTrending(String topic, List<WebResearchResult> results) async {
    try {
      final resp = await _dio.get(
        'https://api.github.com/search/repositories',
        queryParameters: {'q': topic, 'sort': 'stars', 'per_page': 5},
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );
      if (resp.statusCode == 200 && resp.data['items'] is List) {
        for (final item in (resp.data['items'] as List).take(2)) {
          results.add(WebResearchResult(
            source: 'GitHub',
            title: '🔍 ${item['full_name']}',
            url: item['html_url'] ?? '',
            snippet: item['description'] ?? '⭐ ${item['stargazers_count']} stars — ${item['language'] ?? 'N/A'}',
            relevance: 0.6,
            category: 'curiosity',
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _searchGitHubTopic(String topic, List<WebResearchResult> results) async {
    try {
      final resp = await _dio.get(
        'https://api.github.com/search/repositories',
        queryParameters: {'q': topic + ' crypto', 'sort': 'updated', 'per_page': 3},
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );
      if (resp.statusCode == 200 && resp.data['items'] is List) {
        for (final item in (resp.data['items'] as List).take(2)) {
          results.add(WebResearchResult(
            source: 'GitHub',
            title: '🆕 ${item['full_name']}',
            url: item['html_url'] ?? '',
            snippet: 'Récemment mis à jour — ${item['description'] ?? item['language'] ?? ''}',
            relevance: 0.5,
            category: 'discovery',
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _searchFreqtrade(String symbol, List<WebResearchResult> results) async {
    try {
      final resp = await _dio.get(
        'https://www.freqtrade.io/en/stable/',
        options: Options(responseType: ResponseType.plain),
      );
      if (resp.statusCode == 200) {
        final body = resp.data as String;
        results.add(WebResearchResult(
          source: 'Freqtrade',
          title: '📘 Freqtrade — Stratégies dispo',
          url: 'https://www.freqtrade.io/en/stable/',
          snippet: _stripHtml(body).substring(0, 200),
          relevance: 0.5,
          category: 'documentation',
        ));
      }
    } catch (_) {
      results.add(WebResearchResult(
        source: 'Freqtrade',
        title: '📘 Stratégies Freqtrade',
        url: 'https://www.freqtrade.io/en/stable/',
        snippet: 'Framework open-source de trading algo. Stratégies custom en Python avec backtesting.',
        relevance: 0.5,
        category: 'documentation',
      ));
    }
  }

  Future<void> _searchHummingbot(String symbol, List<WebResearchResult> results) async {
    try {
      final resp = await _dio.get(
        'https://docs.hummingbot.org/',
        options: Options(responseType: ResponseType.plain),
      );
      if (resp.statusCode == 200) {
        final body = resp.data as String;
        results.add(WebResearchResult(
          source: 'Hummingbot',
          title: '🐝 Hummingbot — Market Making',
          url: 'https://docs.hummingbot.org/',
          snippet: _stripHtml(body).substring(0, 200),
          relevance: 0.5,
          category: 'documentation',
        ));
      }
    } catch (_) {
      results.add(WebResearchResult(
        source: 'Hummingbot',
        title: '🐝 Stratégies Hummingbot',
        url: 'https://docs.hummingbot.org/',
        snippet: 'Plateforme de market making cross-exchange. Stratégies : pure market making, cross-exchange market making, arbitrage.',
        relevance: 0.5,
        category: 'documentation',
      ));
    }
  }

  Future<void> _searchPionex(String symbol, List<WebResearchResult> results) async {
    try {
      final resp = await _dio.get(
        'https://www.pionex.com/blog/',
        options: Options(responseType: ResponseType.plain),
      );
      if (resp.statusCode == 200) {
        final body = resp.data as String;
        results.add(WebResearchResult(
          source: 'Pionex',
          title: '🤖 Pionex Blog — Bots',
          url: 'https://www.pionex.com/blog/',
          snippet: _stripHtml(body).substring(0, 200),
          relevance: 0.5,
          category: 'tools',
        ));
      }
    } catch (_) {
      results.add(WebResearchResult(
        source: 'Pionex',
        title: '🤖 Bots Pionex',
        url: 'https://www.pionex.com/',
        snippet: 'Exchange avec bots intégrés : grid bot, DCA bot, arbitrage bot, infinity grid.',
        relevance: 0.5,
        category: 'tools',
      ));
    }
  }

  Future<void> _searchTradingView(String symbol, List<WebResearchResult> results) async {
    try {
      final resp = await _dio.get(
        'https://www.tradingview.com/search/',
        queryParameters: {'q': symbol, 'type': 'idea'},
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      if (resp.statusCode == 200) {
        final body = resp.data as String;
        results.add(WebResearchResult(
          source: 'TradingView',
          title: '📊 Idées TradingView pour $symbol',
          url: 'https://www.tradingview.com/search/?q=$symbol&type=idea',
          snippet: _stripHtml(body).substring(0, 200),
          relevance: 0.6,
          category: 'analysis',
        ));
      }
    } catch (_) {
      results.add(WebResearchResult(
        source: 'TradingView',
        title: '📊 Analyses $symbol',
        url: 'https://www.tradingview.com/symbols/$symbol/ideas/',
        snippet: 'Plateforme de charting avec idées et analyses de la communauté.',
        relevance: 0.6,
        category: 'analysis',
      ));
    }
  }

  String _stripHtml(String html) {
    final withoutTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final decoded = withoutTags
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return decoded.length > 300 ? decoded.substring(0, 300) : decoded;
  }

  String _keywordsFor(String symbol) {
    final base = symbol.replaceAll('USDT', '').replaceAll('USD', '');
    if (base == 'BTC') return 'bitcoin';
    if (base == 'ETH') return 'ethereum';
    if (base == 'SOL') return 'solana';
    if (base == 'BNB') return 'binance coin';
    if (base == 'XRP') return 'ripple';
    if (base == 'ADA') return 'cardano';
    if (base == 'DOGE') return 'dogecoin';
    if (base == 'DOT') return 'polkadot';
    if (base == 'AVAX') return 'avalanche';
    if (base == 'MATIC') return 'polygon';
    return base;
  }
}
