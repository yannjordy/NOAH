class WebResearchResult {
  final String source;
  final String title;
  final String snippet;
  final String category;

  WebResearchResult({
    required this.source,
    required this.title,
    this.snippet = '',
    this.category = 'general',
  });
}

class WebResearchService {
  int _topicIndex = 0;
  static const _topics = [
    'crypto market',
    'DeFi trends',
    'institutional adoption',
    'regulation news',
    'on-chain analytics',
  ];

  String get nextTopic => _topics[_topicIndex++ % _topics.length];

  Future<List<WebResearchResult>> searchAll(String symbol) async {
    return [];
  }
}
