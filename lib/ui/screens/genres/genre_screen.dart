import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/genre_controller.dart';
import 'package:movies/state/search_state.dart';
import 'package:movies/ui/screens/genres/sort_picker.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/screens/genres/genre_search_row.dart';
import 'package:movies/ui/screens/genres/genre_section.dart';
import 'package:movies/ui/widgets/sliver_divider.dart';
import 'package:movies/ui/widgets/vert_anime_list.dart';
import 'package:movies/ui/widgets/not_ready.dart';

/// 类型页面
/// 展示动漫类型列表和对应类型的动漫
/// 支持搜索和类型筛选
@RoutePage(name: 'GenreRoute')
class GenreScreen extends ConsumerStatefulWidget {
  const GenreScreen({super.key});

  @override
  ConsumerState<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends ConsumerState<GenreScreen> {
  /// 已调度的跨页请求序号（避免重复 postFrame）
  int _lastRequestSeq = 0;

  @override
  Widget build(BuildContext context) {
    // 数据层就绪（标签预热完成）后才渲染
    final dataReadyAsync = ref.watch(dataReadyProvider);
    return dataReadyAsync.when(
      error: (e, st) => Text(e.toString()),
      loading: () => const NotReady(),
      data: (_) {
        // 分类页状态（chip 选中 + 搜索结果），controller 状态变化自动 rebuild
        final genreAsync = ref.watch(genreControllerProvider);
        return genreAsync.when(
          error: (e, st) => Text(e.toString()),
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

  /// 等搜索完成后展开 chip 区（requested=false 表示未发起请求）
  Future<void> _finishSearch(Future<bool> search) async {
    final requested = await search;
    if (!requested || !mounted) {
      return;
    }
    expandedNotifier.value = true;
  }

  Widget _genreBody(BuildContext context, GenrePageState pageState) {
    return Container(
      color: screenBackground,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16.0, 0.0, 24.0),
                      child: Text(
                        'Find an Anime',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    GenreSearchRow(pageState.keyword, (searchString) {
                      _finishSearch(
                        ref
                            .read(genreControllerProvider.notifier)
                            .searchByKeyword(searchString),
                      );
                      FocusScope.of(context).unfocus();
                    }),
                    SegmentedButton<SubjectTypeFilter>(
                      segments: [
                        for (final f
                            in SubjectTypeFilter.values) // ALL / Book / Anime
                          ButtonSegment(value: f, label: Text(f.label)),
                      ],
                      selected: {pageState.typeFilter},
                      onSelectionChanged: (sel) {
                        _finishSearch(
                          ref
                              .read(genreControllerProvider.notifier)
                              .setTypeFilter(sel.first),
                        );
                      },
                    ),
                  ]),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: expandedNotifier,
                  builder: (BuildContext context, bool value, Widget? child) {
                    return GenreSection(
                      genreStates: pageState.genreStates,
                      externalTags: pageState.externalTags,
                      isExpanded: value,
                      onGenresExpanded: (expanded) {
                        expandedNotifier.value = expanded;
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
                    );
                  },
                ),
                const SliverDivider(),
                SortPicker(
                  selectedSort: pageState.selectedSort,
                  onSortSelected: (sorting) {
                    ref.read(genreControllerProvider.notifier).setSort(sorting);
                  },
                  useSliver: true,
                ),
                VerticalAnimeList(
                  animes: pageState.currentAnimeList,
                  onAnimeTap: (animeId, heroTag) {
                    context.router.push(
                      AnimeDetailRoute(animeId: animeId, heroTag: heroTag),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 类型展开状态通知器
final ValueNotifier<bool> expandedNotifier = ValueNotifier<bool>(true);
