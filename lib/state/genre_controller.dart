import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/genre_state.dart';
import 'package:movies/data/repositories/anime_repository.dart';
import 'package:movies/utils/prefs.dart';
import 'package:movies/utils/utils.dart';

/// 选中类型存储键
const String genreStringKey = 'GenreKey';

/// 分类页控制器
/// 持有类型 chip 选中态与当前搜索结果，负责类型选择持久化与搜索
class GenreController {
  GenreController(this.animeRepository);

  final AnimeRepository animeRepository;

  /// 类型 chip 状态列表
  List<GenreState> genreStates = [];

  /// 当前搜索结果
  List<Anime> currentAnimeList = [];

  /// 排序方式
  Sorting selectedSort = Sorting.aToz;

  /// 类型列表是否已初始化（避免每次 build 清空重建）
  bool genreStateReady = false;

  /// 仅在首次拿到类型数据时初始化，后续 rebuild 不再 clear
  bool ensureGenreState() {
    if (genreStateReady) {
      return false;
    }
    final genres = animeRepository.animeGenres;
    if (genres == null || genres.isEmpty) {
      return false;
    }
    genreStates = [
      for (final genre in genres) GenreState(genre: genre, isSelected: false),
    ];
    genreStateReady = true;
    return true;
  }

  /// 从本地存储恢复选中状态（只改 isSelected，不重建列表）
  Future<void> restoreSelectedGenres(Prefs prefs) async {
    final raw = prefs.getString(genreStringKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final selectedNames = raw.split(',').where((s) => s.isNotEmpty).toSet();
    if (selectedNames.isEmpty) {
      return;
    }
    genreStates = [
      for (final state in genreStates)
        state.copyWith(isSelected: selectedNames.contains(state.genre.name)),
    ];
  }

  /// 仅保存已选中的类型名
  Future<void> saveSelectedGenres(Prefs prefs) async {
    final selectedNames = genreStates
        .where((state) => state.isSelected)
        .map((state) => state.genre.name)
        .toList();
    prefs.setString(genreStringKey, selectedNames.join(','));
  }

  /// 已选中的类型名（含跨页跳转 tag 去重后作为请求 tags）
  List<String> selectedNames() {
    return genreStates
        .where((state) => state.isSelected)
        .map((state) => state.genre.name)
        .toList();
  }

  /// 搜索并刷新当前结果列表
  /// 关键字与 tags 都为空时返回 false（不打请求、不清列表）
  Future<bool> search(String query, List<String> searchTags) async {
    final selectedTags = selectedNames();
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
    final animeList = await animeRepository.searchAnimes(
      query,
      1,
      selectedTags.isEmpty ? null : selectedTags,
    );
    currentAnimeList = animeList ?? [];
    return true;
  }
}
