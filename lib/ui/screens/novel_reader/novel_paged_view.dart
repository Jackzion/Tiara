import 'package:flutter/material.dart';
import 'package:movies/services/novel/novel_pagination.dart';
import 'package:movies/ui/widgets/resilient_network_image.dart';

/// 横排分页视图：PageView 翻页 + 左右 1/3 点击翻页 + 中央点击回调。
///
/// 片段按引擎给出的 rect 精确定位（行边界装页，段落可跨页）；
/// 插图片段独占整页（一图一页，与滚动模式一致）。
class NovelPagedView extends StatefulWidget {
  const NovelPagedView({
    super.key,
    required this.pages,
    required this.paragraphs,
    required this.layout,
    required this.initialPage,
    required this.textColor,
    required this.onPageChanged,
    required this.onTapCenter,
  });

  final List<NovelPage> pages;
  final List<String> paragraphs;
  final NovelLayout layout;
  final int initialPage;
  final Color textColor;
  final ValueChanged<int> onPageChanged;

  /// 点击屏幕中央（chrome 显隐）
  final VoidCallback onTapCenter;

  @override
  State<NovelPagedView> createState() => _NovelPagedViewState();
}

class _NovelPagedViewState extends State<NovelPagedView> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapUp(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    if (dx <= width / 3) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else if (dx >= width * 2 / 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else {
      widget.onTapCenter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _onTapUp,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.pages.length,
        onPageChanged: widget.onPageChanged,
        itemBuilder: (context, index) => _buildPage(widget.pages[index]),
      ),
    );
  }

  Widget _buildPage(NovelPage page) {
    final style = TextStyle(
      fontSize: widget.layout.fontSize,
      height: widget.layout.lineHeight,
      letterSpacing: widget.layout.letterSpacing,
      color: widget.textColor,
    );
    return Center(
      child: SizedBox(
        width: widget.layout.width,
        height: widget.layout.height,
        child: Stack(
          children: [
            for (final fragment in page.fragments)
              Positioned.fromRect(
                rect: fragment.rect,
                child: fragment.isImage
                    ? _PageImage(url: fragment.url!)
                    : Text(
                        widget.paragraphs[fragment.paragraph]
                            .substring(fragment.start, fragment.end),
                        style: style,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 整页插图（一图一页；双路加载）
class _PageImage extends StatelessWidget {
  const _PageImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: ResilientNetworkImage(url, headers: wenku8ImageHeaders(url)),
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}
