import 'package:movies/data/api/wenku8_api_service.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/data/parsing/wenku8_xml_parser.dart';
import 'package:movies/services/novel/novel_text_loader.dart';

/// wenku8 书源：App XML API → NovelSource 门面（对标 comic 的规则源装配）。
///
/// 挂进 NovelRepository.sources（key = [sourceKey]）后，阅读器/选源面板
/// 侧零改动。正文格式与阅读器约定一致：段落 `\n\n` 分隔 + `<!--image-->` 插图段。
class Wenku8Repository {
  Wenku8Repository(this.api, this.loader);

  final Wenku8ApiService api;
  final NovelTextLoader loader;

  static const String sourceKey = 'wenku8';

  /// 装配为可挂载的书源门面
  NovelSource asSource() => NovelSource(
        key: sourceKey,
        name: '轻小说文库',
        version: '1.0.0',
        loadBookInfo: _loadBookInfo,
        loadBookText: _loadBookText,
        searchLoad: _searchLoad,
      );

  /// 书籍元数据 + 分卷目录 → loadInfo 约定的 Map（2 次请求，节流在 api 层）
  Future<Map<String, dynamic>> _loadBookInfo(String bookId) async {
    final aid = int.parse(bookId);
    final metaHtml = await api.bookMeta(aid);
    final info = Map<String, dynamic>.from(parseWenku8BookMeta(metaHtml));
    final catalogHtml = await api.bookCatalog(aid);
    info['chapters'] = [
      for (final c in parseWenku8Catalog(catalogHtml))
        {
          'chapterId': c.chapterId,
          'title': c.title,
          if (c.volumeTitle != null) 'volumeTitle': c.volumeTitle,
        },
    ];
    info['cover'] ??= Wenku8ApiService.coverUrl(aid);
    return info;
  }

  /// 章节正文 → 阅读器内部格式（磁盘缓存 + 版权下架识别）
  Future<String> _loadBookText(String bookId, String chapterId) async {
    final aid = int.parse(bookId);
    final cid = int.parse(chapterId);
    final text = await loader.ensure(
      sourceKey: sourceKey,
      bookId: bookId,
      chapterId: chapterId,
      fetch: () async {
        final raw = await api.bookText(aid, cid);
        if (isWenku8TextUnavailable(raw)) {
          throw Wenku8RemovedException(bookId, chapterId);
        }
        return normalizeWenku8ChapterText(raw);
      },
    );
    return text;
  }

  /// 搜索（书名；无结果再试作者）
  Future<List<NovelItem>> _searchLoad(String keyword) async {
    final byName = parseWenku8NovelItems(await api.search(keyword));
    if (byName.isNotEmpty) return byName;
    try {
      return parseWenku8NovelItems(
        await api.search(keyword, type: 'author'),
      );
    } catch (_) {
      return const [];
    }
  }
}

/// 版权下架：网页/接口不再提供该书正文
class Wenku8RemovedException implements Exception {
  const Wenku8RemovedException(this.bookId, this.chapterId);

  final String bookId;
  final String chapterId;

  @override
  String toString() => '因版权问题，文库不再提供该小说的在线阅读（$bookId/$chapterId）';
}
