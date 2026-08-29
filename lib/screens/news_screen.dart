import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/crypto_news_service.dart';
import '../theme/noah_theme.dart';

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
  Map<String, dynamic> _sentiment = {};

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _newsService.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _loading = true);
    final articles = await _newsService.fetchNews(limit: 30);
    final sentiment = await _newsService.fetchSentiment();
    if (!mounted) return;
    setState(() {
      _articles = articles;
      _sentiment = sentiment;
      _loading = false;
    });
  }

  List<CryptoNewsArticle> get _filteredArticles {
    if (_filter == 'all') return _articles;
    return _articles.where((a) {
      final text = '${a.title} ${a.description} ${a.category}'.toLowerCase();
      return text.contains(_filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t0 = isDark ? NoahColors.dkT0 : NoahColors.t0;
    final t1 = isDark ? NoahColors.dkT1 : NoahColors.t1;
    final t2 = isDark ? NoahColors.dkT2 : NoahColors.t2;
    final accent = isDark ? NoahColors.dkAccent : NoahColors.accent;
    final bg1 = isDark ? NoahColors.dkBg1 : NoahColors.bg1;
    final border = isDark ? NoahColors.dkBorder : NoahColors.border;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadNews,
        color: accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _sentimentBar(isDark, t0, t1, t2, accent)),
            SliverToBoxAdapter(child: _buildFilters(isDark, t0, t2, accent)),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_filteredArticles.isEmpty)
              SliverFillRemaining(child: _emptyState(t2))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: _filteredArticles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _articleCard(_filteredArticles[index], isDark, t0, t1, t2, accent, bg1, border);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sentimentBar(bool isDark, Color t0, Color t1, Color t2, Color accent) {
    final sentiment = _sentiment['sentiment'] as String? ?? 'neutral';
    final bullish = _sentiment['bullish'] as int? ?? 0;
    final bearish = _sentiment['bearish'] as int? ?? 0;

    Color barColor;
    IconData icon;
    String label;
    if (sentiment == 'bullish') {
      barColor = isDark ? NoahColors.dkGreen : NoahColors.green;
      icon = Icons.trending_up_rounded;
      label = 'Bullish';
    } else if (sentiment == 'bearish') {
      barColor = isDark ? NoahColors.dkRed : NoahColors.red;
      icon = Icons.trending_down_rounded;
      label = 'Bearish';
    } else {
      barColor = isDark ? NoahColors.dkAmber : NoahColors.amber;
      icon = Icons.remove_rounded;
      label = 'Neutre';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: barColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: barColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sentiment', style: TextStyle(fontSize: 11, color: t2, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 15, color: t0, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 12, color: isDark ? NoahColors.dkGreen : NoahColors.green),
                  const SizedBox(width: 2),
                  Text('$bullish', style: TextStyle(fontSize: 12, color: isDark ? NoahColors.dkGreen : NoahColors.green, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_downward_rounded, size: 12, color: isDark ? NoahColors.dkRed : NoahColors.red),
                  const SizedBox(width: 2),
                  Text('$bearish', style: TextStyle(fontSize: 12, color: isDark ? NoahColors.dkRed : NoahColors.red, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 2),
              Text('${_articles.length} articles', style: TextStyle(fontSize: 11, color: t2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark, Color t0, Color t2, Color accent) {
    final filters = [
      ('all', 'Toutes'),
      ('bitcoin', 'BTC'),
      ('ethereum', 'ETH'),
      ('defi', 'DeFi'),
      ('regulation', 'Regulation'),
      ('market', 'Marche'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = filters[index];
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? accent.withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                  width: 0.5,
                ),
              ),
              child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? accent : t0)),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(Color t2) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper_rounded, size: 48, color: t2.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Aucune actualite', style: TextStyle(color: t2, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Tire vers le bas pour rafraichir', style: TextStyle(color: t2.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _articleCard(CryptoNewsArticle article, bool isDark, Color t0, Color t1, Color t2, Color accent, Color bg1, Color border) {
    final green = isDark ? NoahColors.dkGreen : NoahColors.green;
    final amber = isDark ? NoahColors.dkAmber : NoahColors.amber;

    Color catColor;
    final cat = article.category.toLowerCase();
    if (cat.contains('market') || cat.contains('markets')) {
      catColor = green;
    } else if (cat.contains('regulation') || cat.contains('policy')) {
      catColor = amber;
    } else {
      catColor = accent;
    }

    return GestureDetector(
      onTap: article.link.isNotEmpty ? () => launchUrl(Uri.parse(article.link), mode: LaunchMode.externalApplication) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (article.thumbnail != null && article.thumbnail!.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  article.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                    child: Center(child: Icon(Icons.image_outlined, color: t2.withValues(alpha: 0.3), size: 40)),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + category + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(article.source, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(article.category, style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      if (article.timeAgo.isNotEmpty)
                        Text(article.timeAgo, style: TextStyle(color: t2, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    article.title,
                    style: TextStyle(color: t0, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.description,
                      style: TextStyle(color: t1, fontSize: 12.5, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Read more button
                  Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14, color: accent),
                      const SizedBox(width: 4),
                      Text('Lire l\'article', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
