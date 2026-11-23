import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// 段落内插图 URL 提取：取**第一对** `<!--image-->…<!--image-->` 标记。
/// 多图连排的段落由上游切分为多段；这里防御性只取首个。
String? novelImageUrlOf(String paragraph) {
  const marker = '<!--image-->';
  if (!paragraph.startsWith(marker)) return null;
  final end = paragraph.indexOf(marker, marker.length);
  if (end < 0) return null;
  return paragraph.substring(marker.length, end).trim();
}

/// 版面参数：一次排版测量的缓存键（任一字段变化即整体重排）。
class NovelLayout {
  const NovelLayout({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.lineHeight,
    this.letterSpacing = 0,
    this.paragraphGap = 0,
  });

  /// 正文区尺寸（已扣除边距/上下留白）
  final double width;
  final double height;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;

  /// 段间距（不含首段前）
  final double paragraphGap;

  @override
  bool operator ==(Object other) =>
      other is NovelLayout &&
      other.width == width &&
      other.height == height &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.letterSpacing == letterSpacing &&
      other.paragraphGap == paragraphGap;

  @override
  int get hashCode =>
      Object.hash(width, height, fontSize, lineHeight, letterSpacing, paragraphGap);
}

/// 页内片段：段落的一段连续行（行边界对齐，绝不切行），或一张整页插图。
class NovelFragment {
  const NovelFragment.text({
    required this.paragraph,
    required this.start,
    required this.end,
    required this.rect,
  }) : url = null;

  const NovelFragment.image({
    required this.paragraph,
    required this.url,
    required this.rect,
  })  : start = 0,
        end = 0;

  /// 所属段落下标（进度/恢复锚点）
  final int paragraph;

  /// 段内字符区间 [start, end)（仅文本片段）
  final int start;
  final int end;

  /// 片段在页内的位置与行高合计
  final Rect rect;

  /// 插图片段（独占一页）
  final String? url;
  bool get isImage => url != null;
}

/// 一页：若干行片段，或单张插图。
class NovelPage {
  const NovelPage(this.fragments, {required this.firstParagraph});

  final List<NovelFragment> fragments;
  final int firstParagraph;

  bool get isImage => fragments.length == 1 && fragments.first.isImage;
}

/// 分页引擎（对标 Wenku8 paginateReader 的简化版，调研 §1.2）：
///
/// - 每段 shape 一次（ui.Paragraph），行区间用 getLineBoundary 迭代取；
/// - 按行装页：行边界处换页，**段落可跨页**；
/// - 插图段独占整页；
/// - 测量缓存：同 (段落, 版面) 只 shape 一次，换字号重排时只重装页；
/// - 4ms 分块让出 + 取消令牌，大章节不卡 UI。
class NovelPagination {
  /// (段落下标, 版面) → 测量结果。淘汰不影响结果（测量是确定性的）。
  final Map<(int, NovelLayout), _ParagraphMeasure> _measures = {};

  /// 分页主入口；[cancelled] 返回 true 时中止并返回 null。
  Future<List<NovelPage>?> paginate(
    List<String> paragraphs,
    NovelLayout layout, {
    bool Function()? cancelled,
  }) async {
    final pages = <NovelPage>[];
    var current = <NovelFragment>[];
    var firstParagraph = 0;
    var y = 0.0;
    final stopwatch = Stopwatch()..start();

    void flush() {
      if (current.isEmpty) return;
      pages.add(
        NovelPage(List.unmodifiable(current), firstParagraph: firstParagraph),
      );
      current = [];
      y = 0;
    }

    for (var i = 0; i < paragraphs.length; i++) {
      if (cancelled?.call() ?? false) return null;
      // 4ms 分块让出，避免大章节卡死 UI
      if (stopwatch.elapsedMilliseconds >= 4) {
        await Future<void>.delayed(Duration.zero);
        stopwatch.reset();
        if (cancelled?.call() ?? false) return null;
      }

      final paragraph = paragraphs[i];
      final imageUrl = novelImageUrlOf(paragraph);
      if (imageUrl != null) {
        flush();
        pages.add(
          NovelPage(
            [
              NovelFragment.image(
                paragraph: i,
                url: imageUrl,
                rect: Rect.fromLTWH(0, 0, layout.width, layout.height),
              ),
            ],
            firstParagraph: i,
          ),
        );
        continue;
      }

      final measure = _measures.putIfAbsent(
        (i, layout),
        () => _measure(paragraph, layout),
      );
      for (final line in measure.lines) {
        // 行边界处换页；行永远不被切开
        if (y + line.height > layout.height && current.isNotEmpty) {
          flush();
        }
        if (current.isEmpty) firstParagraph = i;
        current.add(
          NovelFragment.text(
            paragraph: i,
            start: line.start,
            end: line.end,
            rect: Rect.fromLTWH(line.left, y, line.width, line.height),
          ),
        );
        y += line.height;
      }
      y += layout.paragraphGap;
    }
    flush();
    return pages;
  }

  /// shape 一次：行区间 + 行几何。
  _ParagraphMeasure _measure(String text, NovelLayout layout) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
    )
      ..pushStyle(
        ui.TextStyle(
          fontSize: layout.fontSize,
          height: layout.lineHeight,
          letterSpacing: layout.letterSpacing,
        ),
      )
      ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: layout.width));

    // 行区间：getLineBoundary 迭代（起始于行首、终止于行尾）
    final ranges = <(int, int)>[];
    var cur = 0;
    while (cur < text.length) {
      final r = paragraph.getLineBoundary(ui.TextPosition(offset: cur));
      if (r.end <= cur) break;
      ranges.add((r.start, r.end));
      cur = r.end;
    }

    final metrics = paragraph.computeLineMetrics();
    // 区间与 metrics 数量不一致时退化为整段单行（防御，正常不会发生）
    if (ranges.length != metrics.length) {
      return _ParagraphMeasure([
        _LineMeasure(0, text.length, 0, layout.width, metrics.fold<double>(0, (s, m) => s + m.height)),
      ]);
    }
    return _ParagraphMeasure([
      for (var i = 0; i < ranges.length; i++)
        _LineMeasure(
          ranges[i].$1,
          ranges[i].$2,
          metrics[i].left,
          metrics[i].width,
          metrics[i].height,
        ),
    ]);
  }
}

class _ParagraphMeasure {
  const _ParagraphMeasure(this.lines);
  final List<_LineMeasure> lines;
}

class _LineMeasure {
  const _LineMeasure(this.start, this.end, this.left, this.width, this.height);
  final int start;
  final int end;
  final double left;
  final double width;
  final double height;
}
