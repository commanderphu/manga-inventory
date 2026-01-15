// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manga.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manga _$MangaFromJson(Map<String, dynamic> json) => Manga(
      id: json['id'] as String,
      titel: json['titel'] as String,
      band: json['band'] as String?,
      genre: json['genre'] as String?,
      autor: json['autor'] as String?,
      verlag: json['verlag'] as String?,
      isbn: json['isbn'] as String?,
      sprache: json['sprache'] as String?,
      coverImage: json['cover_image'] as String?,
      read: json['read'] as bool? ?? false,
      double: json['double'] as bool? ?? false,
      newbuy: json['newbuy'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MangaToJson(Manga instance) => <String, dynamic>{
      'id': instance.id,
      'titel': instance.titel,
      'band': instance.band,
      'genre': instance.genre,
      'autor': instance.autor,
      'verlag': instance.verlag,
      'isbn': instance.isbn,
      'sprache': instance.sprache,
      'cover_image': instance.coverImage,
      'read': instance.read,
      'double': instance.double,
      'newbuy': instance.newbuy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

MangaListResponse _$MangaListResponseFromJson(Map<String, dynamic> json) =>
    MangaListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => Manga.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MangaListResponseToJson(MangaListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'pagination': instance.pagination,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };

MangaStats _$MangaStatsFromJson(Map<String, dynamic> json) => MangaStats(
      total: json['total'] as String,
      read: json['read'] as String,
      duplicates: json['duplicates'] as String,
      toBuy: json['to_buy'] as String,
    );

Map<String, dynamic> _$MangaStatsToJson(MangaStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'read': instance.read,
      'duplicates': instance.duplicates,
      'to_buy': instance.toBuy,
    };
