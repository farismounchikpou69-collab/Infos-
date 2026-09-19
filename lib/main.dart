import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/news_article.dart';
import 'services/news_api_service.dart';

void main() {
  runApp(const WorldAIApp());
}

class WorldAIApp extends StatelessWidget {
  const WorldAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'World AI News',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NewsHome(),
    );
  }
}

class NewsHome extends StatefulWidget {
  const NewsHome({super.key});

  @override
  State<NewsHome> createState() => _NewsHomeState();
}

class _NewsHomeState extends State<NewsHome> {
  // Remplace cette valeur par ta clé NewsAPI.
  
  );final NewsApiService api = NewsApiService(
  const String.fromEnvironment('NEWS_API_KEY'),
);

  List<NewsArticle> articles = [];
  bool loading = false;
  String error = '';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadNews();

    timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => loadNews(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadNews() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result = await api.getWorldNews();

      if (!mounted) return;

      setState(() {
        articles = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Impossible de charger les actualités.';
      });
    }
  }

  Future<void> searchNews(String query) async {
    if (query.trim().isEmpty) {
      await loadNews();
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result = await api.search(query);

      if (!mounted) return;

      setState(() {
        articles = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Recherche impossible.';
      });
    }
  }

  String formatDate(DateTime date) {
    final local = date.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> openArticle(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 World AI News'),
        actions: [
          IconButton(
            onPressed: loadNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: 'Rechercher une actualité...',
              leading: const Icon(Icons.search),
              onSubmitted: searchNews,
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadNews,
              child: articles.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Aucune actualité disponible.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => openArticle(article.url),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (article.imageUrl != null &&
                                      article.imageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Image.network(
                                        article.imageUrl!,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                const SizedBox(),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    article.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (article.description != null)
                                    Text(
                                      article.description!,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${article.source} • '
                                    '${formatDate(article.publishedAt)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
