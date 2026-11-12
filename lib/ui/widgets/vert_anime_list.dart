import 'package:flutter/material.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/ui/widgets/anime_row.dart';
import 'package:movies/utils/utils.dart';

/// 列表展示模式
enum AnimeViewMode {
  /// 紧凑文本行
  list,

  /// 详细行（封面 + 信息块）
  detail,

  /// 封面网格
  grid,
}

/// 纵向动漫列表：按视图模式渲染详细行 / 紧凑行 / 网格
class VerticalAnimeList extends StatelessWidget {
  /// 动漫列表数据
  final List<Anime> animes;

  /// 点击回调
  final OnAnimeTap onAnimeTap;

  /// 展示模式
  final AnimeViewMode viewMode;

  const VerticalAnimeList({
    super.key,
    required this.animes,
    required this.onAnimeTap,
    this.viewMode = AnimeViewMode.detail,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case AnimeViewMode.list:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                AnimeCompactRow(anime: animes[index], onAnimeTap: onAnimeTap),
            childCount: animes.length,
          ),
        );
      case AnimeViewMode.grid:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisExtent: 290,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  AnimeGridTile(anime: animes[index], onAnimeTap: onAnimeTap),
              childCount: animes.length,
            ),
          ),
        );
      case AnimeViewMode.detail:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                AnimeRow(anime: animes[index], onAnimeTap: onAnimeTap),
            childCount: animes.length,
          ),
        );
    }
  }
}
