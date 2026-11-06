import 'package:flutter/material.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/ui/widgets/anime_widget.dart';
import 'package:movies/utils/utils.dart';

/// 动漫卡片网格组件
/// 每屏默认展示 [itemCount] 张卡片，按窗口宽度自适应列数并自动分行
/// 悬停时卡片扩到 2 列宽，横幅等比放大并盖住相邻卡片
class HorizontalAnimes extends StatefulWidget {
  /// 动漫列表数据
  final List<Anime> animes;

  /// 点击回调函数
  final OnAnimeTap onAnimeTap;

  /// 动漫类型，用于生成唯一的 Hero 动画标签
  final AnimeType animeType;

  /// 展示的卡片数量（默认 12，按窗口宽度自动分行）
  final int itemCount;

  const HorizontalAnimes({
    required this.onAnimeTap,
    required this.animes,
    required this.animeType,
    this.itemCount = 12,
    super.key,
  });

  @override
  State<HorizontalAnimes> createState() => _HorizontalAnimesState();
}

class _HorizontalAnimesState extends State<HorizontalAnimes> {
  /// 当前悬停的卡片下标（全局，跨行互斥）
  int? hoverIndex;

  static const gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final items = widget.animes.take(widget.itemCount).toList();
          if (items.isEmpty) {
            return const SizedBox.shrink();
          }
          final contentWidth = constraints.maxWidth;
          final columns = columnsForWidth(contentWidth);
          final rows = (items.length / columns).ceil();
          final cellWidth = (contentWidth - gap * (columns - 1)) / columns;
          final cellHeight = posterHeightFor(cellWidth);
          final expandedWidth = cellWidth * 2;

          return Column(
            children: [
              for (var row = 0; row < rows; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: buildRow(
                    row: row,
                    columns: columns,
                    items: items,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
                    expandedWidth: expandedWidth,
                    contentWidth: contentWidth,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 单行：等宽卡片网格；悬停项扩到 2 列宽并提到最上层
  Widget buildRow({
    required int row,
    required int columns,
    required List<Anime> items,
    required double cellWidth,
    required double cellHeight,
    required double expandedWidth,
    required double contentWidth,
  }) {
    final rowStart = row * columns;
    final hover = hoverIndex;
    final hoverCol = (hover != null && hover >= rowStart && hover < rowStart + columns)
        ? hover - rowStart
        : null;

    final slots = <Widget>[];
    for (var col = 0; col < columns; col++) {
      final index = rowStart + col;
      if (index >= items.length) continue;
      final isHovered = hoverCol == col;
      slots.add(
        buildCell(
          index: index,
          anime: items[index],
          col: col,
          columns: columns,
          expanded: isHovered,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          expandedWidth: expandedWidth,
          contentWidth: contentWidth,
        ),
      );
    }

    // 悬停项最后绘制，保证盖住邻居时能收到指针事件
    if (hoverCol != null && hoverCol < slots.length) {
      final hovered = slots.removeAt(hoverCol);
      slots.add(hovered);
    }

    return SizedBox(
      height: cellHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: slots,
      ),
    );
  }

  /// 单元格：默认占 1 列；展开时宽度变为 2 列并向邻列伸展
  Widget buildCell({
    required int index,
    required Anime anime,
    required int col,
    required int columns,
    required bool expanded,
    required double cellWidth,
    required double cellHeight,
    required double expandedWidth,
    required double contentWidth,
  }) {
    final slotLeft = col * (cellWidth + gap);
    final width = expanded ? expandedWidth : cellWidth;
    final height = expanded ? bannerHeightFor(expandedWidth) : cellHeight;
    // 首列向右扩、末列向左扩、中间列居中，避免超出网格边界
    final double left;
    if (expanded) {
      if (col == 0) {
        left = 0;
      } else if (col == columns - 1) {
        left = contentWidth - expandedWidth;
      } else {
        left = slotLeft - (expandedWidth - cellWidth) / 2;
      }
    } else {
      left = slotLeft;
    }

    return AnimatedPositioned(
      duration: morphDuration,
      curve: Curves.easeOutCubic,
      left: left,
      top: 0,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hoverIndex = index),
        onExit: (_) => setState(() {
          if (hoverIndex == index) hoverIndex = null;
        }),
        child: RepaintBoundary(
          child: AnimeWidget(
            anime: anime,
            onAnimeTap: widget.onAnimeTap,
            animeType: widget.animeType,
            expanded: expanded,
          ),
        ),
      ),
    );
  }

  /// 根据可用宽度决定列数（列数取 12 的约数，保证行内满排不留空位）
  int columnsForWidth(double width) {
    if (width >= 1200) return 6;
    if (width >= 1000) return 4;
    if (width >= 650) return 3;
    return 2;
  }
}
