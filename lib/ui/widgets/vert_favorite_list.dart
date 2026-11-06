import 'package:flutter/material.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/ui/widgets/favorite_row.dart';

/// 纵向收藏动漫列表组件
class VerticalFavoriteList extends StatelessWidget {
  final List<DBFavorite> favorites;
  final OnAnimeTap onAnimeTap;
  final OnFavoriteResultsTap onFavoritesTap;

  const VerticalFavoriteList({
    super.key,
    required this.favorites,
    required this.onAnimeTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return FavoriteRow(
            favorite: favorites[index],
            onAnimeTap: onAnimeTap,
            onFavoritesTap: onFavoritesTap,
          );
        },
        childCount: favorites.length,
      ),
    );
  }
}
