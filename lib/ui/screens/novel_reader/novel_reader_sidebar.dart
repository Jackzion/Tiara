import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/services/novel/novel_navigation.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';

/// 侧边栏页签
enum NovelSidebarTab { catalog, search }

/// 目录 / 全书搜索 左侧边栏（archive 主题；布局参考 Koodo Reader）。
///
/// - 目录：分卷分组章节列表，当前章标记
/// - 搜索：全书逐章扫描（正文缓存加速），命中按章分组、带上下文片段，
///   点击结果跳转到目标章/段/偏移
class NovelReaderSidebar extends StatefulWidget {
  const NovelReaderSidebar({
    super.key,
    required this.bookTitle,
    required this.chapters,
    required this.currentChapterId,
    required this.loadParagraphs,
    required this.onJump,
    required this.onClose,
    this.initialTab = NovelSidebarTab.catalog,
  });

  final String bookTitle;
  final List<NovelChapter> chapters;
  final String currentChapterId;

  /// 取某章段落（全书搜索用；正文磁盘缓存加速回源）
  final Future<List<String>> Function(String chapterId) loadParagraphs;

  /// 点击搜索结果：目标章 + 段落 + 段内偏移 + 高亮区间（段内绝对坐标）
  final void Function(
    NovelChapter chapter,
    int paragraph,
    int offset,
    List<(int, int)> ranges,
  ) onJump;

  final VoidCallback onClose;
  final NovelSidebarTab initialTab;

  @override
  State<NovelReaderSidebar> createState() => _NovelReaderSidebarState();
}

class _NovelReaderSidebarState extends State<NovelReaderSidebar> {
  late NovelSidebarTab _tab = widget.initialTab;
  final _queryController = TextEditingController();
  Timer? _debounce;

  /// 全书搜索：章 → 命中（按扫描顺序渐进填充）
  final Map<NovelChapter, List<NovelSearchHit>> _hits = {};
  int _scanned = 0;
  bool _searching = false;
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _runSearch(query.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    setState(() {
      _hits.clear();
      _scanned = 0;
      _searching = query.isNotEmpty;
    });
    if (query.isEmpty) return;

    for (final chapter in widget.chapters) {
      // 跳转后侧边栏会 dispose：卸载/新查询都立即停止扫描
      if (!mounted || token != _searchToken) return;
      List<String> paragraphs;
      try {
        paragraphs = await widget.loadParagraphs(chapter.chapterId);
      } catch (_) {
        // 单章取文失败跳过（网络抖动/下架），不阻塞全书搜索
        if (!mounted || token != _searchToken) return;
        setState(() => _scanned++);
        continue;
      }
      if (!mounted || token != _searchToken) return;
      final hits = <NovelSearchHit>[
        for (var i = 0; i < paragraphs.length; i++)
          ...findNovelHitsWithContext(paragraphs[i], query, paragraphIndex: i),
      ];
      if (hits.isNotEmpty) {
        setState(() => _hits[chapter] = hits);
      }
      setState(() => _scanned++);
    }
    if (mounted && token == _searchToken) {
      setState(() => _searching = false);
    }
  }

