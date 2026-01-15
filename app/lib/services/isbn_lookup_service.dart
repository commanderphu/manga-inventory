import 'dart:convert';
import 'package:http/http.dart' as http;

class IsbnLookupService {
  static const String googleBooksApi = 'https://www.googleapis.com/books/v1/volumes';
  static const String openLibraryApi = 'https://openlibrary.org/api/books';

  /// Lookup book information by ISBN with fallback to multiple sources
  Future<BookInfo?> lookupByIsbn(String isbn) async {
    try {
      // Clean ISBN (remove spaces and dashes)
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');

      // Try Google Books first
      final googleResult = await _lookupGoogleBooks(cleanIsbn);
      if (googleResult != null) {
        // If no cover, try to find one from Open Library
        if (googleResult.coverImage == null) {
          final openLibraryCover = await _lookupOpenLibraryCover(cleanIsbn);
          if (openLibraryCover != null) {
            return BookInfo(
              title: googleResult.title,
              authors: googleResult.authors,
              publisher: googleResult.publisher,
              language: googleResult.language,
              categories: googleResult.categories,
              coverImage: openLibraryCover,
              description: googleResult.description,
            );
          }
        }
        return googleResult;
      }

      // If Google Books fails, try Open Library
      return await _lookupOpenLibrary(cleanIsbn);
    } catch (e) {
      print('Error looking up ISBN: $e');
      return null;
    }
  }

  /// Lookup from Google Books API
  Future<BookInfo?> _lookupGoogleBooks(String isbn) async {
    try {
      final uri = Uri.parse('$googleBooksApi?q=isbn:$isbn');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['totalItems'] > 0) {
          final volumeInfo = json['items'][0]['volumeInfo'];

          return BookInfo(
            title: volumeInfo['title'] ?? '',
            authors: volumeInfo['authors'] != null
                ? (volumeInfo['authors'] as List).join(', ')
                : null,
            publisher: volumeInfo['publisher'],
            language: _mapLanguageCode(volumeInfo['language']),
            categories: volumeInfo['categories'] != null
                ? (volumeInfo['categories'] as List).join(', ')
                : null,
            coverImage: _getBestCoverImage(volumeInfo['imageLinks']),
            description: volumeInfo['description'],
          );
        }
      }
      return null;
    } catch (e) {
      print('Error in Google Books lookup: $e');
      return null;
    }
  }

  /// Lookup cover from Open Library
  Future<String?> _lookupOpenLibraryCover(String isbn) async {
    try {
      // Open Library has direct cover API
      final coverUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';

      // Check if cover exists
      final response = await http.head(Uri.parse(coverUrl));
      if (response.statusCode == 200) {
        return coverUrl;
      }
      return null;
    } catch (e) {
      print('Error in Open Library cover lookup: $e');
      return null;
    }
  }

  /// Lookup from Open Library API
  Future<BookInfo?> _lookupOpenLibrary(String isbn) async {
    try {
      final uri = Uri.parse('$openLibraryApi?bibkeys=ISBN:$isbn&format=json&jscmd=data');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final bookKey = 'ISBN:$isbn';

        if (json.containsKey(bookKey)) {
          final bookData = json[bookKey];

          return BookInfo(
            title: bookData['title'] ?? '',
            authors: bookData['authors'] != null && (bookData['authors'] as List).isNotEmpty
                ? (bookData['authors'] as List).map((a) => a['name']).join(', ')
                : null,
            publisher: bookData['publishers'] != null && (bookData['publishers'] as List).isNotEmpty
                ? (bookData['publishers'] as List)[0]['name']
                : null,
            language: null, // Open Library doesn't provide language in this format
            categories: bookData['subjects'] != null && (bookData['subjects'] as List).isNotEmpty
                ? (bookData['subjects'] as List).map((s) => s['name']).join(', ')
                : null,
            coverImage: bookData['cover']?['large'] ?? bookData['cover']?['medium'] ?? bookData['cover']?['small'],
            description: null,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error in Open Library lookup: $e');
      return null;
    }
  }

  /// Get the best quality cover image
  String? _getBestCoverImage(dynamic imageLinks) {
    if (imageLinks == null) return null;

    // Try to get the highest quality image available
    if (imageLinks['extraLarge'] != null) {
      return imageLinks['extraLarge'].toString().replaceAll('http://', 'https://');
    }
    if (imageLinks['large'] != null) {
      return imageLinks['large'].toString().replaceAll('http://', 'https://');
    }
    if (imageLinks['medium'] != null) {
      return imageLinks['medium'].toString().replaceAll('http://', 'https://');
    }
    if (imageLinks['small'] != null) {
      return imageLinks['small'].toString().replaceAll('http://', 'https://');
    }
    if (imageLinks['thumbnail'] != null) {
      return imageLinks['thumbnail'].toString().replaceAll('http://', 'https://');
    }
    if (imageLinks['smallThumbnail'] != null) {
      return imageLinks['smallThumbnail'].toString().replaceAll('http://', 'https://');
    }

    return null;
  }

  /// Map language codes to readable names
  String? _mapLanguageCode(String? code) {
    if (code == null) return null;

    final languageMap = {
      'de': 'Deutsch',
      'en': 'Englisch',
      'ja': 'Japanisch',
      'es': 'Spanisch',
      'fr': 'Französisch',
      'it': 'Italienisch',
      'pt': 'Portugiesisch',
      'zh': 'Chinesisch',
      'ko': 'Koreanisch',
    };

    return languageMap[code.toLowerCase()] ?? code;
  }
}

class BookInfo {
  final String title;
  final String? authors;
  final String? publisher;
  final String? language;
  final String? categories;
  final String? coverImage;
  final String? description;

  BookInfo({
    required this.title,
    this.authors,
    this.publisher,
    this.language,
    this.categories,
    this.coverImage,
    this.description,
  });
}
