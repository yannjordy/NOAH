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
    r