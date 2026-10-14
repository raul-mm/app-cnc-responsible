import 'dart:convert';
import 'package:app_movil_comunidad/models/post_cnc.dart';
import 'package:http/http.dart' as http;

class PostPage {
  final List<PostModel> posts;
  final int totalPages;
  final int total;

  PostPage(this.posts, this.totalPages, this.total);
}

class WordPressService {
  // El sitio publica las noticias como tipo propio "noticias"
  // (https://neocatechumenaleiter.org/noticias/), no en /posts.
  static const _baseUrl =
      'https://neocatechumenaleiter.org/wp-json/wp/v2/noticias';

  Future<PostPage> fetchPosts(int page, int perPage, {String? search}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
        '_embed': 'wp:featuredmedia',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    // WordPress responde 400 al pedir una página más allá de la última
    if (response.statusCode == 400 && page > 1) {
      return PostPage([], page - 1, 0);
    }
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode} al cargar noticias');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return PostPage(
      data.map((json) => PostModel.fromJson(json)).toList(),
      int.tryParse(response.headers['x-wp-totalpages'] ?? '') ?? page,
      int.tryParse(response.headers['x-wp-total'] ?? '') ?? data.length,
    );
  }
}
