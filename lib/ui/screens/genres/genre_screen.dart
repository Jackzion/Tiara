import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/genre_controller.dart';
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
  String _lastSearchedText = '';
  List<String> _lastSearchedTag = [];

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

  /// 把选中的类型同步到跨页 searchTagProvider
  void updateSearchTags() {
    final notifier = ref.read(searchTagProvider.notifier);
    // 必须赋一个新列表实例，GenreScreen 的 watch 才能感知变化
    notifier.state = ref.read(genreControllerProvider.notifier).selectedNames();
  }

  Widget buildScreen(GenrePageState pageState) {
    // SearchDialog / 菜单 / 全局搜索写入 searchTextProvider 时同步并触发搜索
    final searchText = ref.watch(searchTextProvider);
    // 详情页点标签跳转写入 searchTagProvider，也要带着最新 genres 重新请求
    final searchTag = ref.watch(searchTagProvider);
    final textChanged = searchText != _lastSearchedText;
    // 列表按内容比较（引用比较会每次 rebuild 都判为变化）
    final tagChanged = !listEquals(searchTag, _lastSearchedTag);

    // textChanged || tagChanged 才触发 search()
    if (textChanged || tagChanged) {
      _lastSearchedText = searchText; // 只读记忆，没有任何地方会"回写"它
      _lastSearchedTag = List<String>.from(searchTag);
      final hasText = searchText.trim().isNotEmpty;
      final hasTag = searchTag.any((tag) => tag.trim().isNotEmpty);
      // 全局搜索同词双写会经过 ''：中间态不请求、不清列表，避免闪空
      if (!hasText && !hasTag) {
        return SafeArea(child: _genreBody(context, pageState));
      }
      // 本帧纯渲染「空结果 + 收起 chip」（不写任何状态，build 期禁止改 provider）；
      // postFrame 再复位展开态并发起搜索
      WidgetsBinding.instance.addPostFrameCallback((_) {
        expandedNotifier.value = false;
        search();
      });
      return SafeArea(
        child: _genreBody(
          context,
          pageState.copyWith(currentAnimeList: const []),
          isExpanded: false,
        ),
      );
    }
    return SafeArea(child: _genreBody(context, pageState));
  }

  Widget _genreBody(
    BuildContext context,
    GenrePageState pageState, {
    bool? isExpanded,
  }) {
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
                    GenreSearchRow(ref.watch(searchTextProvider), (
                      searchString,
                    ) {
                      // 只写 provider，其余交给 buildScreen 统一触发
                      ref.read(searchTextProvider.notifier).state =
                          searchString;
                      FocusScope.of(context).unfocus();
                    }),
                  ]),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: expandedNotifier,
                  builder: (BuildContext context, bool value, Widget? child) {
                    return GenreSection(
                      genreStates: pageState.genreStates,
                      isExpanded: isExpanded ?? value,
                      onGenresExpanded: (expanded) {
                        expandedNotifier.value = expanded;
                      },
                      onGenresSelected: (fullList) {
                        // 保持全量列表，只同步选中状态（内部会持久化）
                        ref
                            .read(genreControllerProvider.notifier)
                            .updateSelections(fullList);
                        // update searchTags provider
                        updateSearchTags();
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
                  onAnimeTap: (animeId) {
                    context.router.push(AnimeDetailRoute(animeId: animeId));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void search() async {
    // 全局搜索双写 '' + keyword 时，空串不要打请求
    final query = ref.read(searchTextProvider).trim();
    // read tag provider（可能有多个，逐个并入）
    final searchTags = ref.read(searchTagProvider);
    final requested =
        await ref.read(genreControllerProvider.notifier).search(query, searchTags);
    if (!requested || !mounted) {
      return;
    }
    expandedNotifier.value = true;
  }
}

/// 类型展开状态通知器
final ValueNotifier<bool> expandedNotifier = ValueNotifier<bool>(true);
