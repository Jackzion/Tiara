import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/services/novel/novel_navigation.dart';
import 'package:movies/services/novel/novel_pagination.dart';
import 'package:movies/state/novel_reader_controller.dart';
import 'package:movies/ui/screens/novel_reader/novel_paged_view.dart';
import 'package:movies/ui/screens/novel_reader/novel_reader_sidebar.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/not_ready.dart';
import 'package:movies/ui/widgets/resilient_network_image.dart';
import 'package:movies/utils/prefs.dart';

/// 阅读器纸张（背景/文字配色，独立于 App 主题）。
enum NovelPaper {
  system('跟随外观'),
  milk('奶白'),
  parchment('羊皮纸'),
  moss('浅苔'),
  night('夜读');

  const NovelPaper(this.label);

  final String label;

  static NovelPaper parse(String? raw) =>
      values.firstWhere((p) => p.name == raw, orElse: () => system);

  Color background(Brightness brightness) => switch (this) {
        system => brightness == Brightness.dark
            ? const Color(0xFF191919)
            : const Color(0xFFF7F7F2),
        milk => const Color(0xFFF6F5EF),
        parchment => const Color(0xFFEDE2CA),
        moss => const Color(0xFFE4EBDD),
        night => const Color(0xFF191919),
      };

  Color textColor(Brightness brightness) {
    final bg = background(brightness);
    return bg.computeLuminance() < 0.5
        ? Color.lerp(bg, const Color(0xFFF2F2F2), .82)!
        : const Color(0xFF30352F);
  }
}

/// 阅读模式：滚动 / 翻页
enum NovelReadingMode {
  scroll('滚动'),
  paged('翻页');

  const NovelReadingMode(this.label);

  final String label;

  static NovelReadingMode parse(String? raw) =>
      values.firstWhere((m) => m.name == raw, orElse: () => scroll);
}

/// 阅读偏好（字号/行距/纸张/边距/字距/模式；Prefs 持久化，键名风格同 ComicFitMode）。
class NovelReaderPrefs {
  const NovelReaderPrefs({
    this.fontSize = defaultFontSize,
    this.lineHeight = defaultLineHeight,
    this.paper = NovelPaper.system,
    this.letterSpacing = defaultLetterSpacing,
    this.pageMargin = defaultPageMargin,
    this.mode = NovelReadingMode.scroll,
  });

  static const double defaultFontSize = 19;
  static const double defaultLineHeight = 1.72;
  static const double defaultLetterSpacing = 0;
  static const double defaultPageMargin = 24;

  static const String _fontSizeKey = 'NovelFontSize';
  static const String _lineHeightKey = 'NovelLineHeight';
  static const String _paperKey = 'NovelPaper';
  static const String _letterSpacingKey = 'NovelLetterSpacing';
  static const String _pageMarginKey = 'NovelPageMargin';
  static const String _modeKey = 'NovelReaderMode';

  final double fontSize;
  final double lineHeight;
  final NovelPaper paper;
  final double letterSpacing;
  final double pageMargin;
  final NovelReadingMode mode;

  NovelReaderPrefs copyWith({
    double? fontSize,
    double? lineHeight,
    NovelPaper? paper,
    double? letterSpacing,
    double? pageMargin,
    NovelReadingMode? mode,
  }) =>
      NovelReaderPrefs(
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        paper: paper ?? this.paper,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        pageMargin: pageMargin ?? this.pageMargin,
        mode: mode ?? this.mode,
      );

  static Future<NovelReaderPrefs> load(Prefs prefs) async => NovelReaderPrefs(
        fontSize: prefs.getDouble(_fontSizeKey) ?? defaultFontSize,
        lineHeight: prefs.getDouble(_lineHeightKey) ?? defaultLineHeight,
        paper: NovelPaper.parse(prefs.getString(_paperKey)),
        letterSpacing: prefs.getDouble(_letterSpacingKey) ?? defaultLetterSpacing,
        pageMargin: prefs.getDouble(_pageMarginKey) ?? defaultPageMargin,
        mode: NovelReadingMode.parse(prefs.getString(_modeKey)),
      );

