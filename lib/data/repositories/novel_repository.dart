
import 'package:collection/collection.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/novel_source.dart';

/// 小说仓库：多书源并行搜索 + 目录/正文获取（对标 ComicRepository）。
class NovelRepository {
  NovelRepository(this.sources);
  final Map<String, NovelSource> sources;

  /// 多源并行搜索，精确命中（标题相等）置顶
  Future<List<NovelMatch>> matchSearch(String title) async {
    final futures = sources.values.map((s) async {
      try {
        final res = await s.searchLoad(title); // search.load(title, [], 1)
        return [for (final n in res) NovelMatch(sourceKey: s.key, novel: n)];
      } catch (e) {
        logError('matchSearch ${s.key}: $e');
        return <NovelMatch>[];
      }
    });
    final all = (await Future.wait(futures)).expand((e) => e).toList();
    all.sort((a, b) => (b.exact(title) ? 1 : 0) - (a.exact(title) ? 1 : 0));
    return all;
  }

  /// 书籍详情（含章节目录，顺序即阅读顺序）
  Future<NovelDetail> loadInfo(String sourceKey, String bookId) async {
    Future<NovelDetail> fetch() async {
      final info = await sources[sourceKey]!.loadBookInfo(bookId);
      return NovelDetail.fromInfo(info);
    }

    try {
      return await fetch();
    } catch (e) {
      // 与漫画源一致：210 限频退避 3 秒补一次
      if (!e.toString().contains('210')) rethrow;
      await Future.delayed(const Duration(seconds: 3));
      return fetch();
    }
  }

  /// 章节正文（纯文本，段落 \n\n 分隔）
  Future<String> loadText(
    String sourceKey,
    String bookId,
    String chapterId,
  ) =>
      sources[sourceKey]!.loadBookText(bookId, chapterId);
}

/// 内置演示书源：2 本假书，供阅读器 MVP 开发与离线兜底
/// （对标 Wenku8 的 DemoNovelRepository；P3 接入真实规则源后仍保留）。
class DemoNovelSource {
  DemoNovelSource._();

  static const String key = 'demo';

  static NovelSource create() => NovelSource(
        key: key,
        name: '演示书库',
        version: '1.0.0',
        loadBookInfo: _loadBookInfo,
        loadBookText: _loadBookText,
        searchLoad: _searchLoad,
      );

  static const List<({String id, String title, String author, int chapters})>
      _books = [
    (id: 'demo-fog', title: '雾中站台', author: '演示作者甲', chapters: 3),
    (id: 'demo-star', title: '群星低语', author: '演示作者乙', chapters: 2),
  ];

  static Future<Map<String, dynamic>> _loadBookInfo(String bookId) async {
    final book = _books.where((b) => b.id == bookId).firstOrNull;
    if (book == null) throw Exception('演示书库没有这本书：$bookId');
    return {
      'title': book.title,
      'author': book.author,
      'intro': '演示数据，仅供开发与离线预览。',
      'chapters': {
        for (var i = 1; i <= book.chapters; i++) 'c$i': '第 $i 章',
      },
    };
  }

  static Future<String> _loadBookText(String bookId, String chapterId) async {
    final book = _books.where((b) => b.id == bookId).firstOrNull;
    if (book == null) throw Exception('演示书库没有这本书：$bookId');
    final index = int.tryParse(chapterId.replaceFirst('c', '')) ?? 0;
    if (index < 1 || index > book.chapters) {
      throw Exception('演示书库没有这一章：$bookId/$chapterId');
    }
    return [
      for (var p = 1; p <= 8; p++)
        '《${book.title}》第 $index 章第 $p 段。这是演示正文，'
            '用于验证阅读器的滚动、分页与进度恢复；正式接入规则源后会被真实章节替换。',
    ].join('\n\n');
  }

  static Future<List<NovelItem>> _searchLoad(String keyword) async {
    if (keyword.isEmpty) return const [];
    return [
      for (final b in _books)
        if (b.title.contains(keyword) || b.author.contains(keyword))
          NovelItem(id: b.id, title: b.title, subtitle: b.author),
    ];
  }
}
