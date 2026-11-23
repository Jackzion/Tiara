import 'package:flutter_test/flutter_test.dart';
import 'package:movies/services/novel/novel_pagination.dart';

void main() {
  // 测试环境用 Ahem 字体（每字形等宽），行折可预测到"段落级别"不变量
  const layout = NovelLayout(
    width: 200,
    height: 100,
    fontSize: 20,
    lineHeight: 1.0,
    paragraphGap: 10,
  );

  /// 收集所有文本片段（按出现顺序）
  List<NovelFragment> textFragments(List<NovelPage> pages) =>
      [for (final p in pages) ...p.fragments.where((f) => !f.isImage)];

  group('NovelPagination.paginate', () {
    test('长段落按行装页：区间连续覆盖原文、页高不超限', () async {
      final text = 'a' * 200; // 单个超长段落
      final pages = await NovelPagination().paginate([text], layout);
      expect(pages, isNotNull);
      expect(pages!.length, greaterThan(1));

      final fragments = textFragments(pages);
      // 片段区间首尾相接、完整覆盖段落
      var cursor = 0;
      for (final f in fragments) {
        expect(f.paragraph, 0);
        expect(f.start, cursor);
        cursor = f.end;
      }
      expect(cursor, text.length);
      // 片段高度不超页高（行不被切开的必要条件）
      for (final f in fragments) {
        expect(f.rect.height, lessThanOrEqualTo(layout.height));
      }
    });

    test('多段落：段序保持、段落可跨页', () async {
      final paragraphs = [
        'a' * 200, // 超长段（必然跨页）
        'b' * 20,
        'c' * 200,
      ];
      final pages = await NovelPagination().paginate(paragraphs, layout);
      expect(pages, isNotNull);

      final fragments = textFragments(pages!);
      // 段落下标单调不减
      for (var i = 1; i < fragments.length; i++) {
        expect(fragments[i].paragraph,
            greaterThanOrEqualTo(fragments[i - 1].paragraph));
      }
      // 超长段 0 必然出现在多个页上
      final pagesOfFirst = {
        for (final p in pages)
          if (p.fragments.any((f) => f.paragraph == 0)) p,
      };
      expect(pagesOfFirst.length, greaterThan(1));
    });

    test('插图段独占一页', () async {
      final pages = await NovelPagination().paginate(
        ['开头文字', '<!--image-->https://a/1.jpg<!--image-->', '结尾文字'],
        layout,
      );
      expect(pages, isNotNull);
      final imagePages = pages!.where((p) => p.isImage).toList();
      expect(imagePages, hasLength(1));
      expect(imagePages.single.fragments.single.url, 'https://a/1.jpg');
      // 整页尺寸
      expect(imagePages.single.fragments.single.rect.width, layout.width);
    });

    test('字号变大 → 页数变多（重排生效）', () async {
      final text = ['a' * 400];
      final small = await NovelPagination().paginate(
        text,
        const NovelLayout(width: 200, height: 100, fontSize: 16, lineHeight: 1),
      );
      final large = await NovelPagination().paginate(
        text,
        const NovelLayout(width: 200, height: 100, fontSize: 32, lineHeight: 1),
      );
      expect(small!.length, lessThan(large!.length));
    });

    test('取消令牌 → 返回 null', () async {
      final pages = await NovelPagination().paginate(
        ['a' * 10000, 'b' * 10000],
        layout,
        cancelled: () => true,
      );
      expect(pages, isNull);
    });
  });

  group('novelImageUrlOf', () {
    test('取第一对标记内的 URL（多图连排不吞标记流）', () {
      expect(
        novelImageUrlOf('<!--image-->https://a/1.jpg<!--image-->'),
        'https://a/1.jpg',
      );
      expect(
        novelImageUrlOf(
          '<!--image-->https://a/1.jpg<!--image-->   '
          '<!--image-->https://a/2.jpg<!--image-->',
        ),
        'https://a/1.jpg',
      );
      expect(novelImageUrlOf('普通文本'), isNull);
      expect(novelImageUrlOf('<!--image-->未闭合'), isNull);
    });
  });
}
