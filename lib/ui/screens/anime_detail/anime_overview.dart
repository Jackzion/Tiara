import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:movies/data/models/genre.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_chapter_list.dart';
import 'package:movies/ui/widgets/archive/archive_synopsis_block.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';

/// 详情页右栏：剧情简介 → 章节 → 标签，三段档案索引。
class AnimeOverview extends ConsumerStatefulWidget {
  final AnimeDetails details;

  /// 兼容旧参数（新布局不再使用上移重叠）
  final double overlapHeight;

  /// 点章节:(1-based 集号) 回调
  final void Function(int episode)? onEpisodeTap;

  /// 点标签:(标签名称) 回调
  final void Function(Genre genre)? onTagTap;

  /// 「开始观看」等：不带集号
  final VoidCallback? onWatchTap;

  /// 漫画：点目录里的某一话（epId）直接进阅读器（resume 存在时可用）
  final void Function(LibraryResume resume, String epId)? onComicEpisodeTap;

  /// 小说：点章直接进阅读器（resume 存在时可用）
  final void Function(NovelChapter chapter)? onNovelChapterTap;

  /// 本地书库里的续看信息（没有则为 null）
  final LibraryResume? resume;

  /// 续看：有存下来的上下文时，标题按钮变成「继续观看/继续阅读」
  final VoidCallback? onResume;

  /// 宽屏两栏时为 true：
  final bool fillHeight;

  /// the height of the body area in the folded state of the block
  final double synopsisHeight;

  const AnimeOverview({
    super.key,
    required this.details,
    this.onEpisodeTap,
    this.onWatchTap,
    this.onComicEpisodeTap,
    this.onNovelChapterTap,
    this.overlapHeight = 0,
    this.onTagTap,
    this.resume,
    this.onResume,
    this.fillHeight = false,
    this.synopsisHeight = 130,
  });

  @override
  ConsumerState<AnimeOverview> createState() => _AnimeOverviewState();
}

class _AnimeOverviewState extends ConsumerState<AnimeOverview> {
  bool _expandedTags = false;

