import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:movies/data/models/play_context.dart';
import 'package:movies/ui/main_screen.dart';
import 'package:movies/ui/screens/comic_reader/comic_reader.dart';
import 'package:movies/ui/screens/genres/genre_screen.dart';
import 'package:movies/ui/screens/home/home_screen.dart';
import 'package:movies/ui/screens/favorites/favorite_screen.dart';
import 'package:movies/ui/screens/anime_detail/anime_detail.dart';
import 'package:movies/ui/screens/videos/video_page.dart';

part 'app_routes.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: '/',
      initial: true,
      page: MainRoute.page,
      children: [
        AutoRoute(path: 'home', page: HomeRoute.page),
        AutoRoute(path: 'Genre', page: GenreRoute.page),
        AutoRoute(path: 'favorites', page: FavoriteRoute.page),
      ],
    ),
    CustomRoute(
      path: '/details/:animeId',
      page: AnimeDetailRoute.page,
      maintainState: false,
      transitionsBuilder: TransitionsBuilders.slideBottom,
      duration: const Duration(milliseconds: 500),
    ),
    CustomRoute(
      path: '/comic-reader',
      page: ComicReaderRoute.page,
      maintainState: false,
      transitionsBuilder: TransitionsBuilders.slideLeftWithFade,
      duration: const Duration(milliseconds: 500),
    ),
    // 视频播放页面路由
    CustomRoute(
      path: '/video',
      page: VideoPageRoute.page,
      maintainState: false,
      transitionsBuilder: TransitionsBuilders.slideLeftWithFade,
      duration: const Duration(milliseconds: 500),
    ),
  ];
}
