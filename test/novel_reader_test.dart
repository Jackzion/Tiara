import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/ui/screens/novel_reader/novel_reader.dart';
import 'package:movies/utils/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// 以 Demo 书源 + 假书库深链进入阅读器（绕开会打网络的主页）
  Future<void> pumpReader(
    WidgetTester tester, {
    _FakeDatabase? database,
    String chapterId = 'c1',
  }) async {
    final router = AppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (database != null)
            driftDatabaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp.router(
          routerConfig: router.config(
            deepLinkBuilder: (_) => DeepLink.single(
              NovelReaderRoute(
                sourceKey: 'demo',
                bookId: 'demo-fog',
                chapterId: chapterId,
                title: '雾中站台',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('渲染章名与段落正文', (tester) async {
    await pumpReader(tester, database: _FakeDatabase());
    expect(find.textContaining('雾中站台'), findsWidgets);
    expect(find.textContaining('第 1 章第 1 段'), findsOneWidget);
    // 懒列表：滚到底部才构建末段
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.textContaining('第 1 章第 8 段'), findsOneWidget);
  });

  testWidgets('中央点击切换顶/底栏显隐', (tester) async {
    await pumpReader(tester, database: _FakeDatabase());
    final opacity = find.byType(AnimatedOpacity);
    expect(tester.widget<AnimatedOpacity>(opacity.first).opacity, 1);

    // 点中央
    await tester.tapAt(tester.getCenter(find.byType(ListView)));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(opacity.first).opacity, 0);

    // 再点恢复
    await tester.tapAt(tester.getCenter(find.byType(ListView)));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(opacity.first).opacity, 1);
  });

  testWidgets('「下一章」翻章加载第二章', (tester) async {
    await pumpReader(tester, database: _FakeDatabase());
    await tester.tap(find.text('下一章'));
    await tester.pumpAndSettle();
    expect(find.textContaining('第 2 章第 1 段'), findsOneWidget);
  });

  testWidgets('阅读设置面板可开合、字号改动即时生效', (tester) async {
    await pumpReader(tester, database: _FakeDatabase());
    await tester.tap(find.byTooltip('阅读设置'));
    await tester.pumpAndSettle();
    expect(find.text('阅读设置'), findsOneWidget);

    // 字号滑杆拖到最大
    final slider = find.byType(Slider).first;
    await tester.drag(slider, const Offset(300, 0));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(
      find.textContaining('第 1 章第 1 段').first,
    );
    expect(text.style!.fontSize, greaterThan(19));
  });

  testWidgets('书库进度恢复：滚到已读段落附近', (tester) async {
    final database = _FakeDatabase()
      ..savedProgressParagraph = 5;
    await pumpReader(tester, database: database);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('滚动后落库：savePlay 记录段落进度', (tester) async {
    final database = _FakeDatabase();
    await pumpReader(tester, database: database);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // 防抖 500ms 落库
    expect(database.lastPlay, isNotNull);
    expect(database.lastPlay!.playParamsJson, contains('novel-progress'));
    expect(database.lastPlay!.lastUnitId, 'c1');
  });

  group('NovelReaderPrefs 持久化', () {
    test('save 后 load 保持一致', () async {
      final prefs = await SharedPreferences.getInstance();
      const config = NovelReaderPrefs(
        fontSize: 22,
        lineHeight: 2.0,
        paper: NovelPaper.parchment,
      );
      await config.save(Prefs(prefs));
      final loaded = await NovelReaderPrefs.load(Prefs(prefs));
      expect(loaded.fontSize, 22);
      expect(loaded.lineHeight, 2.0);
      expect(loaded.paper, NovelPaper.parchment);
    });
  });
}

/// 内存假书库：只实现冒烟用到的 savePlay/findNovel
class _FakeDatabase implements IDatabase {
  LibraryPlayUpdate? lastPlay;
  int savedProgressParagraph = 0;

  @override
  Future savePlay(LibraryPlayUpdate update) async => lastPlay = update;

  @override
  Future<LibraryResume?> findNovel({
    required String sourceKey,
    required String bookId,
  }) async {
    if (savedProgressParagraph <= 0) return null;
    return LibraryResume(
      id: 1,
      uid: 'novel:$sourceKey:$bookId',
      type: 1,
      title: '雾中站台',
      updatedAt: DateTime.now(),
      sourceKey: sourceKey,
      remoteId: bookId,
      playParamsJson:
          '{"kind":"novel-progress","paragraphIndex":$savedProgressParagraph,'
          '"fraction":0.5,"textOffset":0}',
      lastUnitId: 'c1',
      lastUnitTitle: '第 1 章',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
