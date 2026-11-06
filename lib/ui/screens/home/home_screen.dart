import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/home_controller.dart';
import 'package:movies/ui/screens/home/home_screen_image.dart';
import 'package:movies/ui/screens/home/title_row.dart';
import 'package:movies/ui/screens/home/horiz_animes.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/anime_widget.dart';
import 'package:movies/ui/widgets/not_ready.dart';

/// 主页
/// 展示轮播图和不同分类的动漫列表
@RoutePage(name: 'HomeRoute')
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // 数据层就绪（标签/收藏/补充缓存预热）后才渲染
    final dataReadyAsync = ref.watch(dataReadyProvider);
    return dataReadyAsync.when(
      error: (e, st) => Text(e.toString()),
      loading: () => const NotReady(),
      data: (_) => buildScreen(),
    );
  }

  Widget buildScreen() {
    final homeAsync = ref.watch(homeControllerProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: homeAsync.when(
        loading: () => const NotReady(),
        error: (e, st) => Text(e.toString()),
        data: (home) => SingleChildScrollView(
          child: Container(
            color: screenBackground,
            child: Column(
              children: [
                HomeScreenImage(
                  onAnimeTap: onAnimeTap,
                  nowPlayingAnimes: home.nowPlayingAnimes,
                ),
                TitleRow(text: 'trending ', onMoreClicked: () {}),
                HorizontalAnimes(
                  animes: home.trendingAnimes,
                  onAnimeTap: onAnimeTap,
                  animeType: AnimeType.trending,
                ),
                TitleRow(text: 'popular ', onMoreClicked: () {}),
                HorizontalAnimes(
                  animes: home.popularAnimes,
                  onAnimeTap: onAnimeTap,
                  animeType: AnimeType.popular,
                ),
                TitleRow(text: 'top-rated ', onMoreClicked: () {}),
                HorizontalAnimes(
                  animes: home.topRatedAnimes,
                  onAnimeTap: onAnimeTap,
                  animeType: AnimeType.topRated,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 动漫点击回调，跳转到动漫详情页
  void onAnimeTap(int animeId, String? heroTag) {
    context.router.push(AnimeDetailRoute(animeId: animeId, heroTag: heroTag));
  }
}
