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

/// 漫画阅读页：竖向连续滚动 + 单张重试 + 换章
@RoutePage(name: 'ComicReaderRoute')
class ComicReader extends ConsumerWidget {
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

  /// 漫画标题（章名未加载出时的 AppBar 兜底）
  final String title;

  /// 章名（入参兜底，正常以 controller 加载的为准）
  final String epTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerAsync =
        ref.watch(comicReaderControllerProvider(sourceKey, comicId, epId));
    final state = readerAsync.value;
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        backgroundColor: searchBarBackground,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => ref.read(appRouterProvider).maybePop(),
        ),
        title: Text(
          state != null && state.chapterTitle.isNotEmpty
              ? '${state.chapterTitle} · '
                  '${state.readyIndexes.length}/${state.pages.length}'
              : (epTitle.isNotEmpty ? epTitle : title),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: readerAsync.when(
        loading: () => const NotReady(),
        error: (e, st) => _ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(
            comicReaderControllerProvider(sourceKey, comicId, epId),
          ),
        ),
        data: (state) => _ChapterList(
          sourceKey: sourceKey,
          comicId: comicId,
          epId: epId,
          state: state,
        ),
      ),
    );
  }
}

/// 章节正文：竖向连续滚动，末尾「下一章」
class _ChapterList extends ConsumerWidget {
  const _ChapterList({
    required this.sourceKey,
    required this.comicId,
    required this.epId,
    required this.state,
  });

  final String sourceKey;
  final String comicId;
  final String epId;
  final ComicReaderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loader = ref.read(comicImageLoaderProvider);
    final notifier =
        ref.read(comicReaderControllerProvider(sourceKey, comicId, epId).notifier);
    final hasNext = state.nextEpId != null;

    return ListView.builder(
      itemCount: state.pages.length + (hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        // 末位：下一章按钮
        if (index >= state.pages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: FilledButton(
                onPressed: () {
                  // replace 而非 push：返回键回面板，不回上一章
                  context.router.replace(
                    ComicReaderRoute(
                      sourceKey: sourceKey,
                      comicId: comicId,
                      epId: state.nextEpId!,
                      title: '',
                      epTitle: state.nextEpTitle ?? '',
                    ),
                  );
                },
                child: Text('下一章 · ${state.nextEpTitle ?? ''}'),
              ),
            ),
          );
        }

        final page = state.pages[index];
        return _ComicPageView(
          key: ValueKey(page.imageKey), // 换页数据时重置本地 Future
          page: page,
          loader: loader,
          sourceKey: sourceKey,
          comicId: comicId,
          epId: epId,
          onVisible: () => notifier.notifyVisible(index),
        );
      },
    );
  }
}

/// 单张图：ensure() 本地 Future + 限宽解码 + 错误重试
class _ComicPageView extends StatefulWidget {
  const _ComicPageView({
    required this.page,
    required this.loader,
    required this.sourceKey,
    required this.comicId,
    required this.epId,
    required this.onVisible,
    super.key,
  });

  final ComicPage page;
  final ComicImageLoader loader;
  final String sourceKey;
  final String comicId;
  final String epId;
  final VoidCallback onVisible;

  @override
  State<_ComicPageView> createState() => _ComicPageViewState();
}

class _ComicPageViewState extends State<_ComicPageView> {
  /// 本地记忆 Future：rebuild 不重发（ensure 内部还有缓存/在途去重双保险）
  late Future<File> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // 上报视口（postFrame 后调用，避免 build 期副作用）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  // imageLoader 加载图片
  Future<File> _load() => widget.loader.ensure(
        widget.page,
        sourceKey: widget.sourceKey,
        comicId: widget.comicId,
        epId: widget.epId,
      );

  // 删 temp 重试
  void _retry() {
    setState(() {
      // 删除旧 temp file and retry download
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
          return _PageError(onRetry: _retry);
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // get image cache file
        final file = snapshot.data!;
        // 限宽解码：物理像素宽，防全尺寸大图撑爆内存
        final mq = MediaQuery.of(context);
        final targetWidth = (mq.size.width * mq.devicePixelRatio).round();
        // 渲染 image 
        return Image(
          image: ResizeImage(
            FileImage(file),
            width: targetWidth,
            allowUpscaling: false,
          ),
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
          // 父 -> retry -> 子 error page -> 用户判断是否需要 retry
          errorBuilder: (_, __, ___) => _PageError(onRetry: _retry),
        );
      },
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, color: iconPlaceholder, size: 40),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('加载失败 · 重试')),
          ],
        ),
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