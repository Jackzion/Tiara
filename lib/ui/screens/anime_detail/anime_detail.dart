import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/library/library_codec.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/novel_source.dart';
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
import 'package:movies/ui/screens/novel_source_sheet/novel_source_sheet.dart';
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
      error: (e, st) => ArchiveLoadError(message: e.toString()),
      loading: () => NotReady(animeId: widget.animeId.toString()),
      data: (_) => buildScreen(),
    );
  }

  Widget buildScreen() {
    final detailAsync = ref.watch(
      animeDetailControllerProvider(widget.animeId),
    );
    return detailAsync.when(
      loading: () => NotReady(animeId: widget.animeId.toString()),
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
          return NotReady(animeId: widget.animeId.toString());
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
          icon: detailState.isFavorite ? Icons.favorite : Icons.favorite_border,
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
                    if (detailState.refreshFailed) ...[
                      const SizedBox(height: 10),
                      // SWR：刷新失败但旧数据可用 —— 只提示，不打断
                      Row(
                        children: [
                          Expanded(
                            child: ArchiveCode(
                              'STALE / 更新失败 · 显示 ${_staleLabel(detailState.fetchedAt)}',
                              color: ArchivePalette.warning,
                            ),
                          ),
                          ArchiveTextButton(
                            onPressed: detailState.refreshing
                                ? null
                                : () => ref
                                      .read(
                                        animeDetailControllerProvider(
                                          widget.animeId,
                                        ).notifier,
                                      )
                                      .refresh(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ],
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
                              animeDetail: detailState.animeDetails,
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
          ArchiveCode('${details.score}', fontSize: 33),
        ],
      ],
    );
  }

  /// 左海报+元信息 / 右简介等档案段落；780 以下纵向堆叠
  Widget _buildPosterAndOverview(AnimeDetails details) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 780;

    // 本地书库里是否有「上次看到哪」；没有就一切照旧
    final resume = ref.watch(animeResumeProvider(widget.animeId)).value;

    final posterAndMeta = _buildPosterColumn(
      details,
      isWide: isWide,
      stretch: false,
    );
    final overview = AnimeOverview(
      details: details,
      // 宽屏两栏：标签贴到栏底，与左栏元信息共底
      fillHeight: isWide,
      resume: resume,
      onResume: resume == null ? null : () => _resumePlay(resume, details),
      onEpisodeTap: (ep) => _openSourceSheet(details, preferredEpisode: ep),
      onComicEpisodeTap: resume == null
          ? null
          : (ep) => _openComicEpisode(resume, details, ep),
      onNovelChapterTap: resume == null
          ? null
          : (chapter) => _openNovelChapter(resume, details, chapter),
      onWatchTap: () => details.isBook
          ? _openBookEntryChooser(details)
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

    // 两栏自然高度、顶对齐（不强行等高）：IntrinsicHeight 对「Expanded +
    // 折行文本」询问内在尺寸时宽度与实际布局不一致，会持续溢出。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 260, child: posterAndMeta),
        const SizedBox(width: 36),
        Expanded(child: overview),
      ],
    );
  }

  Widget _buildPosterColumn(
    AnimeDetails details, {
    required bool isWide,
    bool stretch = false,
  }) {
    final posterWidth = isWide ? 260.0 : 200.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      children: [
        SizedBox(
          width: posterWidth,
          child: DetailImage(
            details: details,
            width: posterWidth,
            heroTag: widget.heroTag,
          ),
        ),
        // 撑满栏高时把元信息推到底部，与右栏标签共底
        if (stretch) const Spacer() else const SizedBox(height: 16),
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

  static String _compactNumber(int value) =>
      value >= 10000 ? '${(value / 10000).toStringAsFixed(1)} 万' : '$value';

  /// 「显示的是哪天的存档」：MM-dd HH:mm
  static String _staleLabel(DateTime? fetchedAt) {
    if (fetchedAt == null) return '本地存档';
    final local = fetchedAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  /// 续看/续读：有存下来的上下文就直接进播放器/阅读器，否则退回选源
  Future<void> _resumePlay(LibraryResume resume, AnimeDetails details) async {
    // 小说（uid 前缀 novel:）进 NovelReader；漫画进 ComicReader
    if (resume.isNovel) {
      final sourceKey = resume.sourceKey;
      final bookId = resume.remoteId;
      final chapterId = resume.lastUnitId;
      if (sourceKey == null || bookId == null || chapterId == null) return;
      await context.router.push(
        NovelReaderRoute(
          sourceKey: sourceKey,
          bookId: bookId,
          chapterId: chapterId,
          title: resume.title,
          chapterTitle: resume.lastUnitTitle ?? '',
          animeDetail: details,
        ),
      );
      ref.invalidate(animeResumeProvider(widget.animeId));
      return;
    }

    if (resume.isComic) {
      final sourceKey = resume.sourceKey;
      final comicId = resume.remoteId;
      final epId = resume.lastUnitId;
      if (sourceKey == null || comicId == null || epId == null) return;
      await context.router.push(
        ComicReaderRoute(
          sourceKey: sourceKey,
          comicId: comicId,
          epId: epId,
          title: resume.title,
          epTitle: resume.lastUnitTitle ?? '',
        ),
      );
      ref.invalidate(animeResumeProvider(widget.animeId));
      return;
    }

    final rule = decodeRule(resume.ruleJson);
    final roads = decodeRoads(resume.roadsJson);
    if (rule == null || roads.isEmpty) {
      // 上下文不完整（旧数据 / 规则被删）：重新选源，但把上次的集号带上
      await _openSourceSheet(details, preferredEpisode: resume.lastEpisode);
      return;
    }
    await context.router.push(
      VideoPageRoute(
        animeVideo: '',
        playContext: PlayContext(
          animeId: resume.bangumiId ?? widget.animeId,
          title: resume.title,
          detailUrl: resume.detailUrl ?? '',
          roads: roads,
          rule: rule,
          preferredEpisode: resume.lastEpisode,
          preferredRoadIndex: resume.lastRoadIndex,
        ),
        animeDetail: details,
      ),
    );
    ref.invalidate(animeResumeProvider(widget.animeId));
  }

  /// 打开视频源选择器
  /// 漫画章节直跳：resume 当前线路的第 [episode] 话（1-based）直接进阅读器
  Future<void> _openComicEpisode(
    LibraryResume resume,
    AnimeDetails details,
    int episode,
  ) async {
    final roads = decodeRoads(resume.roadsJson);
    if (roads.isEmpty || resume.sourceKey == null || resume.remoteId == null) {
      return;
    }
    final road = roads[resume.lastRoadIndex.clamp(0, roads.length - 1)];
    final i = episode - 1;
    if (i < 0 || i >= road.data.length) return;
    await context.router.push(
      ComicReaderRoute(
        sourceKey: resume.sourceKey!,
        comicId: resume.remoteId!,
        epId: road.data[i],
        title: resume.title,
        epTitle: i < road.identifier.length && road.identifier[i].isNotEmpty
            ? road.identifier[i]
            : '第 $episode 话',
        animeDetail: details,
      ),
    );
    ref.invalidate(animeResumeProvider(widget.animeId));
  }

  /// 小说章节直跳：novel source 目录里的章直接进阅读器
  Future<void> _openNovelChapter(
    LibraryResume resume,
    AnimeDetails details,
    NovelChapter chapter,
  ) async {
    if (resume.sourceKey == null || resume.remoteId == null) return;
    await context.router.push(
      NovelReaderRoute(
        sourceKey: resume.sourceKey!,
        bookId: resume.remoteId!,
        chapterId: chapter.chapterId,
        title: resume.title,
        chapterTitle: chapter.title,
        animeDetail: details,
      ),
    );
    ref.invalidate(animeResumeProvider(widget.animeId));
  }

  Future<void> _openSourceSheet(
    AnimeDetails details, {
    int? preferredEpisode,
  }) async {
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
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
      VideoPageRoute(
        animeVideo: '',
        playContext: playContext,
        animeDetail: details,
      ),
    );
  }

  /// 打开选图源面板（书籍）
  Future<void> _openComicSourceSheet(AnimeDetails details) async {
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
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
        animeDetail: details
      ),
    );
  }

  /// 书籍入口分流：漫画还是小说（BGM 书籍条目两者皆有可能）
  Future<void> _openBookEntryChooser(AnimeDetails details) async {
    final isNovel = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ArchivePalette.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('漫画'),
              subtitle: const Text('图源规则搜索'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('小说'),
              subtitle: const Text('轻小说文库搜索'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (isNovel == null || !mounted) return;
    if (isNovel) {
      await _openNovelSourceSheet(details);
    } else {
      await _openComicSourceSheet(details);
    }
  }

  /// 打开选书面板（小说）
  Future<void> _openNovelSourceSheet(AnimeDetails details) async {
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
      return;
    }
    final selection = await showNovelSourceSheet(
      context,
      keyword: keyword,
      animeId: details.bangumiId,
      animeTitle: details.title ?? keyword,
    );
    if (selection == null || !mounted) return;
    context.router.push(
      NovelReaderRoute(
        sourceKey: selection.sourceKey,
        bookId: selection.bookId,
        chapterId: selection.chapterId,
        title: selection.title,
        chapterTitle: selection.chapterTitle,
        animeDetail: details,
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
            style: ArchiveType.body.copyWith(fontSize: 13, color: tone.ink),
          ),
        ),
      ],
    );
  }
}
