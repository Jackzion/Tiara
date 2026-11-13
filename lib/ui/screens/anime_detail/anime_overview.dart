import 'package:flutter/material.dart';
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

class _AnimeOverviewState extends State<AnimeOverview> {
  bool _expandedChapters = false;
  bool _expandedTags = false;

  String _pad(int n) => n.toString().padLeft(2, '0');

  int get _episodes => widget.details.isBook
      ? widget.details.chapterCount ?? 0
      : widget.details.episodes ?? 0;

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final genres = details.genres ?? <Genre>[];
    final synopsisLines = _splitSynopsis(details.synopsis ?? '');
    final episodes = _episodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (synopsisLines.isNotEmpty) ...[
          const ArchiveSection(title: '剧情简介', code: '01 / SYNOPSIS'),
          const SizedBox(height: 12),
          for (final line in synopsisLines) ...[
            _DescText(line),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
        ],
        ArchiveSection(
          title: '章节',
          code: '02 / CHAPTERS',
          trailing: ArchivePillButton(
            label: details.isBook ? '开始阅读' : '开始观看',
            icon: Icons.play_arrow_rounded,
            height: 40,
            onPressed: widget.onWatchTap,
          ),
        ),
        const SizedBox(height: 14),
        if (episodes > 0) _buildChapterButtons(episodes),
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 28),
          const ArchiveSection(title: '标签', code: '03 / TAGS'),
          const SizedBox(height: 12),
          _buildTagBox(genres),
        ],
      ],
    );
  }

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
    const maxVisible = 16;
    final visible = _expandedTags || genres.length <= maxVisible
        ? genres
        : genres.sublist(0, maxVisible);
    final hasMore = genres.length > maxVisible;
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
              if (hasMore)
                _TagPill(
                  onTap: () => setState(() => _expandedTags = !_expandedTags),
                  name: _expandedTags ? '收起' : '更多 +',
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

/// 章节号：纸底 mono 编号，悬停变深，没有渐变与投影。
class _ChapterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChapterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return SizedBox(
      width: 40,
      height: 30,
      child: Material(
        color: tone.milk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
          side: BorderSide(
            color: tone.hairline,
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
                color: tone.ink,
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
