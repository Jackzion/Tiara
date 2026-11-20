import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/data/repositories/library_repository.dart';
import 'package:movies/data/repositories/novel_repository.dart';

void main() {
  group('NovelItem.fromJson', () {
    test('解析搜索结果条目', () {
      final item = NovelItem.fromJson({
        'id': 42,
        'title': '雾中站台',
        'cover': 'https://example.com/c.jpg',
        'subtitle': '演示作者甲',
      });
      expect(item.id, '42');
      expect(item.title, '雾中站台');
      expect(item.cover, 'https://example.com/c.jpg');
      expect(item.subtitle, '演示作者甲');
    });

    test('缺可选字段时为 null', () {
      final item = NovelItem.fromJson({'id': 'x', 'title': 't'});
      expect(item.cover, isNull);
      expect(item.subtitle, isNull);
    });
  });

  group('NovelDetail.fromInfo', () {
    test('解析章节目录（chapters map 顺序即阅读顺序）', () {
      final detail = NovelDetail.fromInfo({
        'title': '群星低语',
        'author': '演示作者乙',
        'intro': '简介',
        'chapters': {'c1': '第 1 章', 'c2': '第 2 章'},
      });
      expect(detail.title, '群星低语');
      expect(detail.author, '演示作者乙');
      expect(detail.chapters, hasLength(2));
      expect(detail.chapters[0].chapterId, 'c1');
      expect(detail.chapters[1].title, '第 2 章');
    });

    test('缺 chapters 时为空目录', () {
      final detail = NovelDetail.fromInfo({'title': 't'});
      expect(detail.chapters, isEmpty);
    });
  });

  group('NovelProgress', () {
    test('JSON 往返保持字段', () {
      const progress = NovelProgress(
        paragraphIndex: 3,
        fraction: 0.42,
        textOffset: 17,
        fontSize: 19,
        layoutKey: 'v1:19:1.72',
      );
      final decoded = NovelProgress.fromJson(
        jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.paragraphIndex, 3);
      expect(decoded.fraction, 0.42);
      expect(decoded.textOffset, 17);
      expect(decoded.fontSize, 19);
      expect(decoded.layoutKey, 'v1:19:1.72');
    });

    test('kind 标记与动画播放参数区分', () {
      expect(const NovelProgress().toJson()['kind'], 'novel-progress');
    });

    test('缺字段时给默认值', () {
      final decoded = NovelProgress.fromJson(const {});
      expect(decoded.paragraphIndex, 0);
      expect(decoded.fraction, 0);
      expect(decoded.textOffset, 0);
      expect(decoded.fontSize, isNull);
    });
  });

  group('LibraryRepository.saveNovelRead', () {
    test('uid 约定与进度 JSON 落库', () async {
      final fake = _FakeDatabase();
      final repo = LibraryRepository(database: fake);
      await repo.saveNovelRead(
        sourceKey: 'demo',
        bookId: 'demo-fog',
        title: '雾中站台',
        chapterId: 'c2',
        chapterTitle: '第 2 章',
        progress: const NovelProgress(paragraphIndex: 5, fraction: 0.5),
      );
      expect(fake.last, isNotNull);
      expect(fake.last!.uid, 'novel:demo:demo-fog');
      expect(fake.last!.type, 1);
      expect(fake.last!.lastUnitId, 'c2');
      expect(fake.last!.lastUnitTitle, '第 2 章');
      final progress = NovelProgress.fromJson(
        jsonDecode(fake.last!.playParamsJson!) as Map<String, dynamic>,
      );
      expect(progress.paragraphIndex, 5);
      expect(progress.fraction, 0.5);
    });

    test('progress 为空时只记章', () async {
      final fake = _FakeDatabase();
      final repo = LibraryRepository(database: fake);
      await repo.saveNovelRead(
        sourceKey: 'demo',
        bookId: 'demo-fog',
        title: '雾中站台',
        chapterId: 'c1',
        chapterTitle: '第 1 章',
      );
      expect(fake.last!.playParamsJson, isNull);
    });

    test('关键字段为空时跳过落库', () async {
      final fake = _FakeDatabase();
      final repo = LibraryRepository(database: fake);
      await repo.saveNovelRead(
        sourceKey: '',
        bookId: 'demo-fog',
        title: '雾中站台',
        chapterId: 'c1',
        chapterTitle: '第 1 章',
      );
      expect(fake.last, isNull);
    });
  });

  group('DemoNovelSource', () {
    final source = DemoNovelSource.create();

    test('搜索命中标题或作者', () async {
      final byTitle = await source.searchLoad('雾中');
      expect(byTitle, hasLength(1));
      expect(byTitle.first.id, 'demo-fog');

      final byAuthor = await source.searchLoad('演示作者乙');
      expect(byAuthor, hasLength(1));
      expect(byAuthor.first.id, 'demo-star');

      expect(await source.searchLoad(''), isEmpty);
    });

    test('目录与正文', () async {
      final info = await source.loadBookInfo('demo-fog');
      final detail = NovelDetail.fromInfo(info);
      expect(detail.chapters, hasLength(3));

      final text = await source.loadBookText('demo-fog', 'c2');
      expect(text.split('\n\n'), hasLength(8));
    });

    test('未知书/未知章抛错', () async {
      await expectLater(source.loadBookInfo('none'), throwsException);
      await expectLater(
        source.loadBookText('demo-fog', 'c99'),
        throwsException,
      );
    });
  });

  group('NovelRepository.matchSearch', () {
    test('精确命中置顶、单源失败不阻塞其它源', () async {
      final repo = NovelRepository({
        'demo': DemoNovelSource.create(),
        'broken': _BrokenSource(),
      });
      final matches = await repo.matchSearch('雾中站台');
      expect(matches, hasLength(1));
      expect(matches.first.exact('雾中站台'), isTrue);
      expect(matches.first.bookId, 'demo-fog');
    });
  });
}

/// 只实现 savePlay，其余方法用例里不会走到
class _FakeDatabase implements IDatabase {
  LibraryPlayUpdate? last;

  @override
  Future savePlay(LibraryPlayUpdate update) async => last = update;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 永远失败的源（验证 matchSearch 容错）
class _BrokenSource extends NovelSource {
  _BrokenSource()
      : super(
          key: 'broken',
          name: 'broken',
          version: '0',
          loadBookInfo: (_) async => throw Exception('boom'),
          loadBookText: (_, _) async => throw Exception('boom'),
          searchLoad: (_) async => throw Exception('boom'),
        );
}
