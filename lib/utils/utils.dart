import 'dart:io';

import 'package:flutter/material.dart';
import 'package:movies/data/models/anime_trailer.dart';
import 'package:movies/data/database/models/database_models.dart';

/// 是否为桌面平台（Windows / macOS / Linux）
bool isDesktop() {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

Widget addVerticalSpace(double amount) {
  return SizedBox(height: amount);
}

Widget addHorizontalSpace(double amount) {
  return SizedBox(width: amount);
}

/// 动漫点击回调类型
typedef OnAnimeTap = void Function(int animeId, String? heroTag);

/// 预告片点击回调类型
typedef OnAnimeTrailerTap = void Function(AnimeTrailer trailer);

/// 收藏结果点击回调类型
typedef OnFavoriteResultsTap = void Function(DBFavorite favorite);

String youtubeUrlFromId(String videoId) {
  return 'https://www.youtube.com/watch?v=$videoId';
}

/// 排序方式枚举
enum Sorting {
  aToz(name: 'A-Z'),
  zToa(name: 'Z-A'),
  rating(name: 'Rating'),
  year(name: 'Year');

  const Sorting({required this.name});
  final String name;
}
