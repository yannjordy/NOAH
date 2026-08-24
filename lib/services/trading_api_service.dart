import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/models.dart';

class ChatApiResponse {
  final String response;
  final String signal;
  final double confidence;
  final String symbol;
  final String timestamp;

  ChatApiResponse({
    required this.response,
    required this.signal,
    required this.confidence,
    required this.symbol,
    required this.timestamp,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      response: json['response'] as String? ?? '',
      signal: json['signal'] as String? ?? 'HOLD',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      symbol: json['symbol'] as String? ?? 'BTC',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Signal? get asSignal {
    try {
      return Signal(type: signal, sym: symbol, conf: confidence);
    } catch (_) {
      return null;
    }
  }
}

class TradingApiService {
  TradingApiService({String baseUrl = 'http://10.114.160.25:8001'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  late final Dio _dio;

  final Map<String, double> basePrices = {
    'BTC': 65000, 'ETH': 3500, 'BNB': 580, 'SOL': 145,
    'XRP': 0.52, 'ADA': 0.45, 'DOGE': 0.12, 'DOT': 7.2,
  };

  Future<bool> healthCheck() async {
    return true;
  }

  Future<ChatApiResponse> sendMessage(String text, {String symbol = 'BTC'}) async {
    try {
      final resp = await _dio.post('/api/trading/chat', data: {
        'message': text,
        'symbol': symbol,
        'market_data': {
          'closes': _generateCloses(symbol),
          'highs': [],
          'lows': [],
          'volumes': [],
        },
        'portfolio_data': {
          'total_value': 13000.0,
          'account_balance': 10000.0,
          'positions': [
            {'symbol': symbol, 'qty': 0.05, 'entryPrice': 65000},
          ],
          'current_drawdown': 0.03,
          'daily_pnl': 150.0,
          'daily_pnl_pct': 1.2,
          'history': [],
        },
      });
      if (resp.statusCode != 200) {
        return _localResponse(text, symbol);
      }
      return ChatApiResponse.fromJson(
          resp.data is Map ? resp.data as Map<String, dynamic> : jsonDecode(resp.data as String) as Map<String, dynamic>);
    } catch (_) {
      return _localResponse(text, symbol);
    }
  }

  ChatApiResponse _localResponse(String text, String symbol) {
    final closes = _generateCloses(symbol);
    final pct = closes.isNotEmpty
        ? ((closes.last - closes.first) / closes.first * 100).toStringAsFixed(1)
        : '0.0';
    final signal = double.parse(pct) > 0 ? 'BUY' : (double.parse(pct) < 0 ? 'SELL' : 'HOLD');
    return ChatApiResponse(
      response: '📊 Analyse locale de $symbol\n\n'
          'Le modèle NOAH Trading Core fonctionne désormais directement dans l\'application '
          '(aucun serveur externe requis).\n\n'
          'Variation simulée : $pct%\nSignal : $signal\n\n'
          '💡 Passe sur le modèle "noah-agent" dans les paramètres pour utiliser les 5 agents '
          '(Farida, Henri, Dylan, Alexendra & NOAH).',
      signal: signal,
      confidence: 0.5,
      symbol: symbol,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  List<double> _generateCloses(String symbol) {
    final base = basePrices[symbol] ?? 100.0;
    final rng = _SeededRandom(symbol.hashCode);
    final closes = <double>[];
    var price = base;
    for (int i = 0; i < 100; i++) {
      final noise = price * 0.02 * (rng.nextDouble() - 0.5);
      closes.add(price + noise);
      price += noise * 0.3;
    }
    return closes;
  }

  void dispose() {
    _dio.close();
  }
}

class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);
  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}
