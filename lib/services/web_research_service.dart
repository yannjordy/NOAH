import 'dart:async';

import 'package:dio/dio.dart';

class WebResearchResult {
  final String source;
  final String title;
  final String snippet;
  final String category;
  final DateTime timestamp;
  final double? sentimentScore;

  WebResearchResult({
    required this.source,
    required this.title,
    this.snippet = '',
    this.category = 'general',
    DateTime? timestamp,
    this.sentimentScore,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'source': source,
        'title': title,
        'snippet': snippet,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
        'sentimentScore': sentimentScore,
      };

  factory WebResearchResult.fromJson(Map<String, dynamic> json) {
    return WebResearchResult(
      source: json['source'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
    );
  }
}

class _CacheEntry {
  final List<WebResearchResult> results;
  final DateTime expiry;

  _CacheEntry(this.results, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class WebResearchService {
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 10);

  int _topicIndex = 0;
  static const _topics = [
    'crypto market',
    'DeFi trends',
    'institutional adoption',
    'regulation news',
    'on-chain analytics',
  ];

  String get nextTopic => _topics[_topicIndex++ % _topics.length];

  final Dio _dio;
  final Map<String, _CacheEntry> _cache = {};

  WebResearchService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _requestTimeout,
              receiveTimeout: _requestTimeout,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'NOAH-Trading-Bot/1.0',
              },
            ));

  String _cacheKey(String method, String symbol) => '$method:$symbol';

