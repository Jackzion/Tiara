import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/genre.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/ui/theme/theme.dart';

/// 动漫简介右栏组件
/// 参考 Bangumi 详情页右侧：章节按钮 + 简介 + 标签胶囊
/// 左侧海报与元信息由 AnimeDetail 布局提供
class AnimeOverview extends StatefulWidget {
  /// 动漫详情数据
  final AnimeDetails details;

  /// 兼容旧参数（新布局不再使用上移重叠）
  final double overlapHeight;

  /// 点章节:(1-based 集号) 回调
  final void Function(int episode)? onEpisodeTap;

  /// 点标签:(标签名称) 回调
  final void Function(Genre genre)? onTagTap;

  /// 「开始观看」等：不带集号
  final VoidCallback? onWatchTap;

  const AnimeOverview({
    super.key,
    required this.details,
    this.onEpisodeTap,
    this.onWatchTap,
    this.overlapHeight = 0,
    this.onTagTap,
  });

  @override
  State<AnimeOverview> createState() => _AnimeOverviewState();
}

class _AnimeOverviewState extends State<AnimeOverview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..forward();

  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

  bool _expandedChapters = false;
  bool _expandedTags = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final genres = details.genres ?? <Genre>[];
    final synopsis = details.synopsis ?? '';
    final synopsisLines = _splitSynopsis(synopsis);
    final episodes = details.isBook
        ? details.chapterCount ?? 0
        : details.episodes ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChapterHeader(),
        // 数字章节按钮仅在数量已知时渲染
        if (episodes > 0) ...[
          addVerticalSpace(12),
          _buildChapterButtons(episodes),
        ],
        addVerticalSpace(16),

        const Divider(height: 1, thickness: 1, color: dividerLine),
        addVerticalSpace(18),

        if (synopsisLines.isNotEmpty)
          for (final line in synopsisLines) ...[
            _DescText(line),
            addVerticalSpace(4),
          ],

        if (genres.isNotEmpty) ...[addVerticalSpace(14), _buildTagBox(genres)],
      ],
    );
  }

  Widget _buildChapterHeader() {
    final details = widget.details;
    // 与 build 同口径：书籍取 chapterCount
    final episodes = details.isBook
        ? details.chapterCount ?? 0
        : details.episodes ?? 0;
    final showToggle = episodes > 12;

    return Row(
      children: [
        Text(
          '章节列表',
          style: GoogleFonts.notoSansSc(fontSize: 15, color: textSoft),
        ),
        if (showToggle) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _expandedChapters = !_expandedChapters),
            child: Text(
              _expandedChapters ? '[收起]' : '[全部]',
              style: GoogleFonts.notoSansSc(fontSize: 15, color: accentAmber),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: widget.onWatchTap,
          child: Text(
            widget.details.isBook ? '开始阅读 ›' : '开始观看 ›',
            style: GoogleFonts.notoSansSc(fontSize: 15, color: accentAmber),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterButtons(int episodes) {
    final limit = _expandedChapters || episodes <= 12 ? episodes : 12;
    final shown = episodes.clamp(1, limit);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var n = 1; n <= shown; n++)
          _ChapterButton(
            label: _pad(n),
            onTap: () => widget.onEpisodeTap?.call(n),
          ),
      ],
    );
  }

  Widget _buildTagBox(List<Genre> genres) {
    const maxVisible = 12;
    final visible = _expandedTags || genres.length <= maxVisible
        ? genres
        : genres.sublist(0, maxVisible);
    final hasMore = genres.length > maxVisible;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: buttonGrey,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '大家将 ${widget.details.displayTitle} 标注为',
            style: GoogleFonts.notoSansSc(
              fontSize: 14,
              height: 1.95,
              color: posterBorder,
            ),
          ),
          addVerticalSpace(13),
          SlideTransition(
            position: _offsetAnimation,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final genre in visible)
                  _TagPill(
                    name: genre.name,
                    count: genre.count,
                    onTap: () => widget.onTagTap?.call(genre),
                  ),
                if (hasMore)
                  _TagPill(
                    onTap: () => setState(() => _expandedTags = !_expandedTags),
                    name: _expandedTags ? '收起' : '更多+',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _splitSynopsis(String synopsis) {
    final normalized = synopsis.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

/// 章节按钮
class _ChapterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChapterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accentAmberLight, accentAmber, accentAmberDeep],
              stops: [0.0, 0.52, 1.0],
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.notoSansSc(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 标签胶囊
class _TagPill extends StatelessWidget {
  final String name;
  final int? count;

  // 点击回调，可空
  final VoidCallback? onTap;

  const _TagPill({required this.name, this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: buttonGrey, // ← 背景色从 Container 挪到这里
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap, // ← 标签 tag 点击事件
        borderRadius: BorderRadius.circular(999), // 水波纹跟随胶囊圆角
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.notoSansSc(
                  fontSize: 13,
                  height: 1,
                  color: textSoft,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 11,
                    height: 1,
                    color: posterBorder,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 简介正文
class _DescText extends StatelessWidget {
  final String text;

  const _DescText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansSc(
        fontSize: 15,
        height: 2,
        letterSpacing: 0.3,
        color: posterBorder,
      ),
    );
  }
}
