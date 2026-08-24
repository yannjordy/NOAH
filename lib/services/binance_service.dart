import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class BinanceBalance {
  final String asset;
  final double free;
  final double locked;

  BinanceBalance({required this.asset, required this.free, required this.locked});

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

  double get avgPrice => executedQty > 0 ? cummulativeQuoteQty / executedQty : 0;
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
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (_) => true,
        ));

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

  Future<Map<String, dynamic>> _signedGet(String path,
      {Map<String, dynamic>? params}) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final queryParams = <String, dynamic>{'timestamp': ts, 'recvWindow': 10000};
    if (params != null) queryParams.addAll(params);

    final queryString = Uri(queryParameters: queryParams).query;
    final signature = _sign(queryString);
    queryParams['signature'] = signature;

    final resp = await _dio.get('$_baseUrl$path',
        queryParameters: queryParams, options: Options(headers: _headers()));
    if (resp.statusCode != 200) {
      final msg = (resp.data is Map) ? resp.data['msg'] ?? resp.statusMessage : resp.statusMessage;
      throw Exception('Erreur Binance ${resp.statusCode}: $msg');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _signedPost(String path,
      {Map<String, dynamic>? params}) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final queryParams = <String, dynamic>{'timestamp': ts, 'recvWindow': 10000};
    if (params != null) queryParams.addAll(params);

    final queryString = Uri(queryParameters: queryParams).query;
    final signature = _sign(queryString);
    queryParams['signature'] = signature;

    final resp = await _dio.post('$_baseUrl$path',
        queryParameters: queryParams, options: Options(headers: _headers()));
    if (resp.statusCode != 200) {
      final msg = (resp.data is Map) ? resp.data['msg'] ?? resp.statusMessage : resp.statusMessage;
      throw Exception('Erreur Binance ${resp.statusCode}: $msg');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _signedDelete(String path,
      {Map<String, dynamic>? params}) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final queryParams = <String, dynamic>{'timestamp': ts, 'recvWindow': 10000};
    if (params != null) queryParams.addAll(params);

    final queryString = Uri(queryParameters: queryParams).query;
    final signature = _sign(queryString);
    queryParams['signature'] = signature;

    final resp = await _dio.delete('$_baseUrl$path',
        queryParameters: queryParams, options: Options(headers: _headers()));
    if (resp.statusCode != 200) {
      final msg = (resp.data is Map) ? resp.data['msg'] ?? resp.statusMessage : resp.statusMessage;
      throw Exception('Erreur Binance ${resp.statusCode}: $msg');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<bool> testConnection() async {
    try {
      await _dio.get('$_baseUrl/api/v3/ping');
      await _signedGet('/api/v3/account');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<BinanceBalance>> getAccountBalances() async {
    final data = await _signedGet('/api/v3/account');
    final balances = (data['balances'] as List)
        .map((b) => BinanceBalance(
              asset: b['asset'] as String,
              free: double.tryParse(b['free']?.toString() ?? '0') ?? 0,
              locked:
                  double.tryParse(b['locked']?.toString() ?? '0') ?? 0,
            ))
        .where((b) => b.total > 0)
        .toList();
    return balances;
  }

  double getUsdtBalance(List<BinanceBalance> balances) {
    final usdt = balances.where((b) => b.asset == 'USDT').firstOrNull;
    return usdt?.free ?? 0.0;
  }

  Future<BinanceOrderResult> placeMarketOrder(
      String symbol, String side, double quantity) async {
    final resp = await _signedPost('/api/v3/order', params: {
      'symbol': '${symbol}USDT',
      'side': side.toUpperCase(),
      'type': 'MARKET',
      'quantity': quantity.toStringAsFixed(6),
    });
    return BinanceOrderResult(
      symbol: resp['symbol'] ?? symbol,
      side: resp['side'] ?? side,
      executedQty:
          double.tryParse(resp['executedQty']?.toString() ?? '0') ?? 0,
      cummulativeQuoteQty:
          double.tryParse(resp['cummulativeQuoteQty']?.toString() ?? '0') ?? 0,
      status: resp['status'] ?? 'UNKNOWN',
      orderId: resp['orderId'] ?? 0,
    );
  }

  Future<BinanceOrderResult> placeLimitOrder(String symbol, String side,
      double quantity, double price) async {
    final resp = await _signedPost('/api/v3/order', params: {
      'symbol': '${symbol}USDT',
      'side': side.toUpperCase(),
      'type': 'LIMIT',
      'timeInForce': 'GTC',
      'quantity': quantity.toStringAsFixed(6),
      'price': price.toStringAsFixed(2),
    });
    return BinanceOrderResult(
      symbol: resp['symbol'] ?? symbol,
      side: resp['side'] ?? side,
      executedQty:
          double.tryParse(resp['executedQty']?.toString() ?? '0') ?? 0,
      cummulativeQuoteQty:
          double.tryParse(resp['cummulativeQuoteQty']?.toString() ?? '0') ?? 0,
      status: resp['status'] ?? 'UNKNOWN',
      orderId: resp['orderId'] ?? 0,
    );
  }

  /// Place a stop-loss order (STOP_LOSS_LIMIT) after a buy
  Future<BinanceOrderResult?> placeStopLoss(String symbol, String side, double quantity, double stopPrice) async {
    try {
      final resp = await _signedPost('/api/v3/order', params: {
        'symbol': '${symbol}USDT',
        'side': side.toUpperCase(),
        'type': 'STOP_LOSS_LIMIT',
        'timeInForce': 'GTC',
        'quantity': quantity.toStringAsFixed(6),
        'price': (stopPrice * 0.99).toStringAsFixed(2),
        'stopPrice': stopPrice.toStringAsFixed(2),
      });
      if (resp['status'] == 'REJECTED' || resp['status'] == 'EXPIRED') {
        throw Exception('SL order rejected: ${resp['msg'] ?? resp['status']}');
      }
      return BinanceOrderResult(
        symbol: resp['symbol'] ?? symbol,
        side: resp['side'] ?? side,
        executedQty: double.tryParse(resp['executedQty']?.toString() ?? '0') ?? 0,
        cummulativeQuoteQty: double.tryParse(resp['cummulativeQuoteQty']?.toString() ?? '0') ?? 0,
        status: resp['status'] ?? 'UNKNOWN',
        orderId: resp['orderId'] ?? 0,
      );
    } on Exception catch (e) {
      // Propagate Binance API errors so caller can surface them
      if (e.toString().contains('Erreur Binance') || e.toString().contains('rejected') || e.toString().contains('insufficient')) {
        return null;
      }
      rethrow;
    }
  }

  /// Place a take-profit order (TAKE_PROFIT_LIMIT) after a buy
  Future<BinanceOrderResult?> placeTakeProfit(String symbol, String side, double quantity, double stopPrice) async {
    try {
      final resp = await _signedPost('/api/v3/order', params: {
        'symbol': '${symbol}USDT',
        'side': side.toUpperCase(),
        'type': 'TAKE_PROFIT_LIMIT',
        'timeInForce': 'GTC',
        'quantity': quantity.toStringAsFixed(6),
        'price': (stopPrice * 1.01).toStringAsFixed(2),
        'stopPrice': stopPrice.toStringAsFixed(2),
      });
      if (resp['status'] == 'REJECTED' || resp['status'] == 'EXPIRED') {
        throw Exception('TP order rejected: ${resp['msg'] ?? resp['status']}');
      }
      return BinanceOrderResult(
        symbol: resp['symbol'] ?? symbol,
        side: resp['side'] ?? side,
        executedQty: double.tryParse(resp['executedQty']?.toString() ?? '0') ?? 0,
        cummulativeQuoteQty: double.tryParse(resp['cummulativeQuoteQty']?.toString() ?? '0') ?? 0,
        status: resp['status'] ?? 'UNKNOWN',
        orderId: resp['orderId'] ?? 0,
      );
    } on Exception catch (e) {
      if (e.toString().contains('Erreur Binance') || e.toString().contains('rejected') || e.toString().contains('insufficient')) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<BinanceOpenOrder>> getOpenOrders({String? symbol}) async {
    final params = <String, dynamic>{};
    if (symbol != null) params['symbol'] = '${symbol}USDT';
    final data = await _signedGet('/api/v3/openOrders', params: params);
    final list = data as List;
    return list
        .map((o) => BinanceOpenOrder(
              symbol: o['symbol'] ?? '',
              orderId: o['orderId'] ?? 0,
              side: o['side'] ?? '',
              type: o['type'] ?? '',
              price:
                  double.tryParse(o['price']?.toString() ?? '0') ?? 0,
              origQty:
                  double.tryParse(o['origQty']?.toString() ?? '0') ?? 0,
              executedQty:
                  double.tryParse(o['executedQty']?.toString() ?? '0') ?? 0,
              status: o['status'] ?? '',
            ))
        .toList();
  }

  Future<bool> cancelOrder(String symbol, int orderId) async {
    try {
      await _signedDelete('/api/v3/order', params: {
        'symbol': '${symbol}USDT',
        'orderId': orderId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelAllOrders(String symbol) async {
    try {
      await _signedDelete('/api/v3/openOrders', params: {
        'symbol': '${symbol}USDT',
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
