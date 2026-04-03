import 'dart:convert';
import '../models/manga.dart';
import 'manga_api_service.dart';
import 'local_db_service.dart';

class SyncService {
  static SyncService? _instance;

  String? _authToken;
  bool _isOnline = true;
  bool _isSyncing = false;
  final LocalDbService _localDb = LocalDbService();

  SyncService._internal();

  static SyncService get instance {
    _instance ??= SyncService._internal();
    return _instance!;
  }

  MangaApiService get _api => MangaApiService(authToken: _authToken);

  bool get isOnline => _isOnline;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setOnlineStatus(bool isOnline) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;
    if (isOnline && wasOffline) {
      syncPendingOperations();
    }
  }

  /// Fetch all manga from API and cache locally
  Future<void> syncAll() async {
    if (!_isOnline) return;
    try {
      final first = await _api.getMangas(page: 1, limit: 100);
      await _localDb.cacheMangas(first.data);
      final totalPages = first.pagination.pages;
      for (int p = 2; p <= totalPages; p++) {
        final page = await _api.getMangas(page: p, limit: 100);
        await _localDb.cacheMangas(page.data);
      }
    } catch (_) {
      // Sync failed silently - try again later
    }
  }

  Future<MangaListResponse> getMangas({
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
    String? autor,
    String? verlag,
    String? sprache,
    bool? read,
    bool? isDouble,
    bool? newbuy,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    if (_isOnline) {
      try {
        final response = await _api.getMangas(
          page: page,
          limit: limit,
          search: search,
          genre: genre,
          autor: autor,
          verlag: verlag,
          sprache: sprache,
          read: read,
          double: isDouble,
          newbuy: newbuy,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
        // Cache in background
        _localDb.cacheMangas(response.data);
        return response;
      } catch (_) {
        // API unavailable – fall through to offline
      }
    }

    // Offline: query local SQLite
    final mangas = await _localDb.queryMangas(
      page: page,
      limit: limit,
      search: search,
      genre: genre,
      autor: autor,
      verlag: verlag,
      sprache: sprache,
      read: read,
      isDouble: isDouble,
      newbuy: newbuy,
      sortBy: sortBy,
      sortOrder: sortOrder.toUpperCase(),
    );
    final total = await _localDb.countMangas(
      search: search,
      genre: genre,
      autor: autor,
      verlag: verlag,
      sprache: sprache,
      read: read,
      isDouble: isDouble,
      newbuy: newbuy,
    );
    final pages = limit > 0 ? ((total + limit - 1) ~/ limit) : 1;
    return MangaListResponse(
      data: mangas,
      pagination: Pagination(
        page: page,
        limit: limit,
        total: total,
        pages: pages,
      ),
    );
  }

  Future<MangaStats> getStats() async {
    if (_isOnline) {
      try {
        return await _api.getStats();
      } catch (_) {}
    }
    // Offline: compute from local DB
    final total = await _localDb.countMangas();
    final read = await _localDb.countMangas(read: true);
    final duplicates = await _localDb.countMangas(isDouble: true);
    final toBuy = await _localDb.countMangas(newbuy: true);
    return MangaStats(
      total: total.toString(),
      read: read.toString(),
      duplicates: duplicates.toString(),
      toBuy: toBuy.toString(),
    );
  }

  Future<Manga> createManga(Manga manga) async {
    if (_isOnline) {
      try {
        final created = await _api.createManga(manga);
        await _localDb.upsertManga(created);
        return created;
      } catch (_) {
        // API unavailable – create offline
      }
    }
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localManga = manga.copyWith(
      id: tempId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _localDb.upsertManga(localManga, isLocal: true);
    await _localDb.addPendingSync('create', tempId, localManga.toJson());
    return localManga;
  }

  Future<Manga> updateManga(String id, Map<String, dynamic> updates) async {
    if (_isOnline) {
      try {
        final updated = await _api.updateManga(id, updates);
        await _localDb.upsertManga(updated);
        return updated;
      } catch (_) {
        // API unavailable – update offline
      }
    }
    await _localDb.updateManga(id, updates);
    if (!id.startsWith('local_')) {
      await _localDb.addPendingSync('update', id, updates);
    }
    final local = await _localDb.getManga(id);
    return local!;
  }

  Future<void> deleteManga(String id) async {
    if (_isOnline) {
      try {
        await _api.deleteManga(id);
        await _localDb.deleteManga(id);
        return;
      } catch (_) {
        // API unavailable – delete offline
      }
    }
    await _localDb.deleteManga(id);
    if (!id.startsWith('local_')) {
      await _localDb.addPendingSync('delete', id, null);
    }
  }

  /// Push pending offline operations to the server
  Future<void> syncPendingOperations() async {
    if (!_isOnline || _isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await _localDb.getPendingSync();
      for (final op in pending) {
        final opId = op['id'] as int;
        final operation = op['operation'] as String;
        final mangaId = op['manga_id'] as String;
        final payload = op['payload'] != null
            ? jsonDecode(op['payload'] as String) as Map<String, dynamic>
            : null;

        try {
          if (operation == 'create' && payload != null) {
            final manga = Manga.fromJson(payload);
            final serverManga = await _api.createManga(manga.copyWith(id: ''));
            await _localDb.replaceMangaId(mangaId, serverManga.id);
          } else if (operation == 'update' && payload != null) {
            if (!mangaId.startsWith('local_')) {
              await _api.updateManga(mangaId, payload);
            }
          } else if (operation == 'delete') {
            if (!mangaId.startsWith('local_')) {
              await _api.deleteManga(mangaId);
            }
          }
          await _localDb.removePendingSync(opId);
        } catch (_) {
          // Keep in queue for next sync attempt
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> getPendingSyncCount() => _localDb.countPendingSync();
}
