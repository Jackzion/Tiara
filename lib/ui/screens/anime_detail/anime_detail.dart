import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/play_context.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/anime_detail_controller.dart';
import 'package:movies/state/main_nav_index.dart';
import 'package:movies/state/search_state.dart';
import 'package:movies/ui/screens/anime_detail/anime_overview.dart';
import 'package:movies/ui/screens/anime_detail/button_row.dart';
import 'package:movies/ui/screens/anime_detail/detail_banner.dart';
import 'package:movies/ui/screens/anime_detail/detail_image.dart';
import 'package:movies/ui/screens/anime_detail/trailer.dart';
import 'package:movies/ui/screens/comic_source_sheet/comic_source_sheet.dart';
import 'package:movies/ui/screens/source_sheet/source_sheet.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';
import 'package:movies/ui/widgets/horiz_cast.dart';
import 'package:movies/ui/widgets/net_error_view.dart';
import 'package:movies/ui/widgets/not_ready.dart';

/// 动漫详情页：图版横幅 + 档案条目（简介 / 章节 / 标签 / 预告 / 演职员）。
@RoutePage(name: 'AnimeDetailRoute')
class AnimeDetail extends ConsumerStatefulWidget {
  final int animeId;

  /// 来源页 Hero 标签（列表页点击处生成），配对海报 Hero 动画
  final String? heroTag;

  const AnimeDetail(this.animeId, {this.heroTag, super.key});

  @override
  ConsumerState<AnimeDetail> createState() => _AnimeDetailState();
}

class _AnimeDetailState extends ConsumerState<AnimeDetail> {
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
    final detailAsync = ref.watch(animeDetailControllerProvider(widget.animeId));
    return detailAsync.when(
      loading: () => const NotReady(),
      error: (e, st) {
        logMessage('Error: ${e.toString()}');
        return NetErrorView(
          message: '动漫详情加载失败，请检查网络后重试',
          onRetry: () =>
              ref.invalidate(animeDetailControllerProvider(widget.animeId)),
          onBack: () => ref.read(appRouterProvider).maybePop(),
        );
      },
      data: (detailState) {
        if (detailState.animeDetails == null) {
          return const NotReady();
        }
        return buildDetailScreen(detailState);
      },
    );
  }

  Widget buildDetailScreen(AnimeDetailState detailState) {
    final details = detailState.animeDetails!;
    final trailerVideos = detailState.trailerVideos;
    final characters = detailState.characters;

    return ArchivePage(
      title: details.displayTitle,
      code: 'ARCHIVE / WK-${widget.animeId.toString().padLeft(5, '0')}',
      leading: ArchiveIconButton(
        icon: Icons.arrow_back_rounded,
        label: '返回',
        onPressed: () => ref.read(appRouterProvider).maybePop(),
      ),
      actions: [
        ArchiveIconButton(
          icon: detailState.isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          label: detailState.isFavorite ? '取消收藏' : '收藏',
          filled: detailState.isFavorite,
          onPressed: () => ref
              .read(animeDetailControllerProvider(widget.animeId).notifier)
              .toggleFavorite(),
        ),
      ],
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ArchiveGeometry.wideMaxWidth,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DetailBanner(
                  details: details,
                  bannerImage: detailState.bannerImage,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  ArchiveGeometry.pagePadding,
                  0,
                  ArchiveGeometry.pagePadding,
                  64,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTitleBlock(details),
                    const SizedBox(height: 26),
                    _buildPosterAndOverview(details),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ButtonRow(
                            favoriteSelected: detailState.isFavorite,
                            onFavoriteSelected: () {
                              ref
                                  .read(
                                    animeDetailControllerProvider(
                                      widget.animeId,
                                    ).notifier,
                                  )
                                  .toggleFavorite();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (trailerVideos.isNotEmpty) ...[
                      const SizedBox(height: 36),
                      const ArchiveSection(title: '预告', code: '04 / TRAILERS'),
                      const SizedBox(height: 14),
                      Trailer(
                        videos: trailerVideos,
                        onVideoTap: (video) {
                          final playContext = PlayContext(
                            animeId: widget.animeId,
                            title: details.title ?? '',
                            detailUrl: video.videoUrl,
                            roads: [],
                            preferredEpisode: 1,
                          );
                          context.router.push(
                            VideoPageRoute(
                              animeVideo: video.youtubeId ?? '',
                              playContext: playContext,
                            ),
                          );
                        },
                      ),
                    ],
                    if (characters.isNotEmpty) ...[
                      const SizedBox(height: 36),
                      const ArchiveSection(title: '演职员', code: '05 / CAST'),
                      const SizedBox(height: 14),
                      HorizontalCast(characters: characters),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 档案条目头：大标题 + 一行等宽元信息 + 评分章
  Widget _buildTitleBlock(AnimeDetails details) {
    final tone = ArchiveTone.of(context);
    final meta = <String>[
      'WK-${widget.animeId.toString().padLeft(5, '0')}',
      if (details.year != null) '${details.year}',
      if (details.type != null && details.type!.isNotEmpty) details.type!,
      if (details.rank != null) 'RANK #${details.rank}',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArchiveType.display.copyWith(color: tone.ink),
              ),
              const SizedBox(height: 7),
              ArchiveCode(meta.join('  ·  ')),
            ],
          ),
        ),
        if (details.score != null) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tone.ink,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 12, color: tone.surface),
                const SizedBox(width: 5),
                Text(
                  details.score!.toStringAsFixed(1),
                  style: ArchiveType.code.copyWith(
                    fontSize: 11,
                    color: tone.surface,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 左海报+元信息 / 右简介等档案段落；780 以下纵向堆叠
  Widget _buildPosterAndOverview(AnimeDetails details) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 780;

    final posterAndMeta = _buildPosterColumn(details, isWide: isWide);
    final overview = AnimeOverview(
      details: details,
      onEpisodeTap: (ep) => _openSourceSheet(details, preferredEpisode: ep),
      onWatchTap: () => details.isBook
          ? _openComicSourceSheet(details)
          : _openSourceSheet(details, preferredEpisode: null),
      onTagTap: (genre) {
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(currentNavIndexProvider.notifier).goTo(1);
        container.read(searchStateProvider.notifier).addTag(genre.name);
        context.router.pop();
      },
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: posterAndMeta),
          const SizedBox(height: 24),
          overview,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 260, child: posterAndMeta),
        const SizedBox(width: 36),
        Expanded(child: overview),
      ],
    );
  }

  Widget _buildPosterColumn(AnimeDetails details, {required bool isWide}) {
    final posterWidth = isWide ? 260.0 : 200.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: posterWidth,
          child: DetailImage(
            details: details,
            width: posterWidth,
            heroTag: widget.heroTag,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: isWide ? 260 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaLine(label: '中文名', value: details.displayTitle),
              if (details.episodes != null) ...[
                const SizedBox(height: 8),
                _MetaLine(
                  label: details.chapterCountLabel!,
                  value: '${details.chapterCount!}',
                ),
              ],
              if (details.members != null) ...[
                const SizedBox(height: 8),
                _MetaLine(
                  label: '收藏数',
                  value: _compactNumber(details.members!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _compactNumber(int value) => value >= 10000
      ? '${(value / 10000).toStringAsFixed(1)} 万'
      : '$value';

  /// 打开视频源选择器
  Future<void> _openSourceSheet(
    AnimeDetails details, {
    int? preferredEpisode,
  }) async {
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
      return;
    }
    final playContext = await showSourceSheet(
      context,
      keyword: keyword,
      animeId: details.bangumiId,
      animeTitle: details.title ?? keyword,
      preferredEpisode: preferredEpisode,
    );

    if (playContext == null || !mounted) return;

    debugPrint('[Phase4] PlayContext => $playContext');
    context.router.push(
      VideoPageRoute(animeVideo: '', playContext: playContext),
    );
  }

  /// 打开选图源面板（书籍）
  Future<void> _openComicSourceSheet(AnimeDetails details) async {
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
      return;
    }
    final selection = await showComicSourceSheet(
      context,
      keyword: keyword,
      animeId: details.bangumiId,
      animeTitle: details.title ?? keyword,
    );
    if (selection == null || !mounted) return;
    context.router.push(
      ComicReaderRoute(
        sourceKey: selection.sourceKey,
        comicId: selection.comicId,
        epId: selection.epId,
        title: selection.title,
        epTitle: selection.epTitle,
      ),
    );
  }
}

/// 元信息行：等宽标签 + 墨色值。
class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: ArchiveType.code.copyWith(color: tone.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: ArchiveType.body.copyWith(
              fontSize: 13,
              color: tone.ink,
            ),
          ),
        ),
      ],
    );
  }
}
