import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:movies/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_source_controller.g.dart';

/// 每源一行的搜索状态
enum ComicSourceRowStatus { pending, success, empty, error }

/// 面板里的一行：一个图源的搜索结果
class ComicSourceRow {
  const ComicSourceRow({
    required this.sourceKey,
    required this.sourceName,
    this.status = ComicSourceRowStatus.pending,
    this.matches = const [],
    this.errorMessage,
  });

  final String sourceKey;
  final String sourceName;
  final ComicSourceRowStatus status;

  /// 该源命中的候选（已按精确命中置顶）
  final List<ComicMatch> matches;

  /// status == error 时的错误摘要
  final String? errorMessage;
}

/// 面板数据：每源一行 + 选中项的章节列表
class ComicSheetState {
  const ComicSheetState({
    this.rows = const [],
    this.selected,
    this.chapters = const [],
  });

  /// 并行搜索结果（每源一行）
  final List<ComicSourceRow> rows;

  /// 用户点中的漫画（章节列表的归属）
  final ComicMatch? selected;

  /// selected 的章节列表（顺序即阅读顺序）
  final List<ComicChapter> chapters;

  ComicSheetState copyWith({
    List<ComicSourceRow>? rows,
    ComicMatch? selected,
    List<ComicChapter>? chapters,
  }) {
    return ComicSheetState(
      rows: rows ?? this.rows,
      selected: selected ?? this.selected,
      chapters: chapters ?? this.chapters,
    );
  }
}

/// 选图源面板状态（family: keyword，随面板销毁）
@riverpod
class ComicSourceController extends _$ComicSourceController {
  /// build 的 family 参数（实例方法也要用，存一份）
  late String _keyword;

  @override
  Future<ComicSheetState> build(String keyword) async {
    _keyword = keyword;
    final repo = await ref.read(comicRepositoryProvider.future);
    final sources = repo.sources.values.toList();
    // 空列表 = 图源未就绪（规则未装载），UI 显示空态
    if (sources.isEmpty) {
      return const ComicSheetState();
    }
    // to show all pending currently
    final initial = ComicSheetState(
      rows: [
        for (final s in sources)
          ComicSourceRow(sourceKey: s.key, sourceName: s.name),
      ],
    );
    // 后台并发跑，谁先回谁先 patch - 注:相比 unawait -> unwait 会执行到 future 才会让出 cpu , 而 microtask 会直接让给 ui 渲染
    Future.microtask(() => _runAll(sources));

    return initial;
  }

  /// 单源搜索；失败只标记该行 error，不拖垮其它行（计划 §3.5）
  Future<ComicSourceRow> _searchOne(ComicSource source) async {
    try {
      // searchLoad -> ComicItem[]
      final items = await source.searchLoad(_keyword);
      final matches =
          [for (final c in items) ComicMatch(sourceKey: source.key, comic: c)]
            // 精确命中置顶
            ..sort(
              (a, b) =>
                  (b.exact(_keyword) ? 1 : 0) - (a.exact(_keyword) ? 1 : 0),
            );
      return ComicSourceRow(
        sourceKey: source.key,
        sourceName: source.name,
        status: matches.isEmpty
            ? ComicSourceRowStatus.empty
            : ComicSourceRowStatus.success,
        matches: matches.take(3).toList(),
      );
    } catch (e) {
      // 单条失败不阻塞其它源
      logError('搜索失败 ${source.key}: $e');
      return ComicSourceRow(
        sourceKey: source.key,
        sourceName: source.name,
        status: ComicSourceRowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 点匹配项 → 拉章节；失败抛给 UI 提示（snackbar）
  Future<void> select(ComicMatch match) async {
    final repo = await ref.read(comicRepositoryProvider.future);
    // 先清旧章节，UI 立刻反映「选中但章节加载中」
    // set State with selected and chapters = []
    state = AsyncData(
      state.value!.copyWith(selected: match, chapters: const []),
    );
    // loadChapters -> ComicChapter[]
    final chapters = await repo.loadChapters(match.sourceKey, match.comicId);
    if (!ref.mounted) {
      return;
    }
    // set State with chapters
    state = AsyncData(state.value!.copyWith(chapters: chapters));
  }

  // search and update comicSourceRow when worker finished
  Future<void> _runAll(List<ComicSource> sources) async {
    const concurrency = 3;
    var next = 0;
    Future<void> worker() async {
      while (next < sources.length && ref.mounted) {
        final source = sources[next++];
        final row = await _searchOne(source);
        if (!ref.mounted) return;
        _patch(row);
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
  }

  // update one comicSourceRow
  void _patch(ComicSourceRow row) {
    final currentState = state.value;
    if (currentState == null) return;
    // get the new comicSourceRows
    final newRows = [
      for (final r in currentState.rows) r.sourceKey == row.sourceKey ? row : r,
    ];
    // sort with error message
    newRows.sort((a, b) {
      final aHasError = a.errorMessage != null && a.errorMessage!.isNotEmpty;
      final bHasError = b.errorMessage != null && b.errorMessage!.isNotEmpty;

      if (aHasError == bHasError) return 0; // 保持原相对顺序
      return aHasError ? 1 : -1; // 有错的排后面
    });
    // update state
    state = AsyncData(currentState.copyWith(rows: newRows));
  }
}
