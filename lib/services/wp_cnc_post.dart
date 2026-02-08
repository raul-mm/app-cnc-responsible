import 'dart:convert';
import 'package:app_movil_comunidad/models/post_cnc.dart';
import 'package:http/http.dart' as http;

class WordPressService {
  final String baseUrl = 'https://neocatechumenaleiter.org/wp-json/wp/v2/posts';

  Future<List<PostModel>> fetchPosts(int page, int perPage) async {
    final response = await http.get(
      Uri.parse('$baseUrl?page=$page&per_page=$perPage'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar posts');
    }
  }
}
