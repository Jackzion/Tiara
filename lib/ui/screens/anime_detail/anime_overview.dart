import 'package:flutter/material.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/database/models/rules_model.dart';
import 'package:movies/data/library/library_codec.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/genre.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';

/// 详情页右栏：剧情简介 → 章节 → 标签，三段档案索引。
class AnimeOverview extends StatefulWidget {
  final AnimeDetails details;

  /// 兼容旧参数（新布局不再使用上移重叠）
  final double overlapHeight;

  /// 点章节:(1-based 集号) 回调
  final void Function(int episode)? onEpisodeTap;

  /// 点标签:(标签名称) 回调
  final void Function(Genre genre)? onTagTap;

  /// 「开始观看」等：不带集号
  final VoidCallback? onWatchTap;

  /// 本地书库里的续看信息（没有则为 null）
  final LibraryResume? resume;

  /// 续看：有存下来的上下文时，标题按钮变成「继续观看/继续阅读」
  final VoidCallback? onResume;

  /// 宽屏两栏时为 true：
  final bool fillHeight;

  /// 简介滚动框的高度（仅 [fillHeight] 生效），约五行正文。
  final double synopsisHeight;

  const AnimeOverview({
    super.key,
    required this.details,
    this.onEpisodeTap,
    this.onWatchTap,
    this.overlapHeight = 0,
    this.onTagTap,
    this.resume,
    this.onResume,
    this.fillHeight = false,
    this.synopsisHeight = 150,
  });

  @override
  State<AnimeOverview> createState() => _AnimeOverviewState();
}

class _AnimeOverviewState extends State<AnimeOverview> {
  bool _expandedChapters = false;
  bool _expandedTags = false;

  String _pad(int n) => n.toString().padLeft(2, '0');

  int get _episodes => widget.details.isBook
      ? widget.details.chapterCount ?? 0
      : widget.details.episodes ?? 0;

  /// 有续看数据时用存下来的线路替换 bangumi 的集数：
  /// 这样章节格子和实际可播放的分集一一对应，而不是 bangumi 的条目集数。
  List<Road> get _resumeRoads => decodeRoads(widget.resume?.roadsJson);

  int get _resumeEpisodeCount {
    final roads = _resumeRoads;
    if (roads.isEmpty) return 0;
    final index = (widget.resume?.lastRoadIndex ?? 0).clamp(
      0,
      roads.length - 1,
    );
    return roads[index].data.length;
  }

