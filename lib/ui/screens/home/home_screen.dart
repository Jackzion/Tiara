import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/home_controller.dart';
import 'package:movies/ui/screens/home/home_screen_image.dart';
import 'package:movies/ui/screens/home/title_row.dart';
import 'package:movies/ui/screens/home/horiz_animes.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/anime_widget.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';
import 'package:movies/ui/widgets/not_ready.dart';

/// 主页：轮播档案 + 分类索引。
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
      error: (e, st) => ArchiveLoadError(message: e.toString()),
      loading: () => const NotReady(),
      data: (_) => buildScreen(),
    );
  }

  Widget buildScreen() {
    final homeAsync = ref.watch(homeControllerProvider);
    return Scaffold(
      backgroundColor: ArchiveTone.of(context).pageEnd,
      body: Atmosphere(
        child: Stack(
          children: [
            Positioned.fill(
              child: homeAsync.when(
                loading: () => const NotReady(),
                error: (e, st) => ArchiveLoadError(message: e.toString()),
                data: (home) => SingleChildScrollView(
                  padding: archivePagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeScreenImage(
                        onAnimeTap: onAnimeTap,
                        nowPlayingAnimes: home.nowPlayingAnimes,
                      ),
                      const SizedBox(height: 36),
                      TitleRow(
                        text: 'trending',
                        code: '01 / TRENDING',
                        onMoreClicked: () {},
                      ),
                      const SizedBox(height: 14),
                      HorizontalAnimes(
                        animes: home.trendingAnimes,
                        onAnimeTap: onAnimeTap,
                        animeType: AnimeType.trending,
                      ),
                      const SizedBox(height: 20),
                      TitleRow(
                        text: 'popular',
                        code: '02 / POPULAR',
                        onMoreClicked: () {},
                      ),
                      const SizedBox(height: 14),
                      HorizontalAnimes(
                        animes: home.popularAnimes,
                        onAnimeTap: onAnimeTap,
                        animeType: AnimeType.popular,
                      ),
                      const SizedBox(height: 20),
                      TitleRow(
                        text: 'top rated',
                        code: '03 / TOP RATED',
                        onMoreClicked: () {},
                      ),
                      const SizedBox(height: 14),
                      HorizontalAnimes(
                        animes: home.topRatedAnimes,
                        onAnimeTap: onAnimeTap,
                        animeType: AnimeType.topRated,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            // 固定报头：品牌方章 + 大标题 + 档案地址
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FrostedHeader(
                child: ArchiveMasthead(
                  title: '动漫档案',
                  code: 'MOVIES / DISCOVERY ARCHIVE',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 动漫点击回调，跳转到动漫详情页
  void onAnimeTap(int animeId, String? heroTag) {
    context.router.push(AnimeDetailRoute(animeId: animeId, heroTag: heroTag));
  }
}