  int get _totalHits =>
      _hits.values.fold(0, (sum, hits) => sum + hits.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: ArchivePalette.surface,
        border: Border(
          right: BorderSide(
            color: ArchivePalette.hairlineStrong,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabs(),
          const ArchiveDivider(),
          Expanded(
            child: _tab == NovelSidebarTab.catalog
                ? _buildCatalog()
                : _buildSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ArchiveCode('READER / INDEX'),
              const Spacer(),
              ArchiveIconButton(
                icon: Icons.close,
                label: '关闭侧栏',
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArchiveType.title.copyWith(color: ArchivePalette.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: ArchiveTextButton(
              selected: _tab == NovelSidebarTab.catalog,
              onPressed: () => setState(() => _tab = NovelSidebarTab.catalog),
              child: const Text('目录'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ArchiveTextButton(
              selected: _tab == NovelSidebarTab.search,
              onPressed: () => setState(() => _tab = NovelSidebarTab.search),
              child: const Text('搜索'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 目录 ────────────────────────────────────────────────────

  Widget _buildCatalog() {
    if (widget.chapters.isEmpty) {
      return Center(
        child: ArchiveCode(
          'EMPTY / 无目录',
          color: ArchivePalette.faint,
        ),
      );
    }
    final groups = groupChaptersByVolume(widget.chapters);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.volume != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
                child: Text(
                  group.volume!,
                  style: ArchiveType.meta.copyWith(
                    color: ArchivePalette.muted,
                    letterSpacing: 1,
                  ),
                ),
              ),
            for (final chapter in group.chapters) _buildChapterTile(chapter),
          ],
        );
      },
    );
  }

  Widget _buildChapterTile(NovelChapter chapter) {
    final isCurrent = chapter.chapterId == widget.currentChapterId;
    return InkWell(
      onTap: () => widget.onJump(chapter, 0, 0, const []),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isCurrent ? ArchivePalette.raised : null,
          border: const Border(
            bottom: BorderSide(
              color: ArchivePalette.hairline,
              width: ArchiveGeometry.dividerWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chapter.title,
                style: ArchiveType.body.copyWith(
                  color: isCurrent
                      ? ArchivePalette.error
                      : ArchivePalette.inkSoft,
                ),
              ),
            ),
            if (isCurrent)
              const Icon(
                Icons.bookmark,
                size: 14,
                color: ArchivePalette.error,
              ),
          ],
        ),
      ),
    );
  }

  // ── 全书搜索 ────────────────────────────────────────────────

  Widget _buildSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _queryController,
            autofocus: _tab == NovelSidebarTab.search,
            onChanged: _onQueryChanged,
            style: ArchiveType.body.copyWith(color: ArchivePalette.ink),
            decoration: InputDecoration(
              hintText: '全书搜索',
              hintStyle: ArchiveType.body.copyWith(color: ArchivePalette.faint),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: ArchivePalette.muted,
              ),
              suffixIcon: _queryController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: ArchivePalette.muted,
                      ),
                      onPressed: () {
                        _queryController.clear();
                        _runSearch('');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: ArchivePalette.raised,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ArchiveGeometry.pillRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ArchiveCode(
                  'RESULTS · $_totalHits'
                  '${_searching ? ' · SCANNED $_scanned/${widget.chapters.length}' : ''}',
                  color: ArchivePalette.muted,
                ),
              ),
              if (_searching)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const ArchiveDivider(),
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_queryController.text.trim().isEmpty) {
      return Center(
        child: ArchiveCode('输入关键词检索全书', color: ArchivePalette.faint),
      );
    }
    if (_hits.isEmpty && !_searching) {
      return Center(
        child: ArchiveCode('无匹配结果', color: ArchivePalette.faint),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final entry in _hits.entries) ...[
          _buildResultHeader(entry.key, entry.value.length),
          for (final hit in entry.value) _buildResultCard(entry.key, hit),
        ],
      ],
    );
  }

  Widget _buildResultHeader(NovelChapter chapter, int count) {
    final index = widget.chapters.indexOf(chapter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          ArchiveCode('CH.${index + 1}', color: ArchivePalette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArchiveType.meta.copyWith(color: ArchivePalette.inkSoft),
            ),
          ),
          ArchiveCode('($count)', color: ArchivePalette.faint),
        ],
      ),
    );
  }

  Widget _buildResultCard(NovelChapter chapter, NovelSearchHit hit) {
    final style = ArchiveType.bodyRegular.copyWith(color: ArchivePalette.ink);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: PressableScale(
        onTap: () =>
            widget.onJump(chapter, hit.paragraph, hit.start, [(hit.start, hit.end)]),
        child: PaperPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          background: ArchivePalette.milk,
          registration: false,
          child: Text.rich(
            buildHighlightedSpan(hit.snippet, style, [(hit.matchStart, hit.matchEnd)]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