  bool get _hasResume =>
      widget.resume != null &&
      (widget.resume!.lastEpisode != null ||
          (widget.resume!.lastUnitId?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final genres = details.genres ?? <Genre>[];
    final synopsisLines = _splitSynopsis(details.synopsis ?? '');
    // 有本地线路时以线路集数为准，否则用 bangumi 的
    final resumeCount = _resumeEpisodeCount;
    final episodes = resumeCount > 0 ? resumeCount : _episodes;

    final synopsisChars = synopsisLines.fold<int>(0, (sum, line) => sum + line.length);

    Widget synopsisBody() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in synopsisLines) ...[
          _DescText(line),
          const SizedBox(height: 10),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (synopsisLines.isNotEmpty) ...[
          const ArchiveSection(title: '剧情简介', code: '01 / SYNOPSIS'),
          const SizedBox(height: 12),
          // 只有剧情简介自己有滚动框：内容长就在块内滚，页面不被拉长。
          // 短简介不套框，避免留出一片空白。
          if (widget.fillHeight && synopsisChars > 200)
            SizedBox(
              height: widget.synopsisHeight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 8),
                child: synopsisBody(),
              ),
            )
          else
            synopsisBody(),
          const SizedBox(height: 18),
        ],
        ArchiveSection(
          title: '章节',
          code: '02 / CHAPTERS',
          trailing: ArchivePillButton(
            label: _hasResume
                ? (details.isBook ? '继续阅读' : '继续观看')
                : (details.isBook ? '开始阅读' : '开始观看'),
            icon: Icons.play_arrow_rounded,
            height: 40,
            onPressed: _hasResume && widget.onResume != null
                ? widget.onResume
                : widget.onWatchTap,
          ),
        ),
        if (_hasResume) ...[
          const SizedBox(height: 8),
          // 档案式的一行：上次看到哪（漫画显示话名，动画显示第 N 集）
          ArchiveCode(
            'LAST / ${widget.resume!.progressLabel}',
            color: ArchivePalette.ink,
          ),
        ],
        const SizedBox(height: 14),
        if (episodes > 0) _buildChapterButtons(episodes),
        if (genres.isNotEmpty) ...[
          // 宽屏：标签被推到栏底，与左栏元信息共底
          if (widget.fillHeight) const Spacer() else const SizedBox(height: 28),
          ArchiveSection(
            title: '标签',
            code: '03 / TAGS',
            // 标签过多时只留一个小折叠图标；展开只是在滚动框内变长，
            // 不会改变页面高度，两栏底边始终对齐。
            trailing: genres.length > _tagPageSize
                ? _ExpandIcon(
                    expanded: _expandedTags,
                    onTap: () => setState(() => _expandedTags = !_expandedTags),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          _buildTagBox(genres),
        ],
      ],
    );
  }

  /// 折叠时显示的标签数
  static const _tagPageSize = 12;

  Widget _buildChapterButtons(int episodes) {
    final limit = _expandedChapters || episodes <= 24 ? episodes : 24;
    final shown = episodes.clamp(1, limit);
    final tone = ArchiveTone.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var n = 1; n <= shown; n++)
          _ChapterChip(
            label: _pad(n),
            // 上次看到的那一集用墨底标出来
            highlight: n == widget.resume?.lastEpisode,
            onTap: () => widget.onEpisodeTap?.call(n),
          ),
        if (episodes > limit)
          ArchiveTextButton(
            onPressed: () =>
                setState(() => _expandedChapters = !_expandedChapters),
            child: Text(
              '还有 ${episodes - limit} 话',
              style: ArchiveType.micro.copyWith(color: tone.muted),
            ),
          ),
      ],
    );
  }

  Widget _buildTagBox(List<Genre> genres) {
    final visible = _expandedTags || genres.length <= _tagPageSize
        ? genres
        : genres.sublist(0, _tagPageSize);
    final tone = ArchiveTone.of(context);

    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '大家将「${widget.details.displayTitle}」标注为',
            style: ArchiveType.meta.copyWith(color: tone.muted),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final genre in visible)
                _TagPill(
                  name: genre.name,
                  count: genre.count,
                  onTap: () => widget.onTagTap?.call(genre),
                ),
            ],
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

/// 区块头右侧的小折叠图标：展开 / 收起剩余的标签。
class _ExpandIcon extends StatelessWidget {
  const _ExpandIcon({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Semantics(
      button: true,
      label: expanded ? '收起标签' : '展开全部标签',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tone.milk,
              borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
              border: Border.all(
                color: tone.hairline,
                width: ArchiveGeometry.hairlineWidth,
              ),
            ),
            child: Icon(
              expanded ? Icons.unfold_less : Icons.unfold_more,
              size: 16,
              color: tone.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// 章节号：纸底 mono 编号，悬停变深，没有渐变与投影。
/// [highlight] 为 true 时用墨底奶白字标出「上次看到」的那一集。
class _ChapterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _ChapterChip({
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return SizedBox(
      width: 40,
      height: 30,
      child: Material(
        color: highlight ? tone.ink : tone.milk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
          side: BorderSide(
            color: highlight ? tone.ink : tone.hairline,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: tone.raisedHigh,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Center(
            child: Text(
              label,
              style: ArchiveType.code.copyWith(
                fontSize: 11,
                color: highlight ? tone.milk : tone.ink,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 标签胶囊：纸底 + 发丝线，计数用 mono。
class _TagPill extends StatelessWidget {
  final String name;
  final int? count;
  final VoidCallback? onTap;

  const _TagPill({required this.name, this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Material(
      color: tone.surface,
      borderRadius: BorderRadius.circular(ArchiveGeometry.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ArchiveGeometry.pillRadius),
        hoverColor: tone.raisedHigh,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ArchiveGeometry.pillRadius),
            border: Border.all(
              color: tone.hairline,
              width: ArchiveGeometry.hairlineWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: ArchiveType.micro.copyWith(
                  fontSize: 12,
                  color: tone.ink,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: ArchiveType.code.copyWith(
                    color: tone.muted,
                    letterSpacing: 0.3,
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

/// 简介正文：14 / 1.9，墨色，段间 10。
class _DescText extends StatelessWidget {
  final String text;

  const _DescText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ArchiveType.bodyRegular.copyWith(
        height: 1.9,
        letterSpacing: 0.2,
        color: ArchiveTone.of(context).ink,
      ),
    );
  }
}
