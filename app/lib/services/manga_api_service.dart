import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';

class MangaApiService {
  static const String baseUrl = 'https://manga-api.intern.phudevelopement.xyz';
  static const String apiKey = 'NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=';

  final String? authToken;

  MangaApiService({this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// Get list of mangas with optional filters
  Future<MangaListResponse> getMangas({
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
    String? autor,
    String? verlag,
    String? sprache,
    bool? read,
    bool? double,
    bool? newbuy,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (search != null && search.isNotEmpty) 'search': search,
      if (genre != null && genre.isNotEmpty) 'genre': genre,
      if (autor != null && autor.isNotEmpty) 'autor': autor,
      if (verlag != null && verlag.isNotEmpty) 'verlag': verlag,
      if (sprache != null && sprache.isNotEmpty) 'sprache': sprache,
      if (read != null) 'read': read.toString(),
      if (double != null) 'double': double.toString(),
      if (newbuy != null) 'newbuy': newbuy.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/manga').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MangaListResponse.fromJson(json);
    } else {
      throw Exception('Failed to load mangas: ${response.statusCode}');
    }
  }

  /// Get single manga by ID
  Future<Manga> getManga(String id) async {
    final uri = Uri.parse('$baseUrl/api/manga/$id');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Manga.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('Manga not found');
    } else {
      throw Exception('Failed to load manga: ${response.statusCode}');
    }
  }

  /// Create new manga
  Future<Manga> createManga(Manga manga) async {
    final uri = Uri.parse('$baseUrl/api/manga');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(manga.toJson()),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return Manga.fromJson(json);
    } else {
      throw Exception('Failed to create manga: ${response.statusCode}');
    }
  }

  /// Update existing manga
  Future<Manga> updateManga(String id, Map<String, dynamic> updates) async {
    final uri = Uri.parse('$baseUrl/api/manga/$id');

    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Manga.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('Manga not found');
    } else {
      throw Exception('Failed to update manga: ${response.statusCode}');
    }
  }

  /// Delete manga
  Future<void> deleteManga(String id) async {
    final uri = Uri.parse('$baseUrl/api/manga/$id');

    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw Exception('Manga not found');
      } else {
        throw Exception('Failed to delete manga: ${response.statusCode}');
      }
    }
  }

  /// Get statistics
  Future<MangaStats> getStats() async {
    final uri = Uri.parse('$baseUrl/api/manga/stats/summary');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MangaStats.fromJson(json);
    } else {
      throw Exception('Failed to load stats: ${response.statusCode}');
    }
  }

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