  Future<void> save(Prefs prefs) async {
    await prefs.setDouble(_fontSizeKey, fontSize);
    await prefs.setDouble(_lineHeightKey, lineHeight);
    await prefs.setString(_paperKey, paper.name);
    await prefs.setDouble(_letterSpacingKey, letterSpacing);
    await prefs.setDouble(_pageMarginKey, pageMargin);
    await prefs.setString(_modeKey, mode.name);
  }
}

/// 小说阅读页（滚动模式 MVP）：
/// ListView 段落流 + 顶/底栏 chrome + 中央点击显隐 + 上下章 + 进度记忆。
@RoutePage(name: 'NovelReaderRoute')
class NovelReader extends ConsumerStatefulWidget {
  const NovelReader({
    required this.sourceKey,
    required this.bookId,
    required this.chapterId,
    required this.title,
    this.chapterTitle = '',
    this.initialParagraph,
    this.initialOffset,
    super.key,
  });

  final String sourceKey;
  final String bookId;
  final String chapterId;

  /// 书名（章名未加载出时的顶栏兜底）
  final String title;

  /// 章名（入参兜底，正常以 controller 加载的为准）
  final String chapterTitle;

  /// 跨章跳转锚点（全书搜索点击结果时传入；null = 按书库进度恢复）
  final int? initialParagraph;
  final int? initialOffset;

  @override
  ConsumerState<NovelReader> createState() => _NovelReaderState();
}

class _NovelReaderState extends ConsumerState<NovelReader> {
  final ScrollController _scrollController = ScrollController();

  /// 段落下标 → item key（恢复定位 / 进度采样用；只登记已挂载段落）
  final Map<int, GlobalKey> _keys = {};

  /// 顶/底栏显隐（点屏幕中央切换）
  bool _showChrome = true;

  /// 阅读偏好（Prefs 持久化）
  NovelReaderPrefs _prefs = const NovelReaderPrefs();

  /// 进度落库防抖
  Timer? _progressTimer;

  /// 恢复位置只执行一次
  bool _restored = false;

  /// 当前位置锚点段落（滚动采样/翻页共同维护；模式切换时用它接续）
  int _anchorParagraph = 0;

  /// 翻页模式的页码标签（如 "12 / 256 页"）
  String? _pagedLabel;

  /// 章内/全书查找高亮区间（段落 → 段内区间列表）
  Map<int, List<(int, int)>> _highlights = {};

  /// 左侧边栏（目录/全书搜索）
  bool _sidebarVisible = false;
  NovelSidebarTab _sidebarTab = NovelSidebarTab.catalog;

