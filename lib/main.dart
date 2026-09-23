import 'package:flutter/material.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
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
  final NewsApiService api = NewsApiService(
    const String.fromEnvironment('NEWS_API_KEY'),
  );

  List<NewsArticle> articles = [];
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadNews();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World AI News'),
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
            child: TextField(
              onSubmitted: searchNews,
              decoration: InputDecoration(
                hintText: 'Rechercher une actualité...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          Expanded(
            child: articles.isEmpty && !loading
                ? const Center(
                    child: Text(
                      'Aucune actualité disponible.',
                    ),
                  )
                : ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: article.imageUrl != null &&
                                  article.imageUrl!.isNotEmpty
                              ? Image.network(
                                  article.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image_not_supported,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.article,
                                  size: 50,
                                ),
                          title: Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${article.source}\n${_formatDate(article.publishedAt)}',
                            maxLines: 2,
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year à $hour:$minute';
  }
}
