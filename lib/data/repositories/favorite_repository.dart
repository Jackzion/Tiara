import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/repositories/anime_repository.dart';

/// 收藏仓库：收藏 CRUD + 内存缓存（供同步 isFavorite 使用）
class FavoriteRepository {
  FavoriteRepository({
    required this.database,
    required this.animeRepository,
  });

  final IDatabase database;
  final AnimeRepository animeRepository;

  /// 收藏内存缓存
  List<DBFavorite> _favorites = [];

  /// 初始化：预热收藏内存缓存
  Future<void> setup() async {
    await _reloadFavorites();
  }

  Future<void> _reloadFavorites() async {
    _favorites = await database.getFavorites();
  }

  /// 收藏列表流（来自数据库）
  Stream<List<DBFavorite>> streamFavorites() {
    return database.streamFavorites();
  }

  /// 读取全部收藏
  Future<List<DBFavorite>> getFavorites() async {
    return database.getFavorites();
  }

  /// 保存收藏（全量字段，重启后无需再请求）
  Future saveFavorite(AnimeDetails details) async {
    await database.saveFavorite(
      DBFavorite(
        id: details.bangumiId,
        animeId: details.bangumiId,
        posterPath: details.image,
        favorite: true,
        popularity: details.score ?? 0,
        releaseDate: DateTime(details.year ?? DateTime.now().year),
        title: details.displayTitle,
        overview: details.synopsis ?? '',
      ),
    );
    await _reloadFavorites();
  }

  /// 按行 ID 移除收藏
  Future<bool> removeFavorite(int id) async {
    final ok = await database.removeFavorite(id);
    await _reloadFavorites();
    return ok;
  }

  /// 判断动漫是否已收藏（读内存缓存，setup/收藏变更后刷新）
  bool isFavorite(int animeId) {
    return _favorites.any((fav) => fav.animeId == animeId && fav.favorite);
  }

  /// 切换动漫收藏状态
  Future toggleFavorite(Anime anime) async {
    // 先从内存缓存中查找是否已收藏
    final index = _favorites.indexWhere((fav) => fav.animeId == anime.animeId);
    // 如果已收藏，移除, 并刷新内存缓存
    if (index != -1) {
      await database.removeFavorite(_favorites[index].id);
      await _reloadFavorites();
      return;
    }
    // 如果未收藏，添加, 并刷新内存缓存
    final details = await animeRepository.getAnimeDetails(anime.bangumiId);
    if (details != null) {
      await saveFavorite(details);
    } else {
      await database.saveFavorite(
        DBFavorite(
          id: anime.animeId,
          animeId: anime.animeId,
          posterPath: anime.image,
          favorite: true,
          popularity: anime.score ?? 0,
          releaseDate: anime.aired ?? DateTime.now(),
          title: anime.title ?? '',
          overview: anime.synopsis ?? '',
        ),
      );
    }
    await _reloadFavorites();
  }
}
