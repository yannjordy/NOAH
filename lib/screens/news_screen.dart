import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/crypto_news_service.dart';
import '../theme/glass_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final CryptoNewsService _newsService = CryptoNewsService();
  List<CryptoNewsArticle> _articles = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNews();
    _newsService.startAutoRefresh();
  }

  @override
  void dispose() {
    _newsService.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _loading = true);
    final articles = await _newsService.fetchNews(limit: 30);
    setState(() {
      _articles = articles;
      _loading = false;
    });
  }

  List<CryptoNewsArticle> get _filteredArticles {
    if (_filter == 'all') return _articles;
    return _articles.where((a) =>
      a.title.toLowerCase().contains(_filter) ||
      a.description.toLowerCase().contains(_filter)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('News Crypto', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildChip('all', 'Toutes', isDark),
                _buildChip('bitcoin', 'Bitcoin', isDark),
                _buildChip('ethereum', 'Ethereum', isDark),
                _buildChip('defi', 'DeFi', isDark),
                _buildChip('altcoin', 'Altcoins', isDark),
              ],
            ),
          ),
          // News list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadNews,
                    child: _filteredArticles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('Aucune news trouvée', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredArticles.length,
                            itemBuilder: (context, index) {
                              final article = _filteredArticles[index];
                              return _buildArticleCard(article, isDark);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String value, String label, bool isDark) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 13,
        )),
        selected: selected,
        onSelected: (v) => setState(() => _filter = value),
        selectedColor: const Color(0xFF00D4AA),
        backgroundColor: isDark ? Colors.white10 : Colors.black12,
        checkmarkColor: Colors.white,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }

  Widget _buildArticleCard(CryptoNewsArticle article, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Color.fromRGBO(255, 255, 255, 0.06)
                : Color.fromRGBO(0, 0, 0, 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source + time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.source,
                      style: const TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.timeAgo,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                article.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (article.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  article.description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
