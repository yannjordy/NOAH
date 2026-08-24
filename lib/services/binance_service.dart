import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class BinanceBalance {
  final String asset;
  final double free;
  final double locked;

  BinanceBalance({
    required this.asset,
    required this.free,
    required this.locked,
  });

  double get total => free + locked;
}

class BinanceOrderResult {
  final String symbol;
  final String side;
  final double executedQty;
  final double cummulativeQuoteQty;
  final String status;
  final int orderId;

  BinanceOrderResult({
    required this.symbol,
    required this.side,
    required this.executedQty,
    required this.cummulativeQuoteQty,
    required this.status,
    required this.orderId,
  });

  double get avgPrice =>
      executedQty > 0 ? cummulativeQuoteQty / executedQty : 0;
}

class BinanceOpenOrder {
  final String symbol;
  final int orderId;
  final String side;
  final String type;
  final double price;
  final double origQty;
  final double executedQty;
  final String status;

  BinanceOpenOrder({
    required this.symbol,
    required this.orderId,
    required this.side,
    required this.type,
    required this.price,
    required this.origQty,
    required this.executedQty,
    required this.status,
  });
}

class BinanceService {
  final Dio _dio;
  String? _apiKey;
  String? _secretKey;
  bool _testnet = false;

  static const String _baseMain = 'https://api.binance.com';
  static const String _baseTestnet = 'https://testnet.binance.vision';

