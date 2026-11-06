import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.g.dart';

/// 首页四横栏数据
class HomeState {
  const HomeState({
    this.trendingAnimes = const [],
    this.popularAnimes = const [],
    this.topRatedAnimes = const [],
    this.nowPlayingAnimes = const [],
  });

  /// 热门动漫列表（sort=heat）
  final List<Anime> trendingAnimes;

  /// 高评分动漫列表（评分 >= 8.5）
  final List<Anime> popularAnimes;

  /// 排行榜动漫列表（排名 <= 300）
  final List<Anime> topRatedAnimes;

  /// 本季放送动漫列表（放送日历）
  final List<Anime> nowPlayingAnimes;
}

/// 首页控制器
/// build 即一次性加载四横栏；keepAlive + Riverpod 记忆化保证 rebuild 不重拉
@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {

  // init state
  @override
  Future<HomeState> build() async {
    final repo = ref.read(animeRepositoryProvider);
    final results = await Future.wait([
      repo.getTrendingAnimes(1),
      repo.getTopRated(1),
      repo.getPopular(1),
      repo.getNowPlaying(1),
    ]);
    return HomeState(
      trendingAnimes: results[0] ?? [],
      topRatedAnimes: results[1] ?? [],
      popularAnimes: results[2] ?? [],
      nowPlayingAnimes: results[3] ?? [],
    );
  }
}