  bool get _hasResume =>
      widget.resume != null &&
      (widget.resume!.lastEpisode != null ||
          (widget.resume!.lastUnitId?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final genres = details.genres ?? <Genre>[];
    final resume = widget.resume;
    final synopsisLines = _splitSynopsis(details.synopsis ?? '');

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
      // 自然高度：IntrinsicHeight 两栏结构按最高者定高，右栏不再定高约束
      mainAxisSize: MainAxisSize.min,
      children: [
        if (synopsisLines.isNotEmpty) ...[
          // 档案式简介区块：长内容折叠+底部渐隐，点击展开为 Stack 浮层
          ArchiveSynopsisBlock(
            code: '01 / SYNOPSIS',
            title: '剧情简介',
            collapsedHeight: widget.synopsisHeight,
            child: synopsisBody(),
          ),
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
        if (resume != null && resume.isComic) ...[
          ArchiveSynopsisBlock(
            code: 'CATALOG',
            title: '漫画章节',
            collapsedHeight: 200,
            child: _buildComicChapterList(resume),
          ),
        ],
        if (resume != null && resume.isNovel)
          ArchiveSynopsisBlock(
            code: 'CATALOG',
            title: '小说章节',
            collapsedHeight: 200,
            child: _buildNovelChapterList(resume),
          ),

        if (genres.isNotEmpty) ...[
          const SizedBox(height: 28),
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

  /// 小说目录 Future（按 source 惰性取一次）
  Future<List<NovelChapter>>? _novelChaptersFuture;

  /// 漫画目录 Future（按 source 惰性取一次）
  Future<List<ComicChapter>>? _comicChaptersFuture;

  /// 上面那份 Future 对应的 source|comicId，变了就要重拉（换源/首次为空）
  String? _comicChaptersKey;

  Future<List<NovelChapter>> _loadNovelChapters(LibraryResume resume) async {
    final sourceKey = resume.sourceKey;
    final bookId = resume.remoteId;
    if (sourceKey == null || bookId == null) return const [];
    try {
      final detail = await ref
          .read(novelRepositoryProvider)
          .loadInfo(sourceKey, bookId);
      return detail.chapters;
    } catch (_) {
      // 目录拉取失败不阻塞页面（显示为空）
      return const [];
    }
  }

  Future<List<ComicChapter>> _loadComicChapters(LibraryResume resume) async {
    final sourceKey = resume.sourceKey;
    final comicId = resume.remoteId;
    if (sourceKey == null || comicId == null) {
      throw StateError('缺少图源上下文（sourceKey / comicId）');
    }
    final repo = await ref.read(comicRepositoryProvider.future);
    try {
      return await repo.loadChapters(sourceKey, comicId);
    } catch (e) {
      // 规则没装（sources[key] 空指针）/ 210 限频 / 网络失败都落到这里，
      // 交给 FutureBuilder 显示，不再静默变成空列表
      throw StateError('目录加载失败：$e');
    }
  }

  /// 清掉缓存的目录 Future，让下一帧重新拉（错误重试用）
  void _retryComicChapters() {
    setState(() {
      _comicChaptersKey = null;
      _comicChaptersFuture = null;
    });
  }

  /// comic 章节区：目录来自 comic source
  Widget _buildComicChapterList(LibraryResume resume) {
    final key = '${resume.sourceKey}|${resume.remoteId}';
    if (_comicChaptersKey != key) {
      _comicChaptersKey = key;
      _comicChaptersFuture = _loadComicChapters(resume);
    }
    return FutureBuilder<List<ComicChapter>>(
      future: _comicChaptersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ChapterLoadError(
            message: '目录加载失败 · 检查图源规则',
            onRetry: _retryComicChapters,
          );
        }
        if (!snapshot.hasData) {
          return ArchiveChapterListSkeleton(
            height: widget.fillHeight ? 380 : 320,
          );
        }
        final chapters = snapshot.data!;
        if (chapters.isEmpty) {
          return _ChapterLoadError(
            message: '目录为空 · 该图源没有返回章节',
            onRetry: _retryComicChapters,
          );
        }
        // id 用 epId：ArchiveChapterList 的 currentId 高亮和阅读器跳转都以它为准
        return ArchiveChapterList(
          chapters: [
            for (final chapter in chapters)
              ArchiveChapterEntry(id: chapter.epId, title: chapter.title),
          ],
          currentId: resume.lastUnitId,
          onTap: widget.onComicEpisodeTap == null
              ? null
              : (entry) => widget.onComicEpisodeTap!(resume, entry.id),
        );
      },
    );
  }

  /// 小说章节区：目录来自 novel source（含分卷），当前章高亮
  Widget _buildNovelChapterList(LibraryResume resume) {
    return FutureBuilder<List<NovelChapter>>(
      future: _novelChaptersFuture ??= _loadNovelChapters(resume),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ArchiveChapterListSkeleton(
            height: widget.fillHeight ? 380 : 320,
          );
        }
        final chapters = snapshot.data ?? const <NovelChapter>[];
        if (chapters.isEmpty) return const SizedBox.shrink();
        final byId = {
          for (final chapter in chapters) chapter.chapterId: chapter,
        };
        return ArchiveChapterList(
          chapters: [
            for (final chapter in chapters)
              ArchiveChapterEntry(
                id: chapter.chapterId,
                title: chapter.title,
                volumeTitle: chapter.volumeTitle,
              ),
          ],
          currentId: resume.lastUnitId,
          onTap: widget.onNovelChapterTap == null
              ? null
              : (entry) {
                  final chapter = byId[entry.id];
                  if (chapter != null) widget.onNovelChapterTap!(chapter);
                },
        );
      },
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

/// 目录加载失败 / 空态：一行说明 + 重试，不打断页面其余部分。
class _ChapterLoadError extends StatelessWidget {
  const _ChapterLoadError({required this.onRetry, required this.message});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArchiveType.meta.copyWith(color: tone.muted),
            ),
          ),
          ArchiveTextButton(onPressed: onRetry, child: const Text('重试')),
        ],
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
