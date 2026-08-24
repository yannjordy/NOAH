import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

enum MarketStatus { live, simulated, loading, connecting }

class MarketService extends ChangeNotifier {
  final Dio _dio;
  MarketStatus _status = MarketStatus.loading;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  WebSocketChannel? _klineChannel;
  StreamSubscription? _klineSub;
  Timer? _reconnectTimer;
  Timer? _fallbackTimer;

  MarketStatus get status => _status;

  MarketService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.binance.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Map<String, List<Kline>> klines = {};
  String _currentInterval = '1h';
  String _currentSymbol = 'BTC';

  String get currentInterval => _currentInterval;
  Map<String, List<Kline>> get klinesMap => klines;

  // Order book
  final Map<String, List<List<double>>> bids = {};
  final Map<String, List<List<double>>> asks = {};

  void setInterval(String interval) {
    _currentInterval = interval;
    _subscribeKlineStream(_currentSymbol, interval);
    notifyListeners();
  }

  void setSymbol(String symbol) {
    _currentSymbol = symbol;
    _subscribeKlineStream(symbol, _currentInterval);
  }

  Future<void> fetchKlines(String symbol, {String interval = '1h', int limit = 100}) async {
    try {
      final response = await _dio.get('/api/v3/klines', queryParameters: {
        'symbol': '${symbol}USDT',
        'interval': interval,
        'limit': limit,
      });
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        klines[symbol] = list.map((e) => Kline.fromBinance(e as List)).toList();
        _currentSymbol = symbol;
        _currentInterval = interval;
        _subscribeKlineStream(symbol, interval);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchDepth(String symbol) async {
    try {
      final response = await _dio.get('/api/v3/depth', queryParameters: {
        'symbol': '${symbol}USDT',
        'limit': 15,
      });
      if (response.statusCode == 200 && response.data is Map) {
        final d = response.data as Map;
        bids[symbol] = (d['bids'] as List).map((e) => (e as List).map((v) => double.parse(v.toString())).toList()).toList();
        asks[symbol] = (d['asks'] as List).map((e) => (e as List).map((v) => double.parse(v.toString())).toList()).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void connect() {
    _status = MarketStatus.connecting;
    notifyListeners();
    _initWs();
    _initialFetch();
    for (final s in symbols) {
      fetchKlines(s);
    }
  }

  void _initialFetch() async {
    try {
      final response = await _dio.get('/api/v3/ticker/24hr');
      if (response.statusCode == 200 && response.data is List) {
        _applyPrices(response.data as List);
      }
    } catch (_) {}
  }

  void _initWs() {
    _closeWs();
    const url = 'wss://stream.binance.com:9443/ws/!miniTicker@arr';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sub = _channel!.stream.listen(
        (data) {
          _status = MarketStatus.live;
          isMarketConnected = true;
          lastPriceUpdate = DateTime.now();
          _fallbackTimer?.cancel();
          try {
            final items = jsonDecode(data as String);
            if (items is List) {
              for (final item in items) {
                final sym = (item['s'] as String).replaceAll('USDT', '');
                if (symbols.contains(sym)) {
                  prices[sym] = double.tryParse(item['c']?.toString() ?? '') ?? (prices[sym] ?? 0.0);
                  pcts[sym] = double.tryParse(item['p']?.toString() ?? '') ?? 0.0;
                }
              }
            }
          } catch (_) {}
          notifyListeners();
        },
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );
      _startFallbackTimer();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (_status == MarketStatus.connecting) {
        _status = MarketStatus.simulated;
        notifyListeners();
        _fallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          simulatePrices();
          notifyListeners();
        });
      }
    });
  }

  void _subscribeKlineStream(String symbol, String interval) {
    _closeKlineWs();
    try {
      final stream = '${symbol.toLowerCase()}usdt@kline_$interval';
      final url = 'wss://stream.binance.com:9443/stream?streams=$stream';
      _klineChannel = WebSocketChannel.connect(Uri.parse(url));
      _klineSub = _klineChannel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            if (msg is Map && msg['data'] is Map) {
              final k = msg['data']['k'] as Map;
              final sym = (k['s'] as String).replaceAll('USDT', '');
              if (!symbols.contains(sym)) return;
              final existing = klines[sym];
              if (existing == null || existing.isEmpty) return;
              final ot = k['t'] as int;
              final close = double.tryParse(k['c']?.toString() ?? '') ?? 0.0;
              final high = double.tryParse(k['h']?.toString() ?? '') ?? 0.0;
              final low = double.tryParse(k['l']?.toString() ?? '') ?? 0.0;
              final volume = double.tryParse(k['v']?.toString() ?? '') ?? 0.0;
              final isClosed = k['x'] as bool;

              final idx = existing.indexWhere((k) => k.openTime == ot);
              if (idx >= 0) {
                existing[idx] = Kline(
                  openTime: ot,
                  open: existing[idx].open,
                  high: high,
                  low: low,
                  close: close,
                  volume: volume,
                  closeTime: k['T'] as int,
                );
              } else {
                existing.add(Kline(
                  openTime: ot,
                  open: double.tryParse(k['o']?.toString() ?? '') ?? 0.0,
                  high: high,
                  low: low,
                  close: close,
                  volume: volume,
                  closeTime: k['T'] as int,
                ));
              }
              if (isClosed) {
                fetchKlines(sym, interval: interval);
              }
              notifyListeners();
            }
          } catch (_) {}
        },
        onError: (_) => _closeKlineWs(),
        onDone: () => _closeKlineWs(),
      );
    } catch (_) {
      _closeKlineWs();
    }
  }

  void _closeKlineWs() {
    _klineSub?.cancel();
    _klineSub = null;
    _klineChannel?.sink.close();
    _klineChannel = null;
  }

  void _handleDisconnect() {
    _status = MarketStatus.simulated;
    isMarketConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _initWs);
    _fallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      simulatePrices();
      notifyListeners();
    });
    notifyListeners();
  }

  void _applyPrices(List items) {
    for (final item in items) {
      final symbol = item['symbol'] as String? ?? '';
      if (!symbol.endsWith('USDT')) continue;
      final sym = symbol.replaceAll('USDT', '');
      if (!symbols.contains(sym)) continue;
      prices[sym] = double.tryParse(item['lastPrice']?.toString() ?? '') ?? (prices[sym] ?? 0.0);
      pcts[sym] = double.tryParse(item['priceChangePercent']?.toString() ?? '') ?? 0.0;
    }
    _status = MarketStatus.live;
    notifyListeners();
  }

  void _closeWs() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _closeKlineWs();
  }

  void simulatePrices() {
    for (final sym in symbols) {
      final current = prices[sym] ?? 100.0;
      final change = current * (DateTime.now().millisecond % 100 - 50) / 100000;
      prices[sym] = current + change;
      pcts[sym] = (pcts[sym] ?? 0) + change / current * 100;
    }
  }

  @override
  void dispose() {
    _closeWs();
    _reconnectTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }
}
