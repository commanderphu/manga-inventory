import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/manga.dart';

class LocalDbService {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'manga_local.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE manga (
            id TEXT PRIMARY KEY,
            titel TEXT NOT NULL,
            band TEXT,
            genre TEXT,
            autor TEXT,
            verlag TEXT,
            isbn TEXT,
            sprache TEXT,
            cover_image TEXT,
            read_status INTEGER DEFAULT 0,
            is_double INTEGER DEFAULT 0,
            newbuy INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT,
            is_local INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_sync (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation TEXT NOT NULL,
            manga_id TEXT NOT NULL,
            payload TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Manga _rowToManga(Map<String, dynamic> row) {
    return Manga(
      id: row['id'] as String,
      titel: row['titel'] as String,
      band: row['band'] as String?,
      genre: row['genre'] as String?,
      autor: row['autor'] as String?,
      verlag: row['verlag'] as String?,
      isbn: row['isbn'] as String?,
      sprache: row['sprache'] as String?,
      coverImage: row['cover_image'] as String?,
      read: (row['read_status'] as int) == 1,
      double: (row['is_double'] as int) == 1,
      newbuy: (row['newbuy'] as int) == 1,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _mangaToRow(Manga manga, {bool isLocal = false}) {
    return {
      'id': manga.id,
      'titel': manga.titel,
      'band': manga.band,
      'genre': manga.genre,
      'autor': manga.autor,
      'verlag': manga.verlag,
      'isbn': manga.isbn,
      'sprache': manga.sprache,
      'cover_image': manga.coverImage,
      'read_status': manga.read ? 1 : 0,
      'is_double': manga.double ? 1 : 0,
      'newbuy': manga.newbuy ? 1 : 0,
      'created_at': manga.createdAt?.toIso8601String(),
      'updated_at': manga.updatedAt?.toIso8601String(),
      'is_local': isLocal ? 1 : 0,
    };
  }

  Future<void> cacheMangas(List<Manga> mangas) async {
    final database = await db;
    final batch = database.batch();
    for (final manga in mangas) {
      // Don't overwrite locally-created (offline) entries
      final existing = await database.query(
        'manga',
        where: 'id = ? AND is_local = 1',
        whereArgs: [manga.id],
      );
      if (existing.isEmpty) {
        batch.insert(
          'manga',
          _mangaToRow(manga),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Manga>> queryMangas({
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
    String sortOrder = 'DESC',
  }) async {
    final database = await db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      conditions.add('(titel LIKE ? OR autor LIKE ? OR isbn LIKE ?)');
      final s = '%$search%';
      args.addAll([s, s, s]);
    }
    if (genre != null && genre.isNotEmpty) {
      conditions.add('genre = ?');
      args.add(genre);
    }
    if (autor != null && autor.isNotEmpty) {
      conditions.add('autor = ?');
      args.add(autor);
    }
    if (verlag != null && verlag.isNotEmpty) {
      conditions.add('verlag = ?');
      args.add(verlag);
    }
    if (sprache != null && sprache.isNotEmpty) {
      conditions.add('sprache = ?');
      args.add(sprache);
    }
    if (read != null) {
      conditions.add('read_status = ?');
      args.add(read ? 1 : 0);
    }
    if (isDouble != null) {
      conditions.add('is_double = ?');
      args.add(isDouble ? 1 : 0);
    }
    if (newbuy != null) {
      conditions.add('newbuy = ?');
      args.add(newbuy ? 1 : 0);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final colMap = {
      'created_at': 'created_at',
      'titel': 'titel',
      'autor': 'autor',
      'band': 'band',
    };
    final sortCol = colMap[sortBy] ?? 'created_at';
    final order = sortOrder.toUpperCase() == 'ASC' ? 'ASC' : 'DESC';
    final offset = (page - 1) * limit;

    final rows = await database.query(
      'manga',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: '$sortCol $order',
      limit: limit,
      offset: offset,
    );
    return rows.map(_rowToManga).toList();
  }

  Future<int> countMangas({
    String? search,
    String? genre,
    String? autor,
    String? verlag,
    String? sprache,
    bool? read,
    bool? isDouble,
    bool? newbuy,
  }) async {
    final database = await db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      conditions.add('(titel LIKE ? OR autor LIKE ? OR isbn LIKE ?)');
      final s = '%$search%';
      args.addAll([s, s, s]);
    }
    if (genre != null && genre.isNotEmpty) {
      conditions.add('genre = ?');
      args.add(genre);
    }
    if (autor != null && autor.isNotEmpty) {
      conditions.add('autor = ?');
      args.add(autor);
    }
    if (verlag != null && verlag.isNotEmpty) {
      conditions.add('verlag = ?');
      args.add(verlag);
    }
    if (sprache != null && sprache.isNotEmpty) {
      conditions.add('sprache = ?');
      args.add(sprache);
    }
    if (read != null) {
      conditions.add('read_status = ?');
      args.add(read ? 1 : 0);
    }
    if (isDouble != null) {
      conditions.add('is_double = ?');
      args.add(isDouble ? 1 : 0);
    }
    if (newbuy != null) {
      conditions.add('newbuy = ?');
      args.add(newbuy ? 1 : 0);
    }

    final where = conditions.isEmpty ? '' : ' WHERE ${conditions.join(' AND ')}';
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM manga$where',
      args.isEmpty ? null : args,
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<Manga?> getManga(String id) async {
    final database = await db;
    final rows =
        await database.query('manga', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToManga(rows.first);
  }

  Future<void> upsertManga(Manga manga, {bool isLocal = false}) async {
    final database = await db;
    await database.insert(
      'manga',
      _mangaToRow(manga, isLocal: isLocal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateManga(String id, Map<String, dynamic> updates) async {
    final database = await db;
    final row = <String, dynamic>{};
    if (updates.containsKey('titel')) row['titel'] = updates['titel'];
    if (updates.containsKey('band')) row['band'] = updates['band'];
    if (updates.containsKey('genre')) row['genre'] = updates['genre'];
    if (updates.containsKey('autor')) row['autor'] = updates['autor'];
    if (updates.containsKey('verlag')) row['verlag'] = updates['verlag'];
    if (updates.containsKey('isbn')) row['isbn'] = updates['isbn'];
    if (updates.containsKey('sprache')) row['sprache'] = updates['sprache'];
    if (updates.containsKey('cover_image')) {
      row['cover_image'] = updates['cover_image'];
    }
    if (updates.containsKey('read')) {
      row['read_status'] = updates['read'] == true ? 1 : 0;
    }
    if (updates.containsKey('double')) {
      row['is_double'] = updates['double'] == true ? 1 : 0;
    }
    if (updates.containsKey('newbuy')) {
      row['newbuy'] = updates['newbuy'] == true ? 1 : 0;
    }
    row['updated_at'] = DateTime.now().toIso8601String();
    if (row.isNotEmpty) {
      await database.update('manga', row, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteManga(String id) async {
    final database = await db;
    await database.delete('manga', where: 'id = ?', whereArgs: [id]);
  }

  // Pending sync queue
  Future<void> addPendingSync(
      String operation, String mangaId, Map<String, dynamic>? payload) async {
    final database = await db;
    await database.insert('pending_sync', {
      'operation': operation,
      'manga_id': mangaId,
      'payload': payload != null ? jsonEncode(payload) : null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final database = await db;
    return database.query('pending_sync', orderBy: 'id ASC');
  }

  Future<void> removePendingSync(int id) async {
    final database = await db;
    await database.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countPendingSync() async {
    final database = await db;
    final result =
        await database.rawQuery('SELECT COUNT(*) as cnt FROM pending_sync');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> replaceMangaId(String oldId, String newId) async {
    final database = await db;
    await database.update(
      'manga',
      {'id': newId, 'is_local': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }
}
