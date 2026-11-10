import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:movies/providers.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/services/commic/commic_image_loader.dart';
import 'package:movies/state/comic_reader_controller.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/not_ready.dart';

/// 图片适配模式：整页（默认，完整可见）/ 宽适应（铺满宽度，可捏合缩小看全貌）
enum ComicFitMode {
  contain('整页', BoxFit.contain),
  width('宽适应', BoxFit.fitWidth);

  const ComicFitMode(this.label, this.fit);

  final String label;
  final BoxFit fit;

  static ComicFitMode parse(String? raw) =>
      raw == width.name ? width : contain;
}

/// 设置键：图片适配模式（Prefs 持久化）
const String _comicFitModeKey = 'ComicFitMode';

/// 漫画阅读页（对标 Venera 画廊模式）：
/// 横向 PageView 翻页 + InteractiveViewer 缩放 + 页码/进度 + 点击区域翻页
@RoutePage(name: 'ComicReaderRoute')
class ComicReader extends ConsumerStatefulWidget {
  const ComicReader({
    required this.sourceKey,
    required this.comicId,
    required this.epId,
    required this.title,
    this.epTitle = '',
    super.key,
  });

  final String sourceKey;
  final String comicId;
  final String epId;

  /// 漫画标题（章名未加载出时的顶栏兜底）
  final String title;

  /// 章名（入参兜底，正常以 controller 加载的为准）
  final String epTitle;

  @override
  ConsumerState<ComicReader> createState() => _ComicReaderState();
}

class _ComicReaderState extends ConsumerState<ComicReader> {
  final PageController _pageController = PageController();

  /// 当前页（0-based，不含末尾「下一章」页）
  int _currentPage = 0;

  /// 顶/底栏显隐（点屏幕中央切换）
  bool _showChrome = true;

  /// 当前是否缩放中（缩放时侧边点击不翻页，避免误触）
  bool _zoomed = false;

  /// 图片适配模式（Prefs 持久化）
  ComicFitMode _fitMode = ComicFitMode.contain;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyVisible(0);
    });
    _loadFitMode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFitMode() async {
    final prefs = await ref.read(prefsProvider.future);
    if (!mounted) return;
    setState(() {
      _fitMode = ComicFitMode.parse(prefs.getString(_comicFitModeKey));
    });
  }

  void _toggleFitMode() {
    setState(() {
      _fitMode =
          _fitMode == ComicFitMode.contain ? ComicFitMode.width : ComicFitMode.contain;
    });
    ref.read(prefsProvider.future).then(
          (prefs) => prefs.setString(_comicFitModeKey, _fitMode.name),
        );
  }

  void _notifyVisible(int index) {
    ref
        .read(
          comicReaderControllerProvider(
                  widget.sourceKey, widget.comicId, widget.epId)
              .notifier,
        )
        .notifyVisible(index);
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerAsync = ref.watch(
      comicReaderControllerProvider(widget.sourceKey, widget.comicId, widget.epId),
    );
    final state = readerAsync.value;
    return Scaffold(
      backgroundColor: screenBackground,
      body: Stack(
        children: [
          // 正文：横向画廊
          Positioned.fill(
            child: readerAsync.when(
              loading: () => const NotReady(),
              error: (e, st) => _ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(
                  comicReaderControllerProvider(
                      widget.sourceKey, widget.comicId, widget.epId),
                ),
              ),
              data: _buildGallery,
            ),
          ),
          // 顶部栏：章名 · 页码（点中央显隐）
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
                      ? state.chapterTitle
                      : (widget.epTitle.isNotEmpty ? widget.epTitle : widget.title),
                  pageLabel: _pageLabel(state),
                  onBack: () => ref.read(appRouterProvider).maybePop(),
                ),
              ),
            ),
          ),
          // 底部：进度条 + 适配切换
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
                  pageLabel: _pageLabel(state),
                  fitMode: _fitMode,
                  onFitToggle: _toggleFitMode,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 页码文案：n/m（在「下一章」页时钳到 m/m）
  String _pageLabel(ComicReaderState? state) {
    if (state == null || state.pages.isEmpty) return '';
    final total = state.pages.length;
    final cur = (_currentPage + 1).clamp(1, total);
    return '$cur/$total';
  }

  double? _progress(ComicReaderState? state) {
    if (state == null || state.pages.isEmpty) return null;
    return ((_currentPage + 1) / state.pages.length).clamp(0, 1).toDouble();
  }

  Widget _buildGallery(ComicReaderState state) {
    if (state.pages.isEmpty) {
      return Center(child: Text('本章无图', style: body2Regular));
    }
    final hasNext = state.nextEpId != null;
    final loader = ref.read(comicImageLoaderProvider);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) => _onTap(details, state),
      child: PageView.builder(
        controller: _pageController,
        itemCount: state.pages.length + (hasNext ? 1 : 0),
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          _notifyVisible(index.clamp(0, state.pages.length - 1));
        },
        itemBuilder: (context, index) {
          // 末位：「下一章」页
          if (index >= state.pages.length) {
            return _NextChapterPage(
              title: state.nextEpTitle ?? '',
              onTap: () => context.router.replace(
                ComicReaderRoute(
                  sourceKey: widget.sourceKey,
                  comicId: widget.comicId,
                  epId: state.nextEpId!,
                  title: '',
                  epTitle: state.nextEpTitle ?? '',
                ),
              ),
            );
          }
          return _ComicPageView(
            key: ValueKey(state.pages[index].imageKey),
            page: state.pages[index],
            loader: loader,
            sourceKey: widget.sourceKey,
            comicId: widget.comicId,
            epId: widget.epId,
            fitMode: _fitMode,
            onVisible: () => _notifyVisible(index),
            onZoomChanged: (zoomed) {
              if (_zoomed != zoomed) setState(() => _zoomed = zoomed);
            },
          );
        },
      ),
    );
  }

  /// 点击区域：左 1/3 上一页、右 1/3 下一页、中央切换顶/底栏
  void _onTap(TapUpDetails details, ComicReaderState state) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    if (dx < width / 3) {
      if (!_zoomed) _goToPage(_currentPage - 1);
    } else if (dx > width * 2 / 3) {
      if (!_zoomed) _goToPage(_currentPage + 1);
    } else {
      setState(() => _showChrome = !_showChrome);
    }
  }
}

