import 'package:flutter/painting.dart';
import 'package:movies/data/models/novel_source.dart';

/// 章内查找命中（段内字符区间 [start, end)）
class NovelMatchPosition {
  const NovelMatchPosition(this.paragraph, this.start, this.end);

  final int paragraph;
  final int start;
  final int end;
}

/// 带上下文的命中（全书搜索结果项）
class NovelSearchHit {
  const NovelSearchHit({
    required this.paragraph,
    required this.start,
    required this.end,
    required this.snippet,
    required this.matchStart,
  });

  /// 命中所在的段落下标与段内区间
  final int paragraph;
  final int start;
  final int end;

  /// 上下文片段（命中前后各带一段文字，单行展示）
  final String snippet;

  /// 命中在 [snippet] 中的起点（终点 = matchStart + (end - start)）
  final int matchStart;
  int get matchEnd => matchStart + (end - start);
}

/// 正文切段：\n\n 分隔、去空行（与阅读器控制器一致）
List<String> splitNovelParagraphs(String text) => [
      for (final p in text.split('\n\n'))
        if (p.trim().isNotEmpty) p.trim(),
    ];

/// 章内查找：大小写不敏感，按 (段落, 位置) 顺序返回全部命中。
List<NovelMatchPosition> findNovelMatches(
  List<String> paragraphs,
  String query,
) {
  final needle = query.toLowerCase();
  if (needle.isEmpty) return const [];
  final out = <NovelMatchPosition>[];
  for (var i = 0; i < paragraphs.length; i++) {
    final text = paragraphs[i].toLowerCase();
    var from = 0;
    while (true) {
      final at = text.indexOf(needle, from);
      if (at < 0) break;
      out.add(NovelMatchPosition(i, at, at + query.length));
      from = at + query.length;
    }
  }
  return out;
}

/// 单段带上下文命中：命中前后各取 [context] 字符做 snippet（边界截断）。
List<NovelSearchHit> findNovelHitsWithContext(
  String paragraph,
  String query, {
  int paragraphIndex = 0,
  int context = 24,
}) {
  final needle = query.toLowerCase();
  if (needle.isEmpty) return const [];
  final text = paragraph.toLowerCase();
  final hits = <NovelSearchHit>[];
  var from = 0;
  while (true) {
    final at = text.indexOf(needle, from);
    if (at < 0) break;
    final end = at + query.length;
    final winStart = (at - context).clamp(0, paragraph.length);
    final winEnd = (end + context).clamp(0, paragraph.length);
    hits.add(
      NovelSearchHit(
        paragraph: paragraphIndex,
        start: at,
        end: end,
        snippet: paragraph.substring(winStart, winEnd).trim(),
        matchStart: at - winStart,
      ),
    );
    from = end;
  }
  return hits;
}

/// 分卷分组：连续同卷章节折叠成组（对标 Wenku8 NovelVolume 投影，调研 §2.3）。
/// 卷名为空/null 的章节归入无卷组。
List<({String? volume, List<NovelChapter> chapters})> groupChaptersByVolume(
  List<NovelChapter> chapters,
) {
  final out = <({String? volume, List<NovelChapter> chapters})>[];
  for (final chapter in chapters) {
    final volume = (chapter.volumeTitle == null || chapter.volumeTitle!.isEmpty)
        ? null
        : chapter.volumeTitle;
    if (out.isEmpty || out.last.volume != volume) {
      out.add((volume: volume, chapters: [chapter]));
    } else {
      out.last.chapters.add(chapter);
    }
  }
  return out;
}

/// 高亮文本片段：[ranges] 为段内绝对区间；[base] 为本段文本对应的
/// 段内起始偏移（分页片段是段落子串时用）。区间自动裁剪到可见部分。
InlineSpan buildHighlightedSpan(
  String text,
  TextStyle style,
  List<(int, int)> ranges, {
  int base = 0,
}) {
  if (ranges.isEmpty) return TextSpan(text: text, style: style);
  final highlight = style.copyWith(
    backgroundColor: const Color(0x55F5C242),
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final (s, e) in ranges) {
    final start = (s - base).clamp(0, text.length);
    final end = (e - base).clamp(0, text.length);
    if (end <= start || start < cursor) continue;
    if (start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, start), style: style));
    }
    spans.add(TextSpan(text: text.substring(start, end), style: highlight));
    cursor = end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }
  return TextSpan(children: spans, style: style);
}
