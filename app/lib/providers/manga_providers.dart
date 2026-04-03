import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../services/manga_api_service.dart';
import 'auth_provider.dart';

// Provider for manga API service with auth token
final mangaApiProvider = Provider((ref) {
  final authToken = ref.watch(authTokenProvider).value;
  return MangaApiService(authToken: authToken);
});

// Search and filter state
final searchQueryProvider = StateProvider<String>((ref) => '');
final genreFilterProvider = StateProvider<String?>((ref) => null);
final autorFilterProvider = StateProvider<String?>((ref) => null);
final verlagFilterProvider = StateProvider<String?>((ref) => null);
final spracheFilterProvider = StateProvider<String?>((ref) => null);
final readFilterProvider = StateProvider<bool?>((ref) => null);
final doubleFilterProvider = StateProvider<bool?>((ref) => null);
final newbuyFilterProvider = StateProvider<bool?>((ref) => null);

// Pagination state
final currentPageProvider = StateProvider<int>((ref) => 1);
final itemsPerPageProvider = StateProvider<int>((ref) => 20);

// Provider for manga list with filters and pagination
final mangaListProvider = FutureProvider.autoDispose<MangaListResponse>((ref) async {
  final apiService = ref.watch(mangaApiProvider);
  final search = ref.watch(searchQueryProvider);
  final genre = ref.watch(genreFilterProvider);
  final autor = ref.watch(autorFilterProvider);
  final verlag = ref.watch(verlagFilterProvider);
  final sprache = ref.watch(spracheFilterProvider);
  final read = ref.watch(readFilterProvider);
  final double = ref.watch(doubleFilterProvider);
  final newbuy = ref.watch(newbuyFilterProvider);
  final page = ref.watch(currentPageProvider);
  final limit = ref.watch(itemsPerPageProvider);

  return await apiService.getMangas(
    page: page,
    limit: limit,
    search: search.isEmpty ? null : search,
    genre: genre,
    autor: autor,
    verlag: verlag,
    sprache: sprache,
    read: read,
    double: double,
    newbuy: newbuy,
  );
});

// Provider for stats
final statsProvider = FutureProvider.autoDispose<MangaStats>((ref) async {
  final apiService = ref.watch(mangaApiProvider);
  return await apiService.getStats();
});