  List<WebResearchResult>? _getCached(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.results;
    }
    if (entry != null) {
      _cache.remove(key);
    }
    return null;
  }

  void _setCache(String key, List<WebResearchResult> results) {
    _cache[key] = _CacheEntry(results, DateTime.now().add(_cacheTtl));
  }

  Future<Response?> _safeGet(String url,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParameters);
      if (response.statusCode == 200) {
        return response;
      }
    } on DioException {
    } catch (_) {}
    return null;
  }

  Future<List<WebResearchResult>> _fetchCoinGeckoData(String symbol) async {
    final results = <WebResearchResult>[];

    final marketResponse = await _safeGet(
      'https://api.coingecko.com/api/v3/coins/${symbol.toLowerCase()}',
      queryParameters: {
        'localization': false,
        'tickers': false,
        'market_data': true,
        'community_data': true,
        'developer_data': false,
        'sparkline': false,
      },
    );

    if (marketResponse?.data is Map<String, dynamic>) {
      final data = marketResponse!.data as Map<String, dynamic>;
      final marketData = data['market_data'] as Map<String, dynamic>?;
      final communityData = data['community_data'] as Map<String, dynamic>?;
      final description =
          (data['description'] as Map<String, dynamic>?)?['en'] as String?;

      if (marketData != null) {
        final price =
            (marketData['current_price'] as Map<String, dynamic>?)?['usd'];
        final change24h =
            (marketData['price_change_percentage_24h'] as num?)?.toDouble();
        final marketCap =
            (marketData['market_cap'] as Map<String, dynamic>?)?['usd'];
        final volume =
            (marketData['total_volume'] as Map<String, dynamic>?)?['usd'];
        final ath =
            (marketData['ath'] as Map<String, dynamic>?)?['usd'];
        final athChange =
            (marketData['ath_change_percentage'] as Map<String, dynamic>?)?['usd'];

        if (price != null) {
          results.add(WebResearchResult(
            source: 'CoinGecko',
            title: '${symbol.toUpperCase()} Price: \$${_formatNumber(price)}',
            snippet:
                '24h change: ${change24h != null ? '${change24h.toStringAsFixed(2)}%' : 'N/A'} | '
                'Market Cap: ${marketCap != null ? '\$${_formatLargeNumber(marketCap)}' : 'N/A'} | '
                'Volume 24h: ${volume != null ? '\$${_formatLargeNumber(volume)}' : 'N/A'}',
            category: 'news',
          ));
        }

        if (ath != null && athChange != null) {
          results.add(WebResearchResult(
            source: 'CoinGecko',
            title: '${symbol.toUpperCase()} ATH Analysis',
            snippet:
                'All-time high: \$${_formatNumber(ath)} | '
                'From ATH: ${athChange.toStringAsFixed(2)}% | '
                'Distance from ATH indicates ${athChange > -10 ? 'strong momentum' : 'potential recovery zone'}',
            category: 'sentiment',
          ));
        }

        final sparkline = marketData['sparkline_7d'] as Map<String, dynamic>?;
        final priceData = sparkline?['price'] as List?;
        if (priceData != null && priceData.length >= 2) {
          final firstPrice = (priceData.first as num).toDouble();
          final lastPrice = (priceData.last as num).toDouble();
          final weekChange = ((lastPrice - firstPrice) / firstPrice) * 100;
          results.add(WebResearchResult(
            source: 'CoinGecko',
            title: '${symbol.toUpperCase()} 7-Day Trend',
            snippet:
                'Weekly change: ${weekChange.toStringAsFixed(2)}% | '
                'Trend: ${weekChange > 2 ? 'Bullish' : weekChange < -2 ? 'Bearish' : 'Sideways'}',
            category: 'sentiment',
          ));
        }
      }

      if (communityData != null) {
        final twitterFollowers = communityData['twitter_followers'] as int?;
        final redditSubscribers = communityData['reddit_subscribers'] as int?;
        final telegramUsers =
            communityData['telegram_channel_user_count'] as int?;

        if (twitterFollowers != null || redditSubscribers != null) {
          results.add(WebResearchResult(
            source: 'CoinGecko',
            title: '${symbol.toUpperCase()} Community Metrics',
            snippet:
                'Twitter: ${twitterFollowers != null ? _formatLargeNumber(twitterFollowers) : 'N/A'} | '
                'Reddit: ${redditSubscribers != null ? _formatLargeNumber(redditSubscribers) : 'N/A'} | '
                'Telegram: ${telegramUsers != null ? _formatLargeNumber(telegramUsers) : 'N/A'}',
            category: 'sentiment',
          ));
        }
      }

      if (description != null && description.isNotEmpty) {
        final cleanDesc = description.replaceAll(RegExp(r'<[^>]*>'), '');
        final snippet = cleanDesc.length > 200
            ? '${cleanDesc.substring(0, 200)}...'
            : cleanDesc;
        results.add(WebResearchResult(
          source: 'CoinGecko',
          title: '${symbol.toUpperCase()} Overview',
          snippet: snippet,
          category: 'macro',
        ));
      }
    }

    return results;
  }

  Future<List<WebResearchResult>> _fetchCoinCapData(String symbol) async {
    final results = <WebResearchResult>[];
    final id = _symbolToCoinCapId(symbol);

    final assetResponse =
        await _safeGet('https://api.coincap.io/v2/assets/$id');

    if (assetResponse?.data is Map<String, dynamic>) {
      final data = (assetResponse!.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
      if (data != null) {
        final priceUsd = double.tryParse(data['priceUsd'] as String? ?? '');
        final marketCapUsd =
            double.tryParse(data['marketCapUsd'] as String? ?? '');
        final volumeUsd24h =
            double.tryParse(data['volumeUsd24h'] as String? ?? '');
        final changePercent24h =
            double.tryParse(data['changePercent24h'] as String? ?? '');
        final supply = double.tryParse(data['supply'] as String? ?? '');
        final maxSupply = double.tryParse(data['maxSupply'] as String? ?? '');

        if (priceUsd != null) {
          results.add(WebResearchResult(
            source: 'CoinCap',
            title: '${symbol.toUpperCase()} Market Data',
            snippet:
                'Price: \$${_formatNumber(priceUsd)} | '
                '24h: ${changePercent24h != null ? '${changePercent24h.toStringAsFixed(2)}%' : 'N/A'} | '
                'MCap: ${marketCapUsd != null ? '\$${_formatLargeNumber(marketCapUsd)}' : 'N/A'} | '
                'Vol: ${volumeUsd24h != null ? '\$${_formatLargeNumber(volumeUsd24h)}' : 'N/A'}',
            category: 'news',
          ));
        }

        if (supply != null && maxSupply != null && maxSupply > 0) {
          final supplyPct = (supply / maxSupply) * 100;
          results.add(WebResearchResult(
            source: 'CoinCap',
            title: '${symbol.toUpperCase()} Supply Analysis',
            snippet:
                'Circulating: ${_formatLargeNumber(supply)} / ${_formatLargeNumber(maxSupply)} '
                '(${supplyPct.toStringAsFixed(1)}% in circulation) | '
                '${supplyPct > 90 ? 'Near max supply - deflationary pressure' : 'Room for supply expansion'}',
            category: 'onchain',
          ));
        }
      }
    }

    final historyResponse = await _safeGet(
      'https://api.coincap.io/v2/assets/$id/history',
      queryParameters: {'interval': 'd1'},
    );

    if (historyResponse?.data is Map<String, dynamic>) {
      final historyData =
          (historyResponse!.data as Map<String, dynamic>)['data'] as List?;
      if (historyData != null && historyData.length >= 7) {
        final recent = historyData.takeLast(7).toList();
        final prices = recent
            .map((e) => double.tryParse((e as Map<String, dynamic>)['priceUsd'] as String? ?? '') ?? 0.0)
            .where((p) => p > 0)
            .toList();

        if (prices.length >= 2) {
          final weekChange =
              ((prices.last - prices.first) / prices.first) * 100;
          final volatility = _calculateVolatility(prices);

          results.add(WebResearchResult(
            source: 'CoinCap',
            title: '${symbol.toUpperCase()} 7-Day Performance',
            snippet:
                '7-day change: ${weekChange.toStringAsFixed(2)}% | '
                'Volatility: ${volatility.toStringAsFixed(2)}% | '
                'Range: \$${_formatNumber(prices.reduce((a, b) => a < b ? a : b))} - '
                '\$${_formatNumber(prices.reduce((a, b) => a > b ? a : b))}',
            category: 'sentiment',
          ));
        }
      }
    }

    return results;
  }

  Future<List<WebResearchResult>> _fetchGlobalCryptoData() async {
    final results = <WebResearchResult>[];

    final globalResponse =
        await _safeGet('https://api.coingecko.com/api/v3/global');

    if (globalResponse?.data is Map<String, dynamic>) {
      final data = globalResponse!.data as Map<String, dynamic>;
      final globalData = data['data'] as Map<String, dynamic>?;
      if (globalData != null) {
        final totalMarketCap =
            (globalData['total_market_cap'] as Map<String, dynamic>?)?['usd'];
        final totalVolume =
            (globalData['total_volume'] as Map<String, dynamic>?)?['usd'];
        final btcDominance =
            (globalData['market_cap_percentage'] as Map<String, dynamic>?)?['btc'];
        final activeCryptos = globalData['active_cryptocurrencies'] as int?;

        if (totalMarketCap != null) {
          results.add(WebResearchResult(
            source: 'CoinGecko Global',
            title: 'Crypto Market Overview',
            snippet:
                'Total MCap: \$${_formatLargeNumber(totalMarketCap)} | '
                '24h Vol: ${totalVolume != null ? '\$${_formatLargeNumber(totalVolume)}' : 'N/A'} | '
                'BTC Dom: ${btcDominance != null ? '${(btcDominance as num).toStringAsFixed(1)}%' : 'N/A'} | '
                'Active Coins: ${activeCryptos ?? 'N/A'}',
            category: 'macro',
          ));
        }
      }
    }

    return results;
  }

  String _symbolToCoinCapId(String symbol) {
    final idMap = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'USDT': 'tether',
      'BNB': 'binance-coin',
      'XRP': 'xrp',
      'USDC': 'usd-coin',
      'SOL': 'solana',
      'ADA': 'cardano',
      'DOGE': 'dogecoin',
      'TRX': 'tron',
      'DOT': 'polkadot',
      'MATIC': 'polygon',
      'SHIB': 'shiba-inu',
      'LTC': 'litecoin',
      'BCH': 'bitcoin-cash',
      'ATOM': 'cosmos',
      'LINK': 'chainlink',
      'UNI': 'uniswap',
      'XLM': 'stellar',
      'ALGO': 'algorand',
      'AVAX': 'avalanche',
      'NEAR': 'near',
      'APT': 'aptos',
      'ARB': 'arbitrum',
      'OP': 'optimism',
    };
    return idMap[symbol.toUpperCase()] ?? symbol.toLowerCase();
  }

  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0;
    final returns = <double>[];
    for (var i = 1; i < prices.length; i++) {
      if (prices[i - 1] != 0) {
        returns.add((prices[i] - prices[i - 1]) / prices[i - 1]);
      }
    }
    if (returns.isEmpty) return 0;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
            returns.length;
    return (variance > 0 ? _sqrt(variance) : 0) * 100;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  String _formatNumber(dynamic value) {
    if (value is num) {
      if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
      if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
      if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatLargeNumber(dynamic value) {
    if (value is num) {
      if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)}T';
      if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
      if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
      if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  Future<List<WebResearchResult>> searchAll(String symbol) async {
    final key = _cacheKey('searchAll', symbol);
    final cached = _getCached(key);
    if (cached != null) return cached;

    final results = <WebResearchResult>[];

    final futures = await Future.wait([
      _fetchCoinGeckoData(symbol).catchError((_) => <WebResearchResult>[]),
      _fetchCoinCapData(symbol).catchError((_) => <WebResearchResult>[]),
      _fetchGlobalCryptoData().catchError((_) => <WebResearchResult>[]),
    ]);

    for (final batch in futures) {
      results.addAll(batch);
    }

    if (results.isEmpty) {
      results.addAll(_getFallbackData(symbol));
    }

    _setCache(key, results);
    return results;
  }

  Future<double> searchSentiment(String symbol) async {
    final key = _cacheKey('sentiment', symbol);
    final cached = _getCached(key);
    if (cached != null && cached.isNotEmpty) {
      return _aggregateSentiment(cached);
    }

    final results = await searchAll(symbol);
    return _aggregateSentiment(results);
  }

  double _aggregateSentiment(List<WebResearchResult> results) {
    if (results.isEmpty) return 0.5;

    double sentimentSum = 0;
    int sentimentCount = 0;

    for (final result in results) {
      if (result.sentimentScore != null) {
        sentimentSum += result.sentimentScore!;
        sentimentCount++;
        continue;
      }

      final text =
          '${result.title} ${result.snippet}'.toLowerCase();

      double score = 0.5;

      final bullishTerms = [
        'bullish', 'surge', 'rally', 'gain', 'rise', 'up', 'high',
        'strong', 'growth', 'profit', 'recovery', 'breakout', 'momentum',
      ];
      final bearishTerms = [
        'bearish', 'crash', 'dump', 'loss', 'fall', 'down', 'low',
        'weak', 'decline', 'drop', 'correction', 'fear', 'sell',
      ];

      int bullCount = 0;
      int bearCount = 0;
      for (final term in bullishTerms) {
        if (text.contains(term)) bullCount++;
      }
      for (final term in bearishTerms) {
        if (text.contains(term)) bearCount++;
      }

      if (bullCount > bearCount) {
        score = 0.5 + (bullCount * 0.08).clamp(0, 0.5);
      } else if (bearCount > bullCount) {
        score = 0.5 - (bearCount * 0.08).clamp(0, 0.5);
      }

      sentimentSum += score;
      sentimentCount++;
    }

    if (sentimentCount == 0) return 0.5;
    return (sentimentSum / sentimentCount).clamp(0.0, 1.0);
  }

  List<WebResearchResult> _getFallbackData(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    return [
      WebResearchResult(
        source: 'Fallback',
        title: '$upperSymbol Market Data Unavailable',
        snippet:
            'APIs currently unreachable. Cached data may be stale. '
            'Check network connectivity and try again.',
        category: 'news',
      ),
      WebResearchResult(
        source: 'Fallback',
        title: '$upperSymbol Sentiment Estimate',
        snippet:
            'Unable to fetch real-time sentiment. '
            'Defaulting to neutral (0.5) pending data recovery.',
        category: 'sentiment',
      ),
    ];
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _dio.close();
    _cache.clear();
  }
}

extension _IterableLastN<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    if (length <= n) return this;
    return skip(length - n);
  }
}
