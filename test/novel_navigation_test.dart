import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/services/novel/novel_navigation.dart';

void main() {
  group('findNovelMatches', () {
    test('多段命中按顺序返回、大小写不敏感', () {
      final matches = findNovelMatches(
        ['开头Foo中间foo', '无命中', 'foo'],
        'FOO',
      );
      expect(matches, hasLength(3));
      expect(
        matches.map((m) => (m.paragraph, m.start, m.end)),
        [(0, 2, 5), (0, 7, 10), (2, 0, 3)],
      );
    });

    test('空查询/无命中返回空', () {
      expect(findNovelMatches(['abc'], ''), isEmpty);
      expect(findNovelMatches(['abc'], 'xyz'), isEmpty);
    });
  });

  group('groupChaptersByVolume', () {
    test('连续同卷折叠、空卷归 null 组', () {
      const chapters = [
        NovelChapter(chapterId: '1', title: '序章', volumeTitle: '第一卷'),
        NovelChapter(chapterId: '2', title: '一', volumeTitle: '第一卷'),
        NovelChapter(chapterId: '3', title: '插图'),
        NovelChapter(chapterId: '4', title: '二', volumeTitle: '第二卷'),
        NovelChapter(chapterId: '5', title: '三', volumeTitle: '第二卷'),
      ];
      final groups = groupChaptersByVolume(chapters);
      expect(groups, hasLength(3));
      expect(groups[0].volume, '第一卷');
      expect(groups[0].chapters, hasLength(2));
      expect(groups[1].volume, isNull);
      expect(groups[2].volume, '第二卷');
      expect(groups[2].chapters, hasLength(2));
    });
  });

  group('buildHighlightedSpan', () {
    const style = TextStyle(fontSize: 14);

    test('区间高亮与普通文本交替', () {
      final span = buildHighlightedSpan('abcdef', style, [(1, 3)]);
      final children = (span as TextSpan).children!;
      expect(children, hasLength(3));
      expect((children[0] as TextSpan).text, 'a');
      expect((children[1] as TextSpan).text, 'bc');
      expect((children[2] as TextSpan).text, 'def');
    });

    test('base 偏移裁剪（分页片段子串场景）', () {
      // 段内区间 [4,6)，片段从 base=4 开始 → 片段内 [0,2) 高亮
      final span = buildHighlightedSpan('cdef', style, [(4, 6)], base: 4);
      final children = (span as TextSpan).children!;
      expect(children, hasLength(2));
      expect((children[0] as TextSpan).text, 'cd');
      expect((children[1] as TextSpan).text, 'ef');
    });

    test('无区间返回纯文本', () {
      final span = buildHighlightedSpan('abc', style, const []);
      expect(span is TextSpan && span.children == null, isTrue);
    });
  });
}
