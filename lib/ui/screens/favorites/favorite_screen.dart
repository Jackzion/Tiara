import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/library/library_codec.dart';
import 'package:movies/data/models/play_context.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/favorite_controller.dart';
import 'package:movies/ui/screens/genres/sort_picker.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';
import 'package:movies/ui/widgets/not_ready.dart';
import 'package:movies/ui/widgets/vert_favorite_list.dart';

/// 收藏夹：继续观看 + 收藏列表。
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
      error: (e, st) => ArchiveLoadError(message: e.toString()),
      loading: () => const NotReady(),
      data: (_) => buildScreen(),
    );
  }

  Widget buildScreen() {
    final tone = ArchiveTone.of(context);
    final favoritesAsync = ref.watch(favoriteListProvider);
    final recentAsync = ref.watch(recentPlaysProvider);
    final selectedSort = ref.watch(favoriteControllerProvider);

    return Scaffold(
      backgroundColor: tone.pageEnd,
      body: Atmosphere(
        child: Stack(
          children: [
            Positioned.fill(
              child: favoritesAsync.when(
                loading: () => const NotReady(),
                error: (e, st) => ArchiveLoadError(message: e.toString()),
                data: (favorites) {
                  final currentFavorites = ref
                      .read(favoriteControllerProvider.notifier)
                      .sortFavorites(favorites);
                  final recent = recentAsync.value ?? const [];

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (recent.isNotEmpty) ...[
                                    ArchiveSection(
                                      title: '继续观看',
                                      code: '00 / CONTINUE',
                                      subtitle: '上次看到的位置，点一下直接进入',
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 158,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: recent.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) =>
                                            _ResumeCard(
                                              resume: recent[index],
                                              onTap: () => _openResume(
                                                recent[index],
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                  ],
                                  ArchiveSection(
                                    title: '我的收藏',
                                    code: '01 / FAVORITES',
                                    subtitle:
                                        '${currentFavorites.length} 条记录 · '
                                        '按 ${selectedSort.name} 排序',
                                  ),
                                  const SizedBox(height: 10),
                                  SortPicker(
                                    selectedSort: selectedSort,
                                    useSliver: false,
                                    onSortSelected: (sorting) {
                                      ref
                                          .read(
                                            favoriteControllerProvider
                                                .notifier,
                                          )
                                          .setSort(sorting);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              ArchiveGeometry.pagePadding,
                              10,
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

  /// 直接进入：漫画走阅读器，动画用存下来的规则+线路重建 PlayContext
  void _openResume(LibraryResume resume) {
    if (resume.isComic) {
      final sourceKey = resume.sourceKey;
      final comicId = resume.remoteId;
      final epId = resume.lastUnitId;
      if (sourceKey == null || comicId == null || epId == null) return;
      context.router.push(
        ComicReaderRoute(
          sourceKey: sourceKey,
          comicId: comicId,
          epId: epId,
          title: resume.title,
          epTitle: resume.lastUnitTitle ?? '',
        ),
      );
      return;
    }

    final rule = decodeRule(resume.ruleJson);
    final roads = decodeRoads(resume.roadsJson);
    if (rule == null || roads.isEmpty) {
      // 上下文不完整（旧数据 / 规则已删）：退回详情页重新选源
      if (resume.bangumiId != null) {
        context.router.push(AnimeDetailRoute(animeId: resume.bangumiId!));
      }
      return;
    }
    context.router.push(
      VideoPageRoute(
        animeVideo: '',
        playContext: PlayContext(
          animeId: resume.bangumiId ?? 0,
          title: resume.title,
          detailUrl: resume.detailUrl ?? '',
          roads: roads,
          rule: rule,
          preferredEpisode: resume.lastEpisode,
          preferredRoadIndex: resume.lastRoadIndex,
        ),
        animeDetail: null
      ),
    );
  }
}

/// 继续观看卡片：海报 + 标题 + 「第 N 集 / 话名」
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.resume, required this.onTap});

  final LibraryResume resume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return SizedBox(
      width: 104,
      child: PressableScale(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 104,
              height: 118,
              decoration: BoxDecoration(
                color: tone.raised,
                borderRadius: BorderRadius.circular(
                  ArchiveGeometry.coverRadius,
                ),
                border: Border.all(
                  color: tone.hairline,
                  width: ArchiveGeometry.hairlineWidth,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: (resume.posterUrl ?? '').isEmpty
                  ? Icon(Icons.movie_filter_outlined, color: tone.muted, size: 22)
                  : Image.network(
                      resume.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: tone.muted,
                        size: 22,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              resume.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArchiveType.micro.copyWith(
                color: tone.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              resume.progressLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArchiveType.code.copyWith(color: tone.muted),
            ),
          ],
        ),
      ),
    );
  }
}
