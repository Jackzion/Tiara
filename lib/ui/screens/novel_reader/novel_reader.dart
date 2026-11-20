import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/state/novel_reader_controller.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/not_ready.dart';
import 'package:movies/utils/prefs.dart';

/// 阅读器纸张（背景/文字配色，独立于 App 主题，取自 wenku8-ui-style §2.5）。
///
/// 深色纸的正文永不用纯白：lerp(bg, #F2F2F2, .82)。
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

/// 阅读偏好（v1 三项：字号/行距/纸张；Prefs 持久化，键名风格同 ComicFitMode）。
class NovelReaderPrefs {
  const NovelReaderPrefs({
    this.fontSize = defaultFontSize,
    this.lineHeight = defaultLineHeight,
    this.paper = NovelPaper.system,
  });

  static const double defaultFontSize = 19;
  static const double defaultLineHeight = 1.72;

  static const String _fontSizeKey = 'NovelFontSize';
  static const String _lineHeightKey = 'NovelLineHeight';
  static const String _paperKey = 'NovelPaper';

  final double fontSize;
  final double lineHeight;
  final NovelPaper paper;

  NovelReaderPrefs copyWith({
    double? fontSize,
    double? lineHeight,
    NovelPaper? paper,
  }) => NovelReaderPrefs(
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        paper: paper ?? this.paper,
      );

  static Future<NovelReaderPrefs> load(Prefs prefs) async => NovelReaderPrefs(
        fontSize: prefs.getDouble(_fontSizeKey) ?? defaultFontSize,
        lineHeight: prefs.getDouble(_lineHeightKey) ?? defaultLineHeight,
        paper: NovelPaper.parse(prefs.getString(_paperKey)),
      );

  Future<void> save(Prefs prefs) async {
    await prefs.setDouble(_fontSizeKey, fontSize);
    await prefs.setDouble(_lineHeightKey, lineHeight);
    await prefs.setString(_paperKey, paper.name);
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
    super.key,
  });

  final String sourceKey;
  final String bookId;
  final String chapterId;

  /// 书名（章名未加载出时的顶栏兜底）
  final String title;

  /// 章名（入参兜底，正常以 controller 加载的为准）
  final String chapterTitle;

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

  /// 书库进度：防抖 500ms 落库（fire-and-forget，失败不影响阅读）
  void _scheduleProgressSave() {
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(milliseconds: 500), _saveProgress);
  }

  void _saveProgress() {
    if (!mounted || !_scrollController.hasClients) return;
    final reader = ref.read(
      novelReaderControllerProvider(
        widget.sourceKey,
        widget.bookId,
        widget.chapterId,
      ),
    );
    final state = reader.value;
    if (state == null || state.paragraphs.isEmpty) return;

    // 采样：视口顶部之上、下标最大的已挂载段落 = 当前段
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
    final max = _scrollController.position.maxScrollExtent;
    final fraction = max > 0 ? _scrollController.offset / max : 0.0;

    ref
        .read(
          novelReaderControllerProvider(
            widget.sourceKey,
            widget.bookId,
            widget.chapterId,
          ).notifier,
        )
        .touchProgress(current, fraction, fontSize: _prefs.fontSize);
  }

  /// 恢复阅读位置：先按估值跳近，再精修到目标段（顶对齐）
  void _scheduleRestore(NovelReaderState state) {
    if (_restored) return;
    _restored = true;
    final target = state.initialParagraph;
    if (target <= 0) return;
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
        }
      });
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

  Widget _buildReader(NovelReaderState state) {
    _scheduleRestore(state);
    final brightness = Theme.of(context).brightness;
    final textColor = _prefs.paper.textColor(brightness);
    if (state.paragraphs.isEmpty) {
      return Center(
        child: Text('本章无内容', style: body2Regular.copyWith(color: textColor)),
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
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 88),
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
            final imageUrl = _imageUrlOf(paragraph);
            return Padding(
              key: _keys.putIfAbsent(index, () => GlobalKey()),
              padding: EdgeInsets.only(bottom: _paragraphGap),
              child: imageUrl != null
                  ? _ParagraphImage(url: imageUrl)
                  : Text(
                      paragraph,
                      style: TextStyle(
                        fontSize: _prefs.fontSize,
                        height: _prefs.lineHeight,
                        color: textColor,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  /// 插图段：<!--image-->URL<!--image-->（可带 <!--epub-image:...--> 尾注）
  String? _imageUrlOf(String paragraph) {
    const marker = '<!--image-->';
    if (!paragraph.startsWith(marker)) return null;
    final end = paragraph.lastIndexOf(marker);
    if (end <= marker.length) return null;
    return paragraph.substring(marker.length, end).trim();
  }

  /// 点击区域：中央切换顶/底栏（滚动模式左右点击不切章，防误触）
  void _onTap(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    if (dx > width / 3 && dx < width * 2 / 3) {
      setState(() => _showChrome = !_showChrome);
    }
  }

  double? _progress(NovelReaderState? state) {
    if (state == null || state.chapterCount == 0) return null;
    return (state.chapterIndex + 1) / state.chapterCount;
  }

  String _chapterLabel(NovelReaderState? state) {
    if (state == null || state.chapterCount == 0) return '';
    return '第 ${state.chapterIndex + 1}/${state.chapterCount} 章';
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ReaderSettingsSheet(
        prefs: _prefs,
        onChanged: (next) {
          setState(() => _prefs = next);
          _savePrefs();
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
    required this.onSettings,
  });

  final double? progress;
  final String pageLabel;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
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
class _ParagraphImage extends StatelessWidget {
  const _ParagraphImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        url,
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
                onPressed: () {},
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('阅读设置', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
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
    );
  }
}