/// 顶部栏：返回 + 章名 + 页码
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.pageLabel,
    required this.onBack,
  });

  final String title;
  final String pageLabel;
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
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(pageLabel, style: body2Regular),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部：进度条 + 适配模式切换
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.progress,
    required this.pageLabel,
    required this.fitMode,
    required this.onFitToggle,
  });

  final double? progress;
  final String pageLabel;
  final ComicFitMode fitMode;
  final VoidCallback onFitToggle;

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
                    onPressed: onFitToggle,
                    icon: Icon(
                      fitMode == ComicFitMode.contain
                          ? Icons.fit_screen
                          : Icons.width_full,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      fitMode.label,
                      style: body3Regular.copyWith(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
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

/// 末位「下一章」页
class _NextChapterPage extends StatelessWidget {
  const _NextChapterPage({required this.title, required this.onTap});

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
          FilledButton(
            onPressed: onTap,
            child: Text('下一章 · $title'),
          ),
        ],
      ),
    );
  }
}

/// 单张图：ensure() 本地 Future + InteractiveViewer 缩放 + 错误重试
class _ComicPageView extends StatefulWidget {
  const _ComicPageView({
    required this.page,
    required this.loader,
    required this.sourceKey,
    required this.comicId,
    required this.epId,
    required this.fitMode,
    required this.onVisible,
    required this.onZoomChanged,
    super.key,
  });

  final ComicPage page;
  final ComicImageLoader loader;
  final String sourceKey;
  final String comicId;
  final String epId;
  final ComicFitMode fitMode;
  final VoidCallback onVisible;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ComicPageView> createState() => _ComicPageViewState();
}

class _ComicPageViewState extends State<_ComicPageView> {
  /// 本地记忆 Future：rebuild 不重发（ensure 内部还有缓存/在途去重双保险）
  late Future<File> _future;

  /// 缩放矩阵（每页独立；监听用于判断「缩放中」）
  final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _future = _load();
    _transform.addListener(_onTransform);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05 || scale < 0.95);
  }

  // imageLoader 加载图片
  Future<File> _load() => widget.loader.ensure(
        widget.page,
        sourceKey: widget.sourceKey,
        comicId: widget.comicId,
        epId: widget.epId,
      );

  // 删缓存重试
  void _retry() {
    setState(() {
      _future = widget.loader
          .evict(
            imageKey: widget.page.imageKey,
            sourceKey: widget.sourceKey,
            comicId: widget.comicId,
            epId: widget.epId,
          )
          .then((_) => _load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PageError(onRetry: _retry, detail: '${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final file = snapshot.data!;
        // 限宽解码：物理像素宽，防大图撑爆内存
        final mq = MediaQuery.of(context);
        final targetWidth = (mq.size.width * mq.devicePixelRatio).round();
        return InteractiveViewer(
          transformationController: _transform,
          // 宽适应允许缩到 0.5 看全貌；整页模式从 1 起步
          minScale: widget.fitMode == ComicFitMode.width ? 0.5 : 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: Image(
              image: ResizeImage(
                FileImage(file),
                width: targetWidth,
                allowUpscaling: false,
              ),
              fit: widget.fitMode.fit,
              gaplessPlayback: true,
              errorBuilder: (_, err, _) =>
                  _PageError(onRetry: _retry, detail: '$err'),
            ),
          ),
        );
      },
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({required this.onRetry, this.detail});

  final VoidCallback onRetry;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, color: iconPlaceholder, size: 40),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('加载失败 · 重试')),
          if (detail != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                detail!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: body3Regular.copyWith(color: dangerRed),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
