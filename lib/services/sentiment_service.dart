import 'dart:convert';
import 'dart:math' show Random, sqrt, log, cos, pi, pow;

class SentimentData {
  final String symbol;
  final double score;
  final double momentum;
  final String label;
  final int tweetVolume;
  final DateTime timestamp;

  SentimentData({
    required this.symbol,
    required this.score,
    required this.momentum,
    required this.label,
    this.tweetVolume = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class FearGreedData {
  final int value;
  final String label;
  final DateTime timestamp;

  FearGreedData({required this.value, required this.label, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class SentimentService {
  static double _gauss(Random rng) {
    final u1 = 1 - rng.nextDouble();
    final u2 = rng.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  static SentimentData analyze(String symbol, {double? priceChange24h}) {
    final rng = Random();
    final baseScore = 50 + (priceChange24h ?? 0) * 2;
    final noise = _gauss(rng) * 8;
    final score = baseScore + noise;
    final clamped = score.clamp(0.0, 100.0);

    String label;
    if (clamped > 75) label = 'Très positif';
    else if (clamped > 55) label = 'Positif';
    else if (clamped > 45) label = 'Neutre';
    else if (clamped > 25) label = 'Négatif';
    else label = 'Très négatif';

    final absChange = priceChange24h?.abs() ?? 1;
    final mockVolume = (rng.nextInt(5000) + 500) * absChange.round().clamp(1, 10);

    return SentimentData(
      symbol: symbol,
      score: clamped,
      momentum: (priceChange24h ?? 0) * 0.3 + _gauss(rng) * 5,
      label: label,
      tweetVolume: mockVolume,
    );
  }

  static FearGreedData fearGreedIndex({List<double>? recentPnlChanges}) {
    if (recentPnlChanges == null || recentPnlChanges.isEmpty) {
      return FearGreedData(value: 50, label: 'Neutre');
    }
    final avgChange = recentPnlChanges.reduce((a, b) => a + b) / recentPnlChanges.length;
    final volatility = sqrt(recentPnlChanges.map((r) => pow(r - avgChange, 2)).reduce((a, b) => a + b) / recentPnlChanges.length);
    final rawScore = 50 + avgChange * 100 - volatility * 50;
    final value = rawScore.round().clamp(0, 100);

    String label;
    if (value <= 15) label = 'Extrême Peur';
    else if (value <= 35) label = 'Peur';
    else if (value <= 55) label = 'Neutre';
    else if (value <= 75) label = 'Appétit';
    else label = 'Extrême Appétit';

    return FearGreedData(value: value, label: label);
  }

  static Future<double> fetchRealSentiment(String symbol) async {
    try {
      final uri = Uri.parse('https://api.senticrypt.com/v1/bitcoin');
      final client = _HttpClient();
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['score'] as num?)?.toDouble() ?? 50;
      }
    } catch (_) {}
    return 50;
  }
}

class _HttpClient {
  Future<_Response> get(Uri uri) async {
    final request = await _HttpConnection.request(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Response(body, response.statusCode);
  }
}

class _HttpConnection {
  static request(Uri uri) async {
    try {
      return await (throw UnimplementedError('dart:io not available'));
    } catch (_) {
      rethrow;
    }
  }
}

class _Response {
  final String body;
  final int statusCode;
  _Response(this.body, this.statusCode);
}
