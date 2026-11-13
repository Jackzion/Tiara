import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/favorite_controller.dart';
import 'package:movies/ui/screens/genres/sort_picker.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';
import 'package:movies/ui/widgets/not_ready.dart';
import 'package:movies/ui/widgets/vert_favorite_list.dart';

/// 收藏夹：档案化列表 + 排序。
@RoutePage(name: 'FavoriteRoute')
class FavoriteScreen extends ConsumerStatefulWidget {
  const FavoriteScreen({super.key});

  @override
  ConsumerState<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends ConsumerState<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    final dataReadyAsync = ref.watch(dataReadyProvider);
    return dataReadyAsync.when(
      error: (e, st) => Text(e.toString()),
      loading: () => const NotReady(),
      data: (_) => buildScreen(),
    );
  }

  Widget buildScreen() {
    final tone = ArchiveTone.of(context);
    final favoritesAsync = ref.watch(favoriteListProvider);
    final selectedSort = ref.watch(favoriteControllerProvider);

    return Scaffold(
      backgroundColor: tone.pageEnd,
      body: Atmosphere(
        child: Stack(
          children: [
            Positioned.fill(
              child: favoritesAsync.when(
                loading: () => const NotReady(),
                error: (e, st) => Text(e.toString()),
                data: (favorites) {
                  final currentFavorites = ref
                      .read(favoriteControllerProvider.notifier)
                      .sortFavorites(favorites);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: archivePagePadding(
                              context,
                            ).copyWith(bottom: 0),
                            sliver: SliverToBoxAdapter(
                              child: ArchiveSection(
                                title: '我的收藏',
                                code: '01 / FAVORITES',
                                subtitle:
                                    '${currentFavorites.length} 条记录 · '
                                    '按 ${selectedSort.name} 排序',
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              ArchiveGeometry.pagePadding,
                              10,
                              ArchiveGeometry.pagePadding,
                              8,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: SortPicker(
                                selectedSort: selectedSort,
                                useSliver: false,
                                onSortSelected: (sorting) {
                                  ref
                                      .read(
                                        favoriteControllerProvider.notifier,
                                      )
                                      .setSort(sorting);
                                },
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              ArchiveGeometry.pagePadding,
                              4,
                              ArchiveGeometry.pagePadding,
                              48,
                            ),
                            sliver: VerticalFavoriteList(
                              favorites: currentFavorites,
                              onAnimeTap: (animeId, heroTag) {
                                context.router.push(
                                  AnimeDetailRoute(
                                    animeId: animeId,
                                    heroTag: heroTag,
                                  ),
                                );
                              },
                              onFavoritesTap: (DBFavorite favorite) {
                                ref
                                    .read(favoriteControllerProvider.notifier)
                                    .removeFavorite(favorite);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FrostedHeader(
                child: ArchiveMasthead(
                  title: '收藏夹',
                  code: 'MOVIES / FAVOURITES',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
