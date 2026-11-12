import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/genre_state.dart';
import 'package:movies/providers.dart';
import 'package:movies/state/search_state.dart';
import 'package:movies/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'genre_controller.g.dart';

/// 选中类型存储键
const String genreStringKey = 'GenreKey';

/// Genre 页 tab（ALL 不限 type / Book 书籍 / Anime 动画）→ 映射为 Bangumi types
enum SubjectTypeFilter {
  all('ALL', []), // 空列表 = 不写 filter.type，不限类型
  book('Book', [1]),
  anime('Anime', [2]);

  const SubjectTypeFilter(this.label, this.types);
  final String label;
  final List<int> types;
}

/// 分类页状态（chip 选中 + 外部 tag + 搜索结果 + 排序）
class GenrePageState {
  const GenrePageState({
    this.genreStates = const [],
    this.currentAnimeList = const [],
    this.selectedSort = Sorting.aToz,
    this.keyword = '',
    this.externalTags = const [],
    this.typeFilter = SubjectTypeFilter.all,
  });

  /// 类型 chip 状态列表
  final List<GenreState> genreStates;

  /// 当前搜索结果
  final List<Anime> currentAnimeList;

  /// 排序方式
  final Sorting selectedSort;

  /// 当前搜索关键字（搜索框显示 / 重搜）
  final String keyword;

  /// 外部注入的临时 tag（详情页点标签），展示为前置 chip
  final List<String> externalTags;

  /// 当前选中的类型 tab
  final SubjectTypeFilter typeFilter;

  /// 已选中的类型名
  List<String> selectedNames() => [
        for (final state in genreStates)
          if (state.isSelected) state.genre.name,
      ];

  GenrePageState copyWith({
    List<GenreState>? genreStates,
    List<Anime>? currentAnimeList,
    Sorting? selectedSort,
    String? keyword,
    List<String>? externalTags,
    SubjectTypeFilter? typeFilter,
  }) {
    return GenrePageState(
      genreStates: genreStates ?? this.genreStates,
      currentAnimeList: currentAnimeList ?? this.currentAnimeList,
      selectedSort: selectedSort ?? this.selectedSort,
      keyword: keyword ?? this.keyword,
      externalTags: externalTags ?? this.externalTags,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }
}

/// 分类页控制器（keepAlive：搜索会话跨 Tab 切换复用）
/// 持有 chip 选中态、外部 tag 与搜索结果，负责类型持久化与搜索编排
@Riverpod(keepAlive: true)
class GenreController extends _$GenreController {
  /// 已消费的跨页请求序号（幂等：同序号只应用一次）
  int _appliedSeq = 0;

  @override
  Future<GenrePageState> build() async {
    // 数据层就绪门已保证 animeGenres 就绪；此处兜底空列表
    final genres = ref.read(animeRepositoryProvider).animeGenres ?? const [];
    final genreStates = [
      for (final genre in genres) GenreState(genre: genre, isSelected: false),
    ];
    return GenrePageState(
      genreStates: await _restoreSelected(genreStates),
    );
  }

  /// 从本地存储恢复选中状态（只改 isSelected，不重建列表）
  Future<List<GenreState>> _restoreSelected(List<GenreState> states) async {
    final prefs = await ref.read(prefsProvider.future);
    final raw = prefs.getString(genreStringKey);
    if (raw == null || raw.isEmpty) {
      return states;
    }
    final selectedNames = raw.split(',').where((s) => s.isNotEmpty).toSet();
    if (selectedNames.isEmpty) {
      return states;
    }
    return [
      for (final state in states)
        state.copyWith(isSelected: selectedNames.contains(state.genre.name)),
    ];
  }

  /// 消费一次跨页搜索请求（全局搜索 / SearchDialog / 详情页点标签）
  /// 同序号只应用一次，页面重建 / Tab 切回不会重复打请求
  Future<bool> applyRequest(SearchRequest request) async {
    // 非最新请求，直接返回
    if (request.seq <= _appliedSeq) {
      return false;
    }
    _appliedSeq = request.seq;
    var pageState = state.value!;
    // set keyword
    if (request.keyword != null) {
      pageState = pageState.copyWith(keyword: request.keyword);
    }
    // set tag
    final tag = request.extraTag;
    if (tag != null &&
        tag.trim().isNotEmpty &&
        !pageState.externalTags.contains(tag)) {
      // extraTag 直接 pageState.externalTags 到末尾
      pageState = pageState.copyWith(
        externalTags: [...pageState.externalTags, tag],
      );
    }
    // set type filter
    if (request.types != null && request.types.isNotEmpty) {
      pageState = pageState.copyWith(typeFilter: _filterOfType(request.types));
    }
    state = AsyncData(pageState);
    return search();
  }

  /// 本地搜索框提交
  Future<bool> searchByKeyword(String keyword) async {
    state = AsyncData(state.value!.copyWith(keyword: keyword));
    return search();
  }

  /// 更新 chip 选中状态（保持全量列表）并持久化，然后重搜
  Future<bool> updateSelections(List<GenreState> fullList) async {
    state = AsyncData(state.value!.copyWith(genreStates: fullList));
    await saveSelectedGenres();
    return search();
  }

  Future<bool> setTypeFilter(SubjectTypeFilter filter) async {
    state = AsyncData(state.value!.copyWith(typeFilter: filter));
    return search();
  }

  /// 移除外部临时 tag 并重搜
  Future<bool> removeExternalTag(String tag) async {
    final pageState = state.value!;
    state = AsyncData(pageState.copyWith(
      externalTags: [
        for (final t in pageState.externalTags)
          if (t != tag) t,
      ],
    ));
    return search();
  }

  /// 仅保存已选中的类型名
  Future<void> saveSelectedGenres() async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(genreStringKey, state.value!.selectedNames().join(','));
  }

  /// 已选中的类型名
  List<String> selectedNames() => state.value?.selectedNames() ?? const [];

  /// 切换排序方式
  void setSort(Sorting sorting) {
    state = AsyncData(state.value!.copyWith(selectedSort: sorting));
  }

  /// 按当前 keyword + 已选 chip + 外部 tag 搜索并刷新结果
  /// 关键字与 tags 都为空时返回 false（不打请求、不清列表）
  Future<bool> search() async {
    final pageState = state.value!;
    final query = pageState.keyword.trim();
    final selectedTags = <String>[];

    void addTag(String tag) {
      if (tag.trim().isNotEmpty && !selectedTags.contains(tag)) {
        selectedTags.add(tag);
      }
    }
    // append selectedTags from genreStates
    for (final name in pageState.selectedNames()) {
      addTag(name);
    }
    // append externalTags from pageState
    for (final tag in pageState.externalTags) {
      addTag(tag);
    }
    if (query.isEmpty && selectedTags.isEmpty) {
      return false;
    }
    // 搜索动漫
    final animeList = await ref.read(animeRepositoryProvider).searchAnimes(
          query,
          1,
          selectedTags.isEmpty ? null : selectedTags,
        );
    if (!ref.mounted) {
      return true;
    }
    state = AsyncData(
      pageState.copyWith(currentAnimeList: animeList ?? const []),
    );
    return true;
  }

  /// 把 List<int> 映回枚举：空列表→all，[1]→book，[2]→anime
  SubjectTypeFilter _filterOfType(List<int> types) {
    if (types.isEmpty) {
      return SubjectTypeFilter.all;
    }
    if (types.first == 1) {
      return SubjectTypeFilter.book;
    }
    if (types.first == 2) {
      return SubjectTypeFilter.anime;
    }
    return SubjectTypeFilter.all;
  }
}
