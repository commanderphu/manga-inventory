import 'package:json_annotation/json_annotation.dart';

part 'manga.g.dart';

@JsonSerializable()
class Manga {
  final String id;
  final String titel;
  final String? band;
  final String? genre;
  final String? autor;
  final String? verlag;
  final String? isbn;
  final String? sprache;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final bool read;
  final bool double;
  final bool newbuy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Manga({
    required this.id,
    required this.titel,
    this.band,
    this.genre,
    this.autor,
    this.verlag,
    this.isbn,
    this.sprache,
    this.coverImage,
    this.read = false,
    this.double = false,
    this.newbuy = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Manga.fromJson(Map<String, dynamic> json) => _$MangaFromJson(json);
  Map<String, dynamic> toJson() => _$MangaToJson(this);

  Manga copyWith({
    String? id,
    String? titel,
    String? band,
    String? genre,
    String? autor,
    String? verlag,
    String? isbn,
    String? sprache,
    String? coverImage,
    bool? read,
    bool? double,
    bool? newbuy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Manga(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      band: band ?? this.band,
      genre: genre ?? this.genre,
      autor: autor ?? this.autor,
      verlag: verlag ?? this.verlag,
      isbn: isbn ?? this.isbn,
      sprache: sprache ?? this.sprache,
      coverImage: coverImage ?? this.coverImage,
      read: read ?? this.read,
      double: double ?? this.double,
      newbuy: newbuy ?? this.newbuy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class MangaListResponse {
  final List<Manga> data;
  final Pagination pagination;

  MangaListResponse({
    required this.data,
    required this.pagination,
  });

  factory MangaListResponse.fromJson(Map<String, dynamic> json) =>
      _$MangaListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MangaListResponseToJson(this);
}

@JsonSerializable()
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}

@JsonSerializable()
class MangaStats {
  final String total;
  final String read;
  final String duplicates;
  @JsonKey(name: 'to_buy')
  final String toBuy;

  MangaStats({
    required this.total,
    required this.read,
    required this.duplicates,
    required this.toBuy,
  });

  factory MangaStats.fromJson(Map<String, dynamic> json) =>
      _$MangaStatsFromJson(json);
  Map<String, dynamic> toJson() => _$MangaStatsToJson(this);
}
