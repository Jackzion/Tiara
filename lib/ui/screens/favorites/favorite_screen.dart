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
    // 收藏列表流：数据库变更自动推送，删除后无需手动刷新
    final favoritesAsync = ref.watch(favoriteListProvider);
    // 排序方式变化自动 rebuild
    final selectedSort = ref.watch(favoriteControllerProvider);
    return SafeArea(
      child: favoritesAsync.when(
        loading: () => const NotReady(),
        error: (e, st) => Text(e.toString()),
        data: (favorites) {
          final currentFavorites =
              ref.read(favoriteControllerProvider.notifier).sortFavorites(favorites);
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
                          selectedSort: selectedSort,
                          useSliver: true,
                          onSortSelected: (sorting) {
                            ref
                                .read(favoriteControllerProvider.notifier)
                                .setSort(sorting);
                          },
                        ),
                        VerticalFavoriteList(
                          favorites: currentFavorites,
                          onAnimeTap: (animeId, heroTag) {
                            context.router.push(AnimeDetailRoute(
                              animeId: animeId,
                              heroTag: heroTag,
                            ));
                          },
                          onFavoritesTap: (DBFavorite favorite) {
                            ref
                                .read(favoriteControllerProvider.notifier)
                                .removeFavorite(favorite);
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
}
