import 'package:collection/collection.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/providers.dart';
import 'package:movies/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_controller.g.dart';

/// 收藏列表流（数据库变更自动推送）
@riverpod
Stream<List<DBFavorite>> favoriteList(Ref ref) {
  return ref.read(favoriteRepositoryProvider).streamFavorites();
}

/// 收藏页控制器（autoDispose：随页面销毁）
/// 持有排序方式，负责收藏列表排序与删除
@riverpod
class FavoriteController extends _$FavoriteController {
  @override
  Sorting build() => Sorting.aToz;

  /// 按当前排序方式排序收藏列表
  List<DBFavorite> sortFavorites(List<DBFavorite> source) {
    return source.sorted((a, b) {
      switch (state) {
        case Sorting.aToz:
          return a.title.compareTo(b.title);
        case Sorting.zToa:
          return b.title.compareTo(a.title);
        case Sorting.rating:
          return b.popularity.compareTo(a.popularity);
        case Sorting.year:
          return a.releaseDate.compareTo(b.releaseDate);
      }
    });
  }

  /// 切换排序方式
  void setSort(Sorting sorting) {
    state = sorting;
  }

  /// 移除收藏（favoriteList 流会自动推送新列表，UI 无需手动刷新）
  Future<bool> removeFavorite(DBFavorite favorite) {
    return ref.read(favoriteRepositoryProvider).removeFavorite(favorite.id);
  }
}
