import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/genre_controller.dart';
import 'package:movies/state/search_state.dart';
import 'package:movies/ui/screens/genres/genre_search_row.dart';
import 'package:movies/ui/screens/genres/genre_section.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';
import 'package:movies/ui/widgets/not_ready.dart';
import 'package:movies/ui/widgets/vert_anime_list.dart';
import 'package:movies/utils/utils.dart';

/// 类型页面
/// 布局：顶部搜索 + 筛选栏（排序 / 视图切换），下方左侧作品列表 + 右侧筛选面板
@RoutePage(name: 'GenreRoute')
class GenreScreen extends ConsumerStatefulWidget {
  const GenreScreen({super.key});

  @override
  ConsumerState<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends ConsumerState<GenreScreen> {
  /// 已调度的跨页请求序号（避免重复 postFrame）
  int _lastRequestSeq = 0;

  /// 列表展示模式
  AnimeViewMode _viewMode = AnimeViewMode.detail;

  @override
  Widget build(BuildContext context) {
    // 数据层就绪（标签预热完成）后才渲染
    final dataReadyAsync = ref.watch(dataReadyProvider);
    return dataReadyAsync.when(
      error: (e, st) => ArchiveLoadError(message: e.toString()),
      loading: () => const NotReady(),
      data: (_) {
        // 分类页状态（chip 选中 + 搜索结果），controller 状态变化自动 rebuild
        final genreAsync = ref.watch(genreControllerProvider);
        return genreAsync.when(
          error: (e, st) => ArchiveLoadError(message: e.toString()),
          loading: () => const NotReady(),
          data: buildScreen,
        );
      },
    );
  }

  Widget buildScreen(GenrePageState pageState) {
    // 跨页搜索请求（全局搜索 / SearchDialog / 详情页点标签）：
    // 只登记序号，postFrame 消费，build 期不写任何状态
    final request = ref.watch(searchStateProvider);
    if (request.seq != 0 && request.seq != _lastRequestSeq) {
      _lastRequestSeq = request.seq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishSearch(
          // buildRequest -> controller -> ui rebuild
          ref.read(genreControllerProvider.notifier).applyRequest(request),
        );
      });
    }
    return SafeArea(child: _genreBody(context, pageState));
  }

  /// 等搜索完成（controller 内部更新 state 后 UI 自动重建）
  Future<void> _finishSearch(Future<bool> search) async {
    await search;
  }

  Widget _genreBody(BuildContext context, GenrePageState pageState) {
    final tone = ArchiveTone.of(context);
    final animes = _sortedForView(
      pageState.currentAnimeList,
      pageState.selectedSort,
    );
    return Atmosphere(
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: archivePagePadding(context),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GenreSearchRow(pageState.keyword, (searchString) {
                        _finishSearch(
                          ref
                              .read(genreControllerProvider.notifier)
                              .searchByKeyword(searchString),
                        );
                        FocusScope.of(context).unfocus();
                      }),
                      addVerticalSpace(14),
                      _buildFilterBar(pageState),
                      addVerticalSpace(16),
                      // 结果计数 + 发丝线，代替原来的空白隔断
                      Row(
                        children: [
                          ArchiveCode(
                            '${animes.length.toString().padLeft(3, '0')} ENTRIES',
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: ArchiveGeometry.dividerWidth,
                              color: tone.hairline,
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: 3,
                            height: 3,
                            child: ColoredBox(color: tone.ink),
                          ),
                        ],
                      ),
                      addVerticalSpace(12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildResults(pageState, animes)),
                            addHorizontalSpace(20),
                            SizedBox(
                              width: 242,
                              child: GenreSection(
                                genreStates: pageState.genreStates,
                                externalTags: pageState.externalTags,
                                typeFilter: pageState.typeFilter,
                                onTypeSelected: (filter) {
                                  _finishSearch(
                                    ref
                                        .read(genreControllerProvider.notifier)
                                        .setTypeFilter(filter),
                                  );
                                },
                                onGenresSelected: (fullList) {
                                  // 保持全量列表，只同步选中状态（内部会持久化并重搜）
                                  _finishSearch(
                                    ref
                                        .read(genreControllerProvider.notifier)
                                        .updateSelections(fullList),
                                  );
                                },
                                onRemoveExternalTag: (tag) {
                                  _finishSearch(
                                    ref
                                        .read(genreControllerProvider.notifier)
                                        .removeExternalTag(tag),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        thickness: ArchiveGeometry.dividerWidth,
                        color: tone.hairline,
                      ),
                      const SizedBox(height: 8),
                      ArchivePager(
                        page: pageState.offset,
                        totalPages: 10,
                        onPageChanged: (int offset){
                          ref
                              .read(genreControllerProvider.notifier)
                              .setOffset(offset);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FrostedHeader(
              child: ArchiveMasthead(
                title: '类型索引',
                code: 'MOVIES / GENRE INDEX',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部筛选栏：左侧排序 pill，右侧视图切换
  Widget _buildFilterBar(GenrePageState pageState) {
    return Row(
      children: [
        Text('按', style: roboto.copyWith(fontSize: 13, color: textMuted)),
        addHorizontalSpace(8),
        for (final sort in Sorting.values) ...[
          _sortPill(
            label: _sortLabel(sort),
            active: pageState.selectedSort == sort,
            onTap: () =>
                ref.read(genreControllerProvider.notifier).setSort(sort),
          ),
        ],
        const Spacer(),
        for (final mode in const [
          AnimeViewMode.list,
          AnimeViewMode.detail,
          AnimeViewMode.grid,
        ]) ...[_viewButton(mode), addHorizontalSpace(3)],
      ],
    );
  }

  String _sortLabel(Sorting sort) {
    switch (sort) {
      case Sorting.aToz:
        return '名称';
      case Sorting.zToa:
        return '倒序';
      case Sorting.rating:
        return '评分';
      case Sorting.year:
        return '年份';
    }
  }

  Widget _sortPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final tone = ArchiveTone.of(context);
    return Material(
      color: active ? tone.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
        hoverColor: tone.raisedHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(
            label,
            style: ArchiveType.body.copyWith(
              fontSize: 12,
              height: 1,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? tone.surface : tone.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewButton(AnimeViewMode mode) {
    final tone = ArchiveTone.of(context);
    final active = _viewMode == mode;
    return Material(
      color: active ? tone.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
        hoverColor: tone.raisedHigh,
        child: SizedBox(
          width: 32,
          height: 20,
          child: Center(
            child: _viewIcon(mode, active ? tone.surface : tone.muted),
          ),
        ),
      ),
    );
  }

  /// 三个视图模式的迷你图标（固定 16×12 图标盒，同 mockup）
  Widget _viewIcon(AnimeViewMode mode, Color color) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
    const gapV = 2.5;
    switch (mode) {
      case AnimeViewMode.list:
        return SizedBox(
          width: 16,
          height: 11,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [bar(16, 2), bar(16, 2), bar(16, 2)],
          ),
        );
      case AnimeViewMode.detail:
        return SizedBox(
          width: 17,
          height: 12,
          child: Row(
            children: [
              bar(5, 12),
              addHorizontalSpace(2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [bar(10, 2), bar(10, 2), bar(7, 2)],
                ),
              ),
            ],
          ),
        );
      case AnimeViewMode.grid:
        return SizedBox(
          width: 15,
          height: 11,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [bar(6, 4.5), addHorizontalSpace(gapV), bar(6, 4.5)],
              ),
              Row(
                children: [bar(6, 4.5), addHorizontalSpace(gapV), bar(6, 4.5)],
              ),
            ],
          ),
        );
    }
  }

  /// 左侧结果区
  Widget _buildResults(GenrePageState pageState, List<Anime> animes) {
    if (animes.isEmpty) {
      final filtered =
          pageState.keyword.trim().isNotEmpty ||
          pageState.genreStates.any((state) => state.isSelected) ||
          pageState.externalTags.isNotEmpty;
      return Center(
        child: Text(
          filtered ? '没有找到匹配的作品' : '选择标签或输入关键词开始搜索',
          style: ArchiveType.body.copyWith(
            fontSize: 13,
            color: ArchiveTone.of(context).muted,
          ),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        VerticalAnimeList(
          animes: animes,
          onAnimeTap: (animeId, heroTag) {
            context.router.push(
              AnimeDetailRoute(animeId: animeId, heroTag: heroTag),
            );
          },
          viewMode: _viewMode,
        ),
      ],
    );
  }

  /// 展示排序：按当前排序方式整理结果（A-Z / Z-A / 评分 / 年份）
  List<Anime> _sortedForView(List<Anime> animes, Sorting sort) {
    final copy = List<Anime>.of(animes);
    switch (sort) {
      case Sorting.aToz:
        copy.sort(
          (a, b) => (a.title ?? '').toLowerCase().compareTo(
            (b.title ?? '').toLowerCase(),
          ),
        );
      case Sorting.zToa:
        copy.sort(
          (a, b) => (b.title ?? '').toLowerCase().compareTo(
            (a.title ?? '').toLowerCase(),
          ),
        );
      case Sorting.rating:
        copy.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
      case Sorting.year:
        copy.sort(
          (a, b) => (b.aired?.year ?? -1).compareTo(a.aired?.year ?? -1),
        );
    }
    return copy;
  }
}
