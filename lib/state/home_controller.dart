import 'package:movies/data/models/anime.dart';
import 'package:movies/data/repositories/anime_repository.dart';

/// 首页控制器
/// 持有首页四个横栏列表，负责一次性加载（Future 记忆，rebuild 不重拉）
class HomeController {
  HomeController(this.animeRepository);

  final AnimeRepository animeRepository;

  /// 热门动漫列表（sort=heat）
  List<Anime> trendingAnimes = [];

  /// 高评分动漫列表（评分 >= 8.5）
  List<Anime> popularAnimes = [];

  /// 排行榜动漫列表（排名 <= 300）
  List<Anime> topRatedAnimes = [];

  /// 本季放送动漫列表（放送日历）
  List<Anime> nowPlayingAnimes = [];

  Future<void>? _loadFuture;

  /// 加载全部横栏数据（记忆化：窗口缩放 / rebuild 不得重新拉接口）
  Future<void> loadAll() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      animeRepository.getTrendingAnimes(1),
      animeRepository.getTopRated(1),
      animeRepository.getPopular(1),
      animeRepository.getNowPlaying(1),
    ]);
    trendingAnimes = results[0] ?? [];
    topRatedAnimes = results[1] ?? [];
    popularAnimes = results[2] ?? [];
    nowPlayingAnimes = results[3] ?? [];
  }
}
