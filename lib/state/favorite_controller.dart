import 'package:collection/collection.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/data/repositories/favorite_repository.dart';
import 'package:movies/utils/utils.dart';

/// 收藏页控制器
/// 持有排序方式，负责收藏列表排序与删除
class FavoriteController {
  FavoriteController(this.favoriteRepository);

  final FavoriteRepository favoriteRepository;

  /// 排序方式
  Sorting selectedSort = Sorting.aToz;

  /// 收藏列表流（来自数据库）
  Stream<List<DBFavorite>> stream() => favoriteRepository.streamFavorites();

  /// 按当前排序方式排序收藏列表
  List<DBFavorite> sortFavorites(List<DBFavorite> source) {
    return source.sorted((a, b) {
      switch (selectedSort) {
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

  /// 移除收藏
  Future<bool> removeFavorite(DBFavorite favorite) {
    return favoriteRepository.removeFavorite(favorite.id);
  }
}
