import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/genre_state.dart';
import 'package:movies/providers.dart';
import 'package:movies/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'genre_controller.g.dart';

/// 选中类型存储键
const String genreStringKey = 'GenreKey';

/// 分类页状态（chip 选中 + 搜索结果 + 排序）
class GenrePageState {
  const GenrePageState({
    this.genreStates = const [],
    this.currentAnimeList = const [],
    this.selectedSort = Sorting.aToz,
  });

  /// 类型 chip 状态列表
  final List<GenreState> genreStates;

  /// 当前搜索结果
  final List<Anime> currentAnimeList;

  /// 排序方式
  final Sorting selectedSort;

  /// 已选中的类型名
  List<String> selectedNames() => [
        for (final state in genreStates)
          if (state.isSelected) state.genre.name,
      ];

  GenrePageState copyWith({
    List<GenreState>? genreStates,
    List<Anime>? currentAnimeList,
    Sorting? selectedSort,
  }) {
    return GenrePageState(
      genreStates: genreStates ?? this.genreStates,
      currentAnimeList: currentAnimeList ?? this.currentAnimeList,
      selectedSort: selectedSort ?? this.selectedSort,
    );
  }
}

/// 分类页控制器（autoDispose：随页面销毁）
/// 持有类型 chip 选中态与当前搜索结果，负责类型选择持久化与搜索
@riverpod
class GenreController extends _$GenreController {
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

  /// 更新 chip 选中状态（保持全量列表）并持久化
  Future<void> updateSelections(List<GenreState> fullList) async {
    state = AsyncData(state.value!.copyWith(genreStates: fullList));
    await saveSelectedGenres();
  }

  /// 仅保存已选中的类型名
  Future<void> saveSelectedGenres() async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(genreStringKey, state.value!.selectedNames().join(','));
  }

  /// 已选中的类型名（含跨页跳转 tag 去重后作为请求 tags）
  List<String> selectedNames() => state.value?.selectedNames() ?? const [];

  /// 切换排序方式
  void setSort(Sorting sorting) {
    state = AsyncData(state.value!.copyWith(selectedSort: sorting));
  }

  /// 搜索并刷新当前结果列表
  /// 关键字与 tags 都为空时返回 false（不打请求、不清列表）
  Future<bool> search(String query, List<String> searchTags) async {
    final pageState = state.value!;
    final selectedTags = [...pageState.selectedNames()];
    // 搜索 tags 并入最新 genres（已选同名时去重）
    for (final tag in searchTags) {
      if (tag.trim().isNotEmpty && !selectedTags.contains(tag)) {
        selectedTags.add(tag);
      }
    }
    // 关键字与标签都为空时不打请求（支持仅 tag 的搜索）
    if (query.isEmpty && selectedTags.isEmpty) {
      return false;
    }
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
}