  /// 翻页模式的定位令牌（跳转时递增触发重建）
  int _seekToken = 0;
  int _seekOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ref.read(prefsProvider.future);
    final loaded = await NovelReaderPrefs.load(prefs);
    if (!mounted) return;
    setState(() => _prefs = loaded);
  }

  void _savePrefs() {
    ref
        .read(prefsProvider.future)
        .then((prefs) => _prefs.save(prefs))
        .catchError((Object e) => debugPrint('save prefs failed: $e'));
  }

  /// 书库进度：防抖 500ms 落库（fire-and-forget，失败不影响阅读）。
  /// [paragraph]/[fraction] 显式给出时直接用（翻页模式）；否则滚动采样。
  void _scheduleProgressSave({int? paragraph, double? fraction}) {
    _progressTimer?.cancel();
    _progressTimer = Timer(
      const Duration(milliseconds: 500),
      () => _saveProgress(paragraph: paragraph, fraction: fraction),
    );
  }

  void _saveProgress({int? paragraph, double? fraction}) {
    if (!mounted) return;
    final reader = ref.read(
      novelReaderControllerProvider(
        widget.sourceKey,
        widget.bookId,
        widget.chapterId,
      ),
    );
    final state = reader.value;
    if (state == null || state.paragraphs.isEmpty) return;

    if (paragraph == null) {
      // 滚动采样：视口顶部之上、下标最大的已挂载段落 = 当前段
      if (!_scrollController.hasClients) return;
      final top = MediaQuery.of(context).padding.top;
      var current = 0;
      for (final entry in _keys.entries) {
        final ctx = entry.value.currentContext;
        if (ctx == null) continue;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;
        if (box.localToGlobal(Offset.zero).dy <= top + 16 &&
            entry.key > current) {
          current = entry.key;
        }
      }
      paragraph = current;
      final max = _scrollController.position.maxScrollExtent;
      fraction = max > 0 ? _scrollController.offset / max : 0.0;
    }
    _anchorParagraph = paragraph;

    ref
        .read(
          novelReaderControllerProvider(
            widget.sourceKey,
            widget.bookId,
            widget.chapterId,
          ).notifier,
        )
        .touchProgress(paragraph, fraction ?? 0, fontSize: _prefs.fontSize);
  }

  /// 翻页模式：页变更 → 更新锚点/页码标签/进度
  void _onPaged(int pageIndex, NovelPage page, int pageCount) {
    setState(() => _pagedLabel = '${pageIndex + 1} / $pageCount 页');
    _anchorParagraph = page.firstParagraph;
    _scheduleProgressSave(
      paragraph: page.firstParagraph,
      fraction: pageCount > 1 ? pageIndex / (pageCount - 1) : 0,
    );
  }

  /// 滚动模式跳到指定段落（模式切换接续用）
  void _jumpToParagraph(int paragraph) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _keys[paragraph]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: Duration.zero);
      }
    });
  }



  /// 恢复阅读位置：先按估值跳近，再精修到目标段（顶对齐）
  void _scheduleRestore(NovelReaderState state) {
    if (_restored) return;
    _restored = true;
    // 跨章跳转锚点优先，否则用书库进度锚点
    final target = widget.initialParagraph ?? state.initialParagraph;
    final offset = widget.initialParagraph != null
        ? (widget.initialOffset ?? 0)
        : state.initialOffset;
    _anchorParagraph = target;
    _seekOffset = offset;
    if (target <= 0 && offset <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final est = target *
          (_prefs.fontSize * _prefs.lineHeight * 3 + _paragraphGap);
      _scrollController.jumpTo(
        est.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _keys[target]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: Duration.zero);
          // 段内偏移精修（全书搜索跳转/精确恢复）
          if (offset > 0) {
            _jumpToTextPosition(target, offset);
          }
        }
      });
    });
  }

  // ── 左侧边栏（目录/全书搜索）────────────────────────────────

  void _openSidebar(NovelSidebarTab tab) {
    setState(() {
      _sidebarTab = tab;
      _sidebarVisible = true;
    });
  }

  void _closeSidebar() => setState(() => _sidebarVisible = false);

  /// 侧边栏浮层：左停靠面板 + 点右侧遮罩关闭
  Widget _buildSidebar(NovelReaderState state) {
    return Positioned.fill(
      child: Row(
        children: [
          NovelReaderSidebar(
            bookTitle: state.bookTitle,
            chapters: state.chapters,
            currentChapterId: widget.chapterId,
            loadParagraphs: (chapterId) async {
              final text = await ref
                  .read(novelRepositoryProvider)
                  .loadText(widget.sourceKey, widget.bookId, chapterId);
              return splitNovelParagraphs(text);
            },
            onJump: _onJump,
            onClose: _closeSidebar,
            initialTab: _sidebarTab,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeSidebar,
              child: const ColoredBox(color: ArchivePalette.scrim),
            ),
          ),
        ],
      ),
    );
  }

  /// 侧边栏跳转：本章 → 高亮 + 滚动/翻页定位；他章 → replace 换章带锚点
  void _onJump(
    NovelChapter chapter,
    int paragraph,
    int offset,
    List<(int, int)> ranges,
  ) {
    _closeSidebar();
    if (chapter.chapterId == widget.chapterId) {
      setState(() {
        _highlights = ranges.isEmpty ? {} : {paragraph: ranges};
        _anchorParagraph = paragraph;
        _seekOffset = offset;
        _seekToken++;
      });
      if (_prefs.mode == NovelReadingMode.scroll) {
        _jumpToTextPosition(paragraph, offset);
      }
      return;
    }
    _progressTimer?.cancel();
    _saveProgress();
    context.router.replace(
      NovelReaderRoute(
        sourceKey: widget.sourceKey,
        bookId: widget.bookId,
        chapterId: chapter.chapterId,
        title: widget.title,
        chapterTitle: chapter.title,
        initialParagraph: paragraph,
        initialOffset: offset,
      ),
    );
  }

  /// 精确跳到段内文本位置：段首 ensureVisible，段内按行框顶校正
  void _jumpToTextPosition(int paragraph, int offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _keys[paragraph]?.currentContext;
      if (ctx == null) return;
      if (offset <= 0 || !_scrollController.hasClients) {
        Scrollable.ensureVisible(ctx, duration: Duration.zero);
        return;
      }
      final rp = ctx.findRenderObject() as RenderParagraph?;
      if (rp == null) {
        Scrollable.ensureVisible(ctx, duration: Duration.zero);
        return;
      }
      final boxes = rp.getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      );
      if (boxes.isEmpty) {
        Scrollable.ensureVisible(ctx, duration: Duration.zero);
        return;
      }
      final dy = rp.localToGlobal(Offset.zero).dy + boxes.first.top;
      final target = _scrollController.offset +
          dy -
          (MediaQuery.of(context).padding.top + 64);
      _scrollController.jumpTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }

  double get _paragraphGap => _prefs.fontSize * 0.6;

  /// 换章：先落库当前进度，再整页替换
  void _goChapter(String chapterId, String chapterTitle) {
    _progressTimer?.cancel();
    _saveProgress();
    context.router.replace(
      NovelReaderRoute(
        sourceKey: widget.sourceKey,
        bookId: widget.bookId,
        chapterId: chapterId,
        title: widget.title,
        chapterTitle: chapterTitle,
      ),
    );
  }

  void _onBack() {
    _progressTimer?.cancel();
    _saveProgress();
    ref.read(appRouterProvider).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final readerAsync = ref.watch(
      novelReaderControllerProvider(
        widget.sourceKey,
        widget.bookId,
        widget.chapterId,
      ),
    );
    final state = readerAsync.value;
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: _prefs.paper.background(brightness),
      body: Stack(
        children: [
          // 正文：段落流
          Positioned.fill(
            child: readerAsync.when(
              loading: () => const NotReady(),
              error: (e, st) => _buildError('$e'),
              data: _buildReader,
            ),
          ),
          if (_sidebarVisible && state != null) _buildSidebar(state),
          // 顶部栏：书名 · 章名（点中央显隐）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showChrome,
              child: AnimatedOpacity(
                opacity: _showChrome ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _TopBar(
                  title: state != null && state.chapterTitle.isNotEmpty
                      ? '${widget.title} · ${state.chapterTitle}'
                      : (widget.chapterTitle.isNotEmpty
                          ? '${widget.title} · ${widget.chapterTitle}'
                          : widget.title),
                  onBack: _onBack,
                ),
              ),
            ),
          ),
          // 底部：进度 + 上下章 + 设置
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showChrome,
              child: AnimatedOpacity(
                opacity: _showChrome ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _BottomBar(
                  progress: _progress(state),
                  pageLabel: _chapterLabel(state),
                  hasPrev: state?.prevChapterId != null,
                  hasNext: state?.nextChapterId != null,
                  onPrev: () => _goChapter(
                    state!.prevChapterId!,
                    state.prevChapterTitle ?? '',
                  ),
                  onNext: () => _goChapter(
                    state!.nextChapterId!,
                    state.nextChapterTitle ?? '',
                  ),
                  onCatalog: () => _openSidebar(NovelSidebarTab.catalog),
                  onFind: () => _openSidebar(NovelSidebarTab.search),
                  onSettings: _showSettings,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) => ColoredBox(
        color: _prefs.paper.background(Theme.of(context).brightness),
        child: Column(
          children: [
            Expanded(child: ArchiveLoadError(message: message)),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton(
                onPressed: () => ref.invalidate(
                  novelReaderControllerProvider(
                    widget.sourceKey,
                    widget.bookId,
                    widget.chapterId,
                  ),
                ),
                child: const Text('重试'),
              ),
            ),
          ],
        ),
      );

  /// 正文区版面（滚动/分页共用：屏宽扣边距、屏高扣上下留白）
  NovelLayout _layout(Size size) => NovelLayout(
        width: size.width - _prefs.pageMargin * 2,
        height: size.height - 64 - 88,
        fontSize: _prefs.fontSize,
        lineHeight: _prefs.lineHeight,
        letterSpacing: _prefs.letterSpacing,
        paragraphGap: _paragraphGap,
      );

  Widget _buildReader(NovelReaderState state) {
    _scheduleRestore(state);
    final brightness = Theme.of(context).brightness;
    final textColor = _prefs.paper.textColor(brightness);
    if (state.paragraphs.isEmpty) {
      return Center(
        child: Text('本章无内容', style: body2Regular.copyWith(color: textColor)),
      );
    }
    // 翻页模式：分页引擎 + PageView（一图一页）
    if (_prefs.mode == NovelReadingMode.paged) {
      return _PagedReader(
        key: ValueKey(_seekToken),
        paragraphs: state.paragraphs,
        layout: _layout(MediaQuery.of(context).size),
        textColor: textColor,
        initialParagraph: _anchorParagraph,
        initialOffset: _seekOffset,
        highlights: _highlights,
        onPageChanged: _onPaged,
        onTapCenter: () => setState(() => _showChrome = !_showChrome),
      );
    }
    final hasNext = state.nextChapterId != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _scheduleProgressSave();
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) => _onTap(details),
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(_prefs.pageMargin, 64, _prefs.pageMargin, 88),
          itemCount: state.paragraphs.length + (hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            // 末位：「下一章」卡片
            if (index >= state.paragraphs.length) {
              return Padding(
                padding: EdgeInsets.only(top: _paragraphGap * 2),
                child: _NextChapterCard(
                  title: state.nextChapterTitle ?? '',
                  onTap: () => _goChapter(
                    state.nextChapterId!,
                    state.nextChapterTitle ?? '',
                  ),
                ),
              );
            }
            final paragraph = state.paragraphs[index];
            final imageUrl = novelImageUrlOf(paragraph);
            return Padding(
              key: _keys.putIfAbsent(index, () => GlobalKey()),
              padding: EdgeInsets.only(bottom: _paragraphGap),
              // 一图一页：插图独占整个正文视口（高度 = 屏高 - 上下留白，
              // 与 ListView 的 fromLTRB(24, 64, 24, 88) 对应）
              child: imageUrl != null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height - 64 - 88,
                      child: _ParagraphImage(url: imageUrl),
                    )
                  : Text.rich(
                      buildHighlightedSpan(
                        paragraph,
                        TextStyle(
                          fontSize: _prefs.fontSize,
                          height: _prefs.lineHeight,
                          letterSpacing: _prefs.letterSpacing,
                          color: textColor,
                        ),
                        _highlights[index] ?? const [],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  /// 图片段 URL 提取统一走 novelImageUrlOf（novel_pagination.dart）。

  /// 点击区域：中央切换顶/底栏（滚动模式左右点击不切章，防误触）
  void _onTap(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    if (dx > width / 3 && dx < width * 2 / 3) {
      setState(() => _showChrome = !_showChrome);
    }
  }

  /// 全书进度 =（章序 + 章内段落进度）/ 总章数（插图段按 1 段计）
  double? _progress(NovelReaderState? state) {
    if (state == null || state.chapterCount == 0) return null;
    final within = state.paragraphs.isEmpty
        ? 0.0
        : (_anchorParagraph / state.paragraphs.length).clamp(0.0, 1.0);
    return ((state.chapterIndex + within) / state.chapterCount).clamp(0.0, 1.0);
  }

  String _chapterLabel(NovelReaderState? state) {
    if (_pagedLabel != null) return _pagedLabel!;
    if (state == null || state.chapterCount == 0) return '';
    final percent = ((_progress(state) ?? 0) * 100).round();
    return '第 ${state.chapterIndex + 1}/${state.chapterCount} 章 · $percent%';
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ReaderSettingsSheet(
        prefs: _prefs,
        onChanged: (next) {
          final modeChanged = next.mode != _prefs.mode;
          setState(() => _prefs = next);
          _savePrefs();
          // 切回滚动模式：接续到当前段落
          if (modeChanged && next.mode == NovelReadingMode.scroll) {
            _jumpToParagraph(_anchorParagraph);
          }
        },
      ),
    );
  }
}

/// 顶部栏：返回 + 书名 · 章名
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: searchBarBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部：进度条 + 上下章 + 设置
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.progress,
    required this.pageLabel,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
    required this.onCatalog,
    required this.onFind,
    required this.onSettings,
  });

  final double? progress;
  final String pageLabel;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onCatalog;
  final VoidCallback onFind;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: searchBarBackground,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: buttonGrey,
              color: accentAmber,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: hasPrev ? onPrev : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('上一章'),
                  ),
                  TextButton.icon(
                    onPressed: hasNext ? onNext : null,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text('下一章'),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onCatalog,
                    icon: const Icon(Icons.toc, size: 18),
                    tooltip: '目录',
                  ),
                  IconButton(
                    onPressed: onFind,
                    icon: const Icon(Icons.search, size: 18),
                    tooltip: '章内查找',
                  ),
                  IconButton(
                    onPressed: onSettings,
                    icon: const Icon(Icons.text_fields, size: 18),
                    tooltip: '阅读设置',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(pageLabel, style: body3Regular),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 末位「下一章」卡片
class _NextChapterCard extends StatelessWidget {
  const _NextChapterCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book, color: iconPlaceholder, size: 48),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: Text('下一章 · $title')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 插图段：网络图 + 载入/失败占位
/// wenku8 图片防盗链头（协议调研 §4），403 防护；实现见 widgets 公共件。
class _ParagraphImage extends StatelessWidget {
  const _ParagraphImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image(
        image: ResilientNetworkImage(
          url,
          headers: wenku8ImageHeaders(url),
        ),
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
        errorBuilder: (_, err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.broken_image, color: iconPlaceholder, size: 40),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {logError(url + err.toString());},
                child: const Text('插图加载失败'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 阅读设置面板：字号/行距/纸张（改动即时生效并持久化）
/// 分页正文：管理分页任务（layout/正文变化时重排，可取消）与页定位。
class _PagedReader extends StatefulWidget {
  const _PagedReader({
    super.key,
    required this.paragraphs,
    required this.layout,
    required this.textColor,
    required this.initialParagraph,
    this.initialOffset = 0,
    this.highlights = const {},
    required this.onPageChanged,
    required this.onTapCenter,
  });

  final List<String> paragraphs;
  final NovelLayout layout;
  final Color textColor;
  final int initialParagraph;
  final int initialOffset;
  final Map<int, List<(int, int)>> highlights;
  final void Function(int pageIndex, NovelPage page, int pageCount)
      onPageChanged;
  final VoidCallback onTapCenter;

  @override
  State<_PagedReader> createState() => _PagedReaderState();
}

class _PagedReaderState extends State<_PagedReader> {
  final _engine = NovelPagination();
  List<NovelPage>? _pages;

  @override
  void initState() {
    super.initState();
    _paginate();
  }

  @override
  void didUpdateWidget(covariant _PagedReader old) {
    super.didUpdateWidget(old);
    // 排版参数或正文变化 → 重新分页（测量缓存保证只重装页）
    if (old.layout != widget.layout || old.paragraphs != widget.paragraphs) {
      _paginate();
    }
  }

  Future<void> _paginate() async {
    final pages = await _engine.paginate(widget.paragraphs, widget.layout);
    if (mounted && pages != null) {
      setState(() => _pages = pages);
    }
  }

  /// 初始页：优先精确命中 (段落, 偏移) 所在片段，退化为段落页首
  int _initialPage() {
    final pages = _pages!;
    for (var i = 0; i < pages.length; i++) {
      for (final f in pages[i].fragments) {
        if (f.paragraph == widget.initialParagraph &&
            f.start <= widget.initialOffset &&
            widget.initialOffset < f.end) {
          return i;
        }
      }
    }
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].firstParagraph >= widget.initialParagraph) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    if (pages == null || pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return NovelPagedView(
      pages: pages,
      paragraphs: widget.paragraphs,
      layout: widget.layout,
      initialPage: _initialPage(),
      textColor: widget.textColor,
      highlights: widget.highlights,
      onPageChanged: (index) => widget.onPageChanged(
        index,
        pages[index],
        pages.length,
      ),
      onTapCenter: widget.onTapCenter,
    );
  }
}

/// 目录面板：分卷分组（连续同卷折叠）+ 当前章标记，点击跳章。
class _ReaderSettingsSheet extends StatefulWidget {
  const _ReaderSettingsSheet({required this.prefs, required this.onChanged});

  final NovelReaderPrefs prefs;
  final ValueChanged<NovelReaderPrefs> onChanged;

  @override
  State<_ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<_ReaderSettingsSheet> {
  late NovelReaderPrefs _prefs = widget.prefs;

  void _update(NovelReaderPrefs next) {
    setState(() => _prefs = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('阅读设置', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final mode in NovelReadingMode.values)
                  ChoiceChip(
                    label: Text(mode.label),
                    selected: _prefs.mode == mode,
                    onSelected: (_) => _update(_prefs.copyWith(mode: mode)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('字号'),
                Expanded(
                  child: Slider(
                    value: _prefs.fontSize,
                    min: 10,
                    max: 27,
                    divisions: 17,
                    label: _prefs.fontSize.round().toString(),
                    onChanged: (v) => _update(_prefs.copyWith(fontSize: v)),
                  ),
                ),
                Text(_prefs.fontSize.round().toString()),
              ],
            ),
            Row(
              children: [
                const Text('行距'),
                Expanded(
                  child: Slider(
                    value: _prefs.lineHeight,
                    min: 1.3,
                    max: 2.2,
                    divisions: 9,
                    label: _prefs.lineHeight.toStringAsFixed(2),
                    onChanged: (v) => _update(_prefs.copyWith(lineHeight: v)),
                  ),
                ),
                Text(_prefs.lineHeight.toStringAsFixed(2)),
              ],
            ),
            Row(
              children: [
                const Text('字距'),
                Expanded(
                  child: Slider(
                    value: _prefs.letterSpacing,
                    min: -0.5,
                    max: 3,
                    divisions: 14,
                    label: _prefs.letterSpacing.toStringAsFixed(1),
                    onChanged: (v) =>
                        _update(_prefs.copyWith(letterSpacing: v)),
                  ),
                ),
                Text(_prefs.letterSpacing.toStringAsFixed(1)),
              ],
            ),
            Row(
              children: [
                const Text('边距'),
                Expanded(
                  child: Slider(
                    value: _prefs.pageMargin,
                    min: 12,
                    max: 48,
                    divisions: 12,
                    label: _prefs.pageMargin.round().toString(),
                    onChanged: (v) => _update(_prefs.copyWith(pageMargin: v)),
                  ),
                ),
                Text(_prefs.pageMargin.round().toString()),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final paper in NovelPaper.values)
                  ChoiceChip(
                    label: Text(paper.label),
                    selected: _prefs.paper == paper,
                    onSelected: (_) => _update(_prefs.copyWith(paper: paper)),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
