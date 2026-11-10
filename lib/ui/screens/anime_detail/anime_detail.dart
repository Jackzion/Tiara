import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:movies/ui/widgets/horiz_cast.dart';
import 'package:movies/ui/widgets/not_ready.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/ui/theme/theme.dart';

/// 动漫详情页面
/// 顶部 bannerImage 渐进色背景；下方左完整 detail.image 海报+元信息，右章节/简介/标签
@RoutePage(name: 'AnimeDetailRoute')
class AnimeDetail extends ConsumerStatefulWidget {
  final int animeId;

  /// 来源页 Hero 标签（列表页点击处生成），配对海报 Hero 动画
  /// autoRouter 会自动生成 heroTag 参数
  final String? heroTag;

  const AnimeDetail(this.animeId, {this.heroTag, super.key});

  @override
  ConsumerState<AnimeDetail> createState() => _AnimeDetailState();
}

class _AnimeDetailState extends ConsumerState<AnimeDetail> {
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
    // 详情数据（family: animeId），controller 状态变化自动 rebuild
    final detailAsync = ref.watch(
      animeDetailControllerProvider(widget.animeId),
    );
    return detailAsync.when(
      loading: () => const NotReady(),
      error: (e, st) {
        logMessage('Error: ${e.toString()}');
        return Text(e.toString());
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

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: searchBarBackground,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              ref.read(appRouterProvider).maybePop();
            },
          ),
          centerTitle: false,
          title: Text(
            'Back',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        body: Container(
          color: searchBarBackground,
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  // 顶部渐进色背景：图源 bannerImage（animeId 对应 AniList）
                  DetailBanner(
                    details: details,
                    bannerImage: detailState.bannerImage,
                  ),
                  // 左完整 detail.image + 元信息；右章节/简介/标签
                  _buildPosterAndOverview(details),
                  ButtonRow(
                    favoriteSelected: detailState.isFavorite,
                    onFavoriteSelected: () {
                      ref
                          .read(
                            animeDetailControllerProvider(widget.animeId)
                                .notifier,
                          )
                          .toggleFavorite();
                    },
                  ),
                  if (trailerVideos.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        'Trailers',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
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
                        // 预告片：rule 为空 → VideoPage 走 youtube_explode 取流
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
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        bottom: 16,
                        top: 16,
                      ),
                      child: Text(
                        'Characters',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    HorizontalCast(characters: characters),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 左海报+元信息 / 右简介面板
  /// 宽屏左右分栏；窄屏纵向堆叠，海报仍展示完整封面
  Widget _buildPosterAndOverview(AnimeDetails details) {
    final width = MediaQuery.of(context).size.width;
    // 参考 CSS 在 780px 以下改为纵向
    final isWide = width >= 780;

    final posterAndMeta = _buildPosterColumn(details, isWide: isWide);
    final overview = AnimeOverview(
      details: details,
      // 子组件函数外抛，能让父组件直接调用子组件交互参数典例
      // 点章节:(1-based 集号) 回调
      onEpisodeTap: (ep) => _openSourceSheet(details, preferredEpisode: ep),
      // 点观看:(不带集号) 回调
      onWatchTap: () => details.isBook
          ? _openComicSourceSheet(details)
          : _openSourceSheet(details, preferredEpisode: null),
      // 点标签:(标签名称) 回调
      onTagTap: (genre) {
        // 切换到 Genre Tab 并发起标签搜索（SearchState 请求，Genre 页消费）
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(currentNavIndexProvider.notifier).goTo(1);
        container.read(searchStateProvider.notifier).addTag(genre.name);
        // route to genres screen
        context.router.pop();
      },
    );

    if (!isWide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: posterAndMeta),
            addVerticalSpace(20),
            overview,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 40, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== LEFT : 完整 detail.image 海报 + 元信息 =====
          SizedBox(width: 240, child: posterAndMeta),
          addHorizontalSpace(28),
          // ===== RIGHT : 章节 / 简介 / 标签 =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: overview,
            ),
          ),
        ],
      ),
    );
  }

  /// 左侧列：完整 detail.image 海报 + 中文名 / 话数
  Widget _buildPosterColumn(AnimeDetails details, {required bool isWide}) {
    final posterWidth = isWide ? 240.0 : 200.0;

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
        addVerticalSpace(16),
        SizedBox(
          width: isWide ? 240 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaLine(label: '中文名', value: details.displayTitle),
              if (details.episodes != null) ...[
                addVerticalSpace(8),
                _MetaLine(
                  label: details.chapterCountLabel!,
                  value: '${details.chapterCount!}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 打开视频源选择器
  Future<void> _openSourceSheet(
    AnimeDetails details, {
    int? preferredEpisode,
  }) async {
    // 关键词：优先中文标题，无则日文
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    // 缺少可用的搜索关键词
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
      return;
    }
    // 打开视频源选择器 - showSourceSheet
    final playContext = await showSourceSheet(
      context,
      keyword: keyword,
      animeId: details.bangumiId,
      animeTitle: details.title ?? keyword,
      preferredEpisode: preferredEpisode,
    );

    if (playContext == null || !mounted) return; // 用户取消

    // Phase 4：先打印；Phase 5 换成完整播放
    debugPrint('[Phase4] PlayContext => $playContext');

    // 拿到 playContext 后，跳转到视频播放页面
    // 参数由 page auto route 自动解析 ， dart run build_runner build --delete-conflicting-outputs
    context.router.push(
      VideoPageRoute(animeVideo: '', playContext: playContext),
    );
  }

  /// 打开选图源面板（书籍）
  Future<void> _openComicSourceSheet(AnimeDetails details) async {
    // 关键词：优先中文标题，无则日文
    final keyword = (details.title?.isNotEmpty ?? false)
        ? details.title!
        : (details.titleJapanese ?? '');
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少可用的搜索关键词')));
      return;
    }
    // 打开选图源面板 - showComicSourceSheet
    final selection = await showComicSourceSheet(
      context,
      keyword: keyword,
      animeId: details.bangumiId,
      animeTitle: details.title ?? keyword,
    );
    if (selection == null || !mounted) return; // 用户取消
    // context.router.push(ComicReaderRoute(...selection));
    debugPrint('ComicSelection => $selection');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已选：${selection.title} · ${selection.epTitle}')),
    );
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

/// 元信息行（海报下方）
class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansSc(
            fontSize: 14,
            height: 1.9,
            color: posterBorder,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSansSc(
              fontSize: 14,
              height: 1.9,
              color: posterBorder,
            ),
          ),
        ),
      ],
    );
  }
}