  BinanceService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (_) => true,
        ),
      );

  bool get isConnected => _apiKey != null && _secretKey != null;
  bool get useTestnet => _testnet;

  String get _baseUrl => _testnet ? _baseTestnet : _baseMain;

  void configure(String apiKey, String secretKey, {bool testnet = false}) {
    _apiKey = apiKey;
    _secretKey = secretKey;
    _testnet = testnet;
  }

  void disconnect() {
    _apiKey = null;
    _secretKey = null;
  }

  String _sign(String queryString) {
    final key = utf8.encode(_secretKey!);
    final bytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  Map<String, String> _headers() => {
    'X-MBX-APIKEY': _apiKey!,
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  Future<Map<String, dynamic>> _signedGet(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final queryParams = <String, dynamic>{'timestamp': ts, 'recvWindow': 10000};
    if (params != null) queryParams.addAll(params);

    final queryString = Uri(queryParameters: queryParams).query;
    final signature = _sign(queryString);
    queryParams['signature'] = signature;

    final resp = await _dio.get(
      '$_baseUrl$path',
      queryParameters: queryParams,
      options: Options(headers: _headers()),
    );
    if (resp.statusCode != 200) {
      final msg = (resp.data is Map)
          ? resp.data['msg'] ?? resp.statusMessage
          : resp.statusMessage;
      throw Exception('Erreur Binance ${resp.statusCode}: $msg');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _signedPost(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final queryParams = <String, dynamic>{'timestamp': ts, 'recvWindow': 10000};
    if (params != null) queryParams.addAll(params);

    final queryString = Uri(queryParameters: queryParams).query;
    final signature = _sign(queryString);
    queryParams['signature'] = signature;

    final resp = await _dio.post(
      '$_baseUrl$path',
      queryParameters: queryParams,
      options: Options(headers: _headers()),
    );
    if (resp.statusCode != 200) {
      final msg = (resp.data is Map)
          ? resp.data['msg'] ?? resp.statusMessage
          : resp.statusMessage;
      throw Exception('Erreur Binance ${resp.statusCode}: $msg');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _signedDelete(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final queryParams = <String, dynamic>{'timestamp': ts, 'recvWindow': 10000};
    if (params != null) queryParams.addAll(params);

    final queryString = Uri(queryParameters: queryParams).query;
    final signature = _sign(queryString);
    queryParams['signature'] = signature;

    final resp = await _dio.delete(
      '$_baseUrl$path',
      queryParameters: queryParams,
      options: Options(headers: _headers()),
    );
    if (resp.statusCode != 200) {
      final msg = (resp.data is Map)
          ? resp.data['msg'] ?? resp.statusMessage
          : resp.statusMessage;
      throw Exception('Erreur Binance ${resp.statusCode}: $msg');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<bool> testConnection() async {
    try {
      if (!isConnected) return false;
      await _signedGet('/api/v3/account');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<BinanceBalance>> getBalances() async {
    final data = await _signedGet('/api/v3/account');
    final balances = <BinanceBalance>[];
    final rawList = data['balances'] as List<dynamic>? ?? [];
    for (final b in rawList) {
      final free = double.tryParse(b['free'] ?? '0') ?? 0;
      final locked = double.tryParse(b['locked'] ?? '0') ?? 0;
      if (free > 0 || locked > 0) {
        balances.add(
          BinanceBalance(asset: b['asset'] ?? '', free: free, locked: locked),
        );
      }
    }
    return balances;
  }

  Future<BinanceOrderResult> placeMarketOrder(
    String symbol,
    String side,
    double qty,
  ) async {
    final params = <String, dynamic>{
      'symbol': symbol.toUpperCase(),
      'side': side.toUpperCase(),
      'type': 'MARKET',
      'quantity': qty.toStringAsFixed(6),
    };
    final data = await _signedPost('/api/v3/order', params: params);
    return BinanceOrderResult(
      symbol: data['symbol'] ?? symbol,
      side: data['side'] ?? side,
      executedQty: double.tryParse(data['executedQty'] ?? '0') ?? 0,
      cummulativeQuoteQty:
          double.tryParse(data['cummulativeQuoteQty'] ?? '0') ?? 0,
      status: data['status'] ?? 'UNKNOWN',
      orderId: data['orderId'] ?? 0,
    );
  }

  Future<BinanceOrderResult> placeLimitOrder(
    String symbol,
    String side,
    double qty,
    double price,
  ) async {
    final params = <String, dynamic>{
      'symbol': symbol.toUpperCase(),
      'side': side.toUpperCase(),
      'type': 'LIMIT',
      'timeInForce': 'GTC',
      'quantity': qty.toStringAsFixed(6),
      'price': price.toStringAsFixed(2),
    };
    final data = await _signedPost('/api/v3/order', params: params);
    return BinanceOrderResult(
      symbol: data['symbol'] ?? symbol,
      side: data['side'] ?? side,
      executedQty: double.tryParse(data['executedQty'] ?? '0') ?? 0,
      cummulativeQuoteQty:
          double.tryParse(data['cummulativeQuoteQty'] ?? '0') ?? 0,
      status: data['status'] ?? 'NEW',
      orderId: data['orderId'] ?? 0,
    );
  }

  Future<BinanceOrderResult> placeStopLossOrder(
    String symbol,
    String side,
    double qty,
    double stopPrice,
  ) async {
    final params = <String, dynamic>{
      'symbol': symbol.toUpperCase(),
      'side': side.toUpperCase(),
      'type': 'STOP_LOSS',
      'quantity': qty.toStringAsFixed(6),
      'stopPrice': stopPrice.toStringAsFixed(2),
    };
    final data = await _signedPost('/api/v3/order', params: params);
    return BinanceOrderResult(
      symbol: data['symbol'] ?? symbol,
      side: data['side'] ?? side,
      executedQty: double.tryParse(data['executedQty'] ?? '0') ?? 0,
      cummulativeQuoteQty:
          double.tryParse(data['cummulativeQuoteQty'] ?? '0') ?? 0,
      status: data['status'] ?? 'NEW',
      orderId: data['orderId'] ?? 0,
    );
  }

  Future<List<BinanceOpenOrder>> getOpenOrders({String? symbol}) async {
    final params = <String, dynamic>{};
    if (symbol != null) params['symbol'] = symbol.toUpperCase();
    final data = await _signedGet('/api/v3/openOrders', params: params);
    final orders = <BinanceOpenOrder>[];
    for (final o in (data as List<dynamic>? ?? [])) {
      orders.add(
        BinanceOpenOrder(
          symbol: o['symbol'] ?? '',
          orderId: o['orderId'] ?? 0,
          side: o['side'] ?? '',
          type: o['type'] ?? '',
          price: double.tryParse(o['price'] ?? '0') ?? 0,
          origQty: double.tryParse(o['origQty'] ?? '0') ?? 0,
          executedQty: double.tryParse(o['executedQty'] ?? '0') ?? 0,
          status: o['status'] ?? '',
        ),
      );
    }
    return orders;
  }

  Future<void> cancelOrder(String symbol, int orderId) async {
    await _signedDelete(
      '/api/v3/order',
      params: {'symbol': symbol.toUpperCase(), 'orderId': orderId},
    );
  }

  Stream<Map<String, dynamic>> klineStream(
    String symbol,
    String interval,
  ) async* {
    final wsUrl =
        '${_testnet ? "wss://testnet.binance.vision" : "wss://stream.binance.com:9443"}/ws/${symbol.toLowerCase()}${interval.toLowerCase()}@kline';
    try {
      final wsDio = Dio();
      final resp = await wsDio.get(wsUrl.replaceFirst('wss://', 'https://'));
      if (resp.statusCode == 200 && resp.data is Map) {
        yield Map<String, dynamic>.from(resp.data);
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getKlines(
    String symbol,
    String interval, {
    int limit = 100,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/api/v3/klines',
      queryParameters: {
        'symbol': symbol.toUpperCase(),
        'interval': interval,
        'limit': limit,
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur klines: ${resp.statusMessage}');
    }
    return {'klines': resp.data};
  }

  Future<double> getPrice(String symbol) async {
    final resp = await _dio.get(
      '$_baseUrl/api/v3/ticker/price',
      queryParameters: {'symbol': symbol.toUpperCase()},
    );
    if (resp.statusCode != 200)
      throw Exception('Erreur prix: ${resp.statusMessage}');
    return double.tryParse(resp.data['price'] ?? '0') ?? 0;
  }

  Future<Map<String, double>> getAllPrices() async {
    final resp = await _dio.get('$_baseUrl/api/v3/ticker/price');
    if (resp.statusCode != 200)
      throw Exception('Erreur prix: ${resp.statusMessage}');
    final prices = <String, double>{};
    for (final item in (resp.data as List<dynamic>? ?? [])) {
      final sym = item['symbol'] ?? '';
      final price = double.tryParse(item['price'] ?? '0') ?? 0;
      if (price > 0) prices[sym] = price;
    }
    return prices;
  }

  Future<List<BinanceBalance>> getAccountBalances() async {
    return getBalances();
  }

  Future<Map<String, List<List<double>>>> getOrderBook(
    String symbol, {
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/api/v3/depth',
      queryParameters: {'symbol': symbol.toUpperCase(), 'limit': limit},
    );
    if (resp.statusCode != 200)
      throw Exception('Erreur orderbook: ${resp.statusMessage}');
    final data = resp.data;
    final bids = <List<double>>[];
    final asks = <List<double>>[];
    for (final b in (data['bids'] ?? []) as List) {
      bids.add([double.tryParse(b[0]) ?? 0, double.tryParse(b[1]) ?? 0]);
    }
    for (final a in (data['asks'] ?? []) as List) {
      asks.add([double.tryParse(a[0]) ?? 0, double.tryParse(a[1]) ?? 0]);
    }
    return {'bids': bids, 'asks': asks};
  }
}
