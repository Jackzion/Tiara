
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/comic_source.dart';

class ComicRepository {
  ComicRepository(this.sources);
  final Map<String, ComicSource> sources;

  /// 多源并行搜索，精确命中（标题相等）置顶
  Future<List<ComicMatch>> matchSearch(String title) async {
    final futures = sources.values.map((s) async {
      try {
        final res = await s.searchLoad(title);   // search.load(title, [], 1)
        return [for (final c in res) ComicMatch(sourceKey: s.key, comic: c)];
      } catch (e) {
        logError('matchSearch ${s.key}: $e');
        return <ComicMatch>[];
      }
    });
    final all = (await Future.wait(futures)).expand((e) => e).toList();
    all.sort((a, b) => (b.exact(title) ? 1 : 0) - (a.exact(title) ? 1 : 0));
    return all;
  }

  /// 章节列表（顺序即阅读顺序）
  Future<List<ComicChapter>> loadChapters(String sourceKey, String comicId) async {
    final info = await sources[sourceKey]!.loadComicInfo(comicId);
    final chapters = (info['chapters'] as Map?) ?? const {};
    return [for (final e in chapters.entries) ComicChapter(epId: '${e.key}', title: '${e.value}')];
  }

  /// 一页图（imageKey + 加载配置）
  Future<List<ComicPage>> loadPages(String sourceKey, String comicId, String epId) async {
    final source = sources[sourceKey]!;
    final images = await source.loadComicPages(comicId, epId);
    final getConfig = source.getImageLoadingConfig;
    final pages = <ComicPage>[];
    for (final imageKey in images) {
      final config = getConfig == null
          ? null
          : await getConfig(imageKey, comicId, epId);
      pages.add(ComicPage(imageKey: imageKey, imageLoadingConfig: config));
    }
    return pages;
  }
}