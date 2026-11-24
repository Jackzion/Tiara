import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';

/// 目录条目：设计系统不认识小说/漫画的数据模型，调用方先投影成这个轻量结构。
@immutable
class ArchiveChapterEntry {
  const ArchiveChapterEntry({
    required this.id,
    required this.title,
    this.volumeTitle,
  });

  /// 章节标识（阅读器跳转与进度定位都以它为准）
  final String id;

  final String title;

  /// 分卷名：连续同卷的章节归为一组；空/null 表示不分卷
  final String? volumeTitle;
}

// 行高用于首帧定位（打开目录时直接滚到当前章），所以取固定值。
const double _chapterRowHeight = 42;
const double _chapterRowExtent = _chapterRowHeight + 1; // + 发丝线
const double _volumeRowHeight = 40;
const double _volumeGap = 14; // 卷与卷之间的留白
const double _catalogHeaderHeight = 37; // 34 表头 + 2 进度 + 1 线
const double _catalogListBottom = 8;
const double _gridGap = 12;

/// 按面板宽度决定列数：宽屏三列（参考目录页），中屏两列，窄屏单列。
int _columnsFor(double width) {
  if (width >= 600) return 3;
  if (width >= 420) return 2;
  return 1;
}

/// 档案式章节目录。
///
/// 分卷标题 + 虚线引导线，章节按可用宽度排 1–3 列；每章是
/// `CH.序号`（[ArchiveCode]）+ 章名，行间用 [ArchiveDivider] 分隔。
/// 当前章整格反白。章数多时目录在面板内滚动，首帧自动把当前章
/// 放到目录区中部；章数少时面板收成自然高度。
class ArchiveChapterList extends StatefulWidget {
  const ArchiveChapterList({
    super.key,
    required this.chapters,
    this.currentId,
    this.onTap,
    this.maxHeight = 360,
  });

  final List<ArchiveChapterEntry> chapters;

  /// 当前章 chapterId（不在目录里时不做高亮）
  final String? currentId;

  final ValueChanged<ArchiveChapterEntry>? onTap;

  /// 面板（表头 + 目录）的高度上限；超过时目录区在内部滚动，
  /// 章数少时按内容收成自然高度。
  final double maxHeight;

  @override
  State<ArchiveChapterList> createState() => _ArchiveChapterListState();
}

class _ArchiveChapterListState extends State<ArchiveChapterList> {
  ScrollController? _controller;
  bool _atEnd = false;
  bool _scrolled = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncScrollState() {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    final atEnd = position.pixels >= position.maxScrollExtent - 1;
    final scrolled = position.pixels > 0.5;
    if (atEnd != _atEnd || scrolled != _scrolled) {
      setState(() {
        _atEnd = atEnd;
        _scrolled = scrolled;
      });
    }
  }

  /// 列数依赖实际宽度，所以控制器在首次布局时创建，首帧就落在当前章。
  ScrollController _ensureController(List<_CatalogRow> rows) {
    final existing = _controller;
    if (existing != null) return existing;
    final start = _startOffset(rows);
    _scrolled = start > 0.5;
    _atEnd = start >= _maxOffset(rows) - 1;
    final controller = ScrollController(initialScrollOffset: start);
    controller.addListener(_syncScrollState);
    return _controller = controller;
  }

  /// 目录内容的可滚动上限。
  double _maxOffset(List<_CatalogRow> rows) {
    final content = rows.fold<double>(0, (sum, row) => sum + row.extent);
    final viewport = widget.maxHeight - _catalogHeaderHeight;
    return (content + _catalogListBottom - viewport)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  /// 当前章的起始偏移，上下各留一半目录高度作上下文。
  double _startOffset(List<_CatalogRow> rows) {
    final index = rows.indexWhere(
      (row) =>
          !row.isVolume && row.chapters.any((c) => c.id == widget.currentId),
    );
    if (index <= 0) return 0;

    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += rows[i].extent;
    }
    final viewport = widget.maxHeight - _catalogHeaderHeight;
    return (offset - viewport / 2).clamp(0.0, _maxOffset(rows)).toDouble();
  }

  String _pad(int value, [int width = 3]) =>
      value.toString().padLeft(width, '0');

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    if (widget.chapters.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final rows = _rowsOf(widget.chapters, columns);
        if (rows.isEmpty) return const SizedBox.shrink();
        final controller = _ensureController(rows);

        final content = rows.fold<double>(0, (sum, row) => sum + row.extent);
        final scrollable =
            content + _catalogListBottom >
            widget.maxHeight - _catalogHeaderHeight;
        // 章数少时收成自然高度，避免面板下半截留白。
        final panelHeight = math.min(
          widget.maxHeight,
          _catalogHeaderHeight + content + _catalogListBottom,
        );

        return PaperPanel(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: panelHeight,
            child: Column(
              children: [
                _buildHeader(tone, rows),
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.only(
                          bottom: _catalogListBottom,
                        ),
                        itemCount: rows.length,
                        itemBuilder: (context, index) =>
                            _buildRow(tone, rows, index, columns),
                      ),
                      if (_scrolled) _buildEdgeFade(tone, top: true),
                      if (scrollable && !_atEnd)
                        _buildEdgeFade(tone, top: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 表头：CATALOG / 进度码 + 2px 墨线进度条。
  Widget _buildHeader(ArchiveTone tone, List<_CatalogRow> rows) {
    final total = rows.fold<int>(0, (sum, row) => sum + row.chapters.length);
    int? current;
    for (final row in rows) {
      for (var i = 0; i < row.chapters.length; i++) {
        if (row.chapters[i].id == widget.currentId) {
          current = row.firstNumber + i;
          break;
        }
      }
      if (current != null) break;
    }
    final code = current == null
        ? '${_pad(total)} CH'
        : '${_pad(current)} / ${_pad(total)}';
    final ratio = current == null || total == 0
        ? 0.0
        : (current / total).clamp(0.0, 1.0);

    return SizedBox(
      height: _catalogHeaderHeight,
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const ArchiveCode('CATALOG'),
                  const Spacer(),
                  ArchiveCode(code),
                ],
              ),
            ),
          ),
          Container(
            height: 2,
            color: tone.raised,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              heightFactor: 1,
              child: ColoredBox(color: tone.ink),
            ),
          ),
          const ArchiveDivider(),
        ],
      ),
    );
  }

  Widget _buildRow(
    ArchiveTone tone,
    List<_CatalogRow> rows,
    int index,
    int columns,
  ) {
    final row = rows[index];
    return row.isVolume
        ? _buildVolumeRow(tone, row)
        : _buildChapterRow(tone, row, index == rows.length - 1, columns);
  }

  /// 分卷标题：方块 + VOL.序号 + 卷名 + 虚线引导线 + 本卷章数。
  Widget _buildVolumeRow(ArchiveTone tone, _CatalogRow row) {
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(top: row.topGap),
        child: SizedBox(
          height: _volumeRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxTitle = math.max(72.0, constraints.maxWidth * 0.34);
                return Row(
                  children: [
                    SizedBox(
                      width: 4,
                      height: 4,
                      child: ColoredBox(color: tone.ink),
                    ),
                    const SizedBox(width: 10),
                    ArchiveCode(
                      'VOL.${_pad(row.volumeIndex, 2)}',
                      color: tone.muted,
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxTitle),
                      child: Text(
                        row.volume!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArchiveType.micro.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          height: 1.2,
                          color: tone.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _DashedRule(color: tone.hairlineStrong)),
                    const SizedBox(width: 12),
                    ArchiveCode('${row.volumeCount} CH', color: tone.muted),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 章节行：按列切分的格子 + 行底发丝线。
  Widget _buildChapterRow(
    ArchiveTone tone,
    _CatalogRow row,
    bool last,
    int columns,
  ) {
    final cells = <Widget>[];
    for (var i = 0; i < columns; i++) {
      if (i > 0) cells.add(const SizedBox(width: _gridGap));
      cells.add(
        Expanded(
          child: i < row.chapters.length
              ? _buildCell(tone, row.chapters[i], row.firstNumber + i)
              : const SizedBox.shrink(),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: _chapterRowHeight,
          child: Row(children: cells),
        ),
        if (!last)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: ArchiveDivider(indent: 12),
          ),
      ],
    );
  }

  /// 单个章节：`CH.序号` + 章名；当前章整格反白。
  Widget _buildCell(ArchiveTone tone, ArchiveChapterEntry chapter, int number) {
    final isCurrent = chapter.id == widget.currentId;
    final onTap = widget.onTap == null ? null : () => widget.onTap!(chapter);
    final radius = BorderRadius.circular(ArchiveGeometry.coverRadius);

    return Semantics(
      button: onTap != null,
      selected: isCurrent,
      child: Material(
        color: isCurrent ? tone.ink : Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: isCurrent
              ? Colors.white.withValues(alpha: 0.08)
              : tone.raisedHigh,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: ArchiveCode(
                    'CH.${_pad(number)}',
                    color: isCurrent ? tone.milk : tone.muted,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: chapter.title,
                    waitDuration: const Duration(milliseconds: 700),
                    child: Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArchiveType.body.copyWith(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCurrent
                            ? tone.surface
                            : tone.ink.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 上下渐隐：上面还有被裁掉的半行 / 下面还有章节时提示可继续滚动。
  Widget _buildEdgeFade(ArchiveTone tone, {required bool top}) {
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      height: 24,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: top
                  ? [tone.surface, tone.surface.withValues(alpha: 0)]
                  : [tone.surface.withValues(alpha: 0), tone.surface],
            ),
          ),
        ),
      ),
    );
  }
}

/// 目录拉取中的骨架占位：与 [ArchiveChapterList] 同表头、同卷带、同格高，
/// 加载完成后高度基本不变，详情页不跳。
class ArchiveChapterListSkeleton extends StatelessWidget {
  const ArchiveChapterListSkeleton({super.key, this.height = 360});

  final double height;

  static const _titleWidths = [0.62, 0.78, 0.5, 0.7, 0.84, 0.58];

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);

    Widget bar(double width, {double height = 8}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tone.raised,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final rowCount = math.max(
          1,
          ((height - _catalogHeaderHeight - _volumeRowHeight) /
                  _chapterRowExtent)
              .floor(),
        );

        final cells = <Widget>[];
        for (var i = 0; i < columns; i++) {
          if (i > 0) cells.add(const SizedBox(width: _gridGap));
          cells.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    bar(36),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _titleWidths[i % _titleWidths.length],
                        child: bar(double.infinity),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return PaperPanel(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                SizedBox(
                  height: _catalogHeaderHeight,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 34,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const ArchiveCode('CATALOG'),
                              const Spacer(),
                              ArchiveCode('LOADING', color: tone.muted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                      const ArchiveDivider(),
                    ],
                  ),
                ),
                SizedBox(
                  height: _volumeRowHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        bar(4, height: 4),
                        const SizedBox(width: 10),
                        bar(40),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: bar(72),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _DashedRule(color: tone.hairlineStrong),
                        ),
                        const SizedBox(width: 12),
                        bar(28),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < rowCount; i++) ...[
                        SizedBox(
                          height: _chapterRowHeight,
                          child: Row(children: cells),
                        ),
                        if (i < rowCount - 1)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: ArchiveDivider(indent: 12),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 目录行：分卷标题（chapters 为空）或一行章节（1–3 格）。
class _CatalogRow {
  const _CatalogRow.volume({
    required this.volume,
    required this.volumeIndex,
    required this.volumeCount,
    required this.topGap,
  }) : chapters = const [],
       firstNumber = 0;

  const _CatalogRow.chapters({
    required this.chapters,
    required this.firstNumber,
  }) : volume = null,
       volumeIndex = 0,
       volumeCount = 0,
       topGap = 0;

  final String? volume;
  final int volumeIndex;
  final int volumeCount;
  final List<ArchiveChapterEntry> chapters;

  /// 本行第一格的章号（1 起，跨卷连续）
  final int firstNumber;
  final double topGap;

  bool get isVolume => volume != null;

  double get extent => isVolume ? _volumeRowHeight + topGap : _chapterRowExtent;
}

/// 把章节按分卷和列数切成目录行（连续同卷合并，与阅读器侧栏同规则）。
List<_CatalogRow> _rowsOf(List<ArchiveChapterEntry> chapters, int columns) {
  final rows = <_CatalogRow>[];
  var number = 0;
  var volumeIndex = 0;
  var start = 0;
  var firstVolume = true;
  while (start < chapters.length) {
    final rawVolume = chapters[start].volumeTitle?.trim() ?? '';
    var end = start;
    while (end < chapters.length &&
        (chapters[end].volumeTitle?.trim() ?? '') == rawVolume) {
      end++;
    }
    if (rawVolume.isNotEmpty) {
      volumeIndex++;
      rows.add(
        _CatalogRow.volume(
          volume: rawVolume,
          volumeIndex: volumeIndex,
          volumeCount: end - start,
          topGap: firstVolume ? 0 : _volumeGap,
        ),
      );
      firstVolume = false;
    }
    for (var i = start; i < end; i += columns) {
      final chunk = chapters.sublist(i, math.min(i + columns, end));
      rows.add(_CatalogRow.chapters(chapters: chunk, firstNumber: number + 1));
      number += chunk.length;
    }
    start = end;
  }
  return rows;
}

/// 分卷标题右侧的虚线引导线。
class _DashedRule extends StatelessWidget {
  const _DashedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        size: Size.infinite,
        painter: _DashedRulePainter(color: color),
      ),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter({required this.color});

  static const double _dash = 4;
  static const double _gap = 4;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = ArchiveGeometry.hairlineWidth
      ..style = PaintingStyle.stroke;
    final step = _dash + _gap;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset(math.min(x + _dash, size.width), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRulePainter oldDelegate) =>
      color != oldDelegate.color;
}
