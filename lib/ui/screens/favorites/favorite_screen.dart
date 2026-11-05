import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/favorite_controller.dart';
import 'package:movies/ui/screens/genres/sort_picker.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/vert_favorite_list.dart';
import 'package:movies/ui/widgets/not_ready.dart';

/// 收藏页面
/// 展示用户收藏的动漫列表，支持排序和收藏状态更新
@RoutePage(name: 'FavoriteRoute')
class FavoriteScreen extends ConsumerStatefulWidget {
  const FavoriteScreen({super.key});

  @override
  ConsumerState<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends ConsumerState<FavoriteScreen> {
  /// 本页控制器（排序 + 收藏操作）
  late final FavoriteController favoriteController =
      FavoriteController(ref.read(favoriteRepositoryProvider));

  List<DBFavorite> currentFavorites = [];

  @override
  Widget build(BuildContext context) {
    // 数据层就绪（收藏缓存预热完成）后才渲染
    final dataReadyAsync = ref.watch(dataReadyProvider);
    return dataReadyAsync.when(
      error: (e, st) => Text(e.toString()),
      loading: () => const NotReady(),
      data: (_) => buildScreen(),
    );
  }

  Widget buildScreen() {
    return SafeArea(
      child: StreamBuilder<List<DBFavorite>>(
        stream: favoriteController.stream(),
        builder: (context, snapshot) {
          if ((snapshot.connectionState != ConnectionState.active) &&
              (snapshot.connectionState != ConnectionState.done)) {
            return const NotReady();
          }
          currentFavorites = favoriteController.sortFavorites(snapshot.requireData);
          return Scaffold(
            body: Container(
              color: screenBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16.0, 0.0, 24.0),
                                child: Text(
                                  'My Favorites',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SortPicker(
                          selectedSort: favoriteController.selectedSort,
                          useSliver: true,
                          onSortSelected: (sorting) {
                            setState(() {
                              favoriteController.selectedSort = sorting;
                            });
                          },
                        ),
                        VerticalFavoriteList(
                          favorites: currentFavorites,
                          onAnimeTap: (animeId) {
                            context.router
                                .push(AnimeDetailRoute(animeId: animeId));
                          },
                          onFavoritesTap: (DBFavorite favorite) {
                            removeFavorite(favorite);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 移除收藏
  Future removeFavorite(DBFavorite favorite) async {
    await favoriteController.removeFavorite(favorite);
    setState(() {});
  }
}
