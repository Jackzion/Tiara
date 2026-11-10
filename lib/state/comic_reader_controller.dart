import 'dart:async';

import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:movies/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_reader_controller.g.dart';

class ComicReaderState {
  const ComicReaderState({
    required this.pages,
    required this.chapterTitle,
    this.nextEpId,
    this.nextEpTitle,
    required this.readyIndexes,
  });

  /// 本章图片列表（顺序即阅读顺序）
  final List<ComicPage> pages;

  /// 章名（AppBar 显示）
  final String chapterTitle;

  /// 下一章（无则 null）
  final String? nextEpId;
  final String? nextEpTitle;

  /// 已就绪（下载/缓存完成）的页下标，进度指示用
  final Set<int> readyIndexes;

  ComicReaderState copyWith({
    List<ComicPage>? pages,
    String? chapterTitle,
    String? nextEpId,
    String? nextEpTitle,
    Set<int>? readyIndexes,
  }) {
    return ComicReaderState(
      pages: pages ?? this.pages,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      nextEpId: nextEpId ?? this.nextEpId,
      nextEpTitle: nextEpTitle ?? this.nextEpTitle,
      readyIndexes: readyIndexes ?? this.readyIndexes,
    );
  }
}

/// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）
@riverpod
class ComicReaderController extends _$ComicReaderController {
  /// build family
  late String _sourceKey;
  late String _comicId;
  late String _epId;

  @override
  Future<ComicReaderState> build(
    String sourceKey,
    String comicId,
    String epId,
  ) async {
    _sourceKey = sourceKey;
    _comicId = comicId;
    _epId = epId;
    final repo = await ref.read(comicRepositoryProvider.future);

    // 章节表 + 本章图片
    final chapters = await repo.loadChapters(sourceKey, comicId);
    final pages = await repo.loadPages(_sourceKey, _comicId, _epId);

    // chapters 顺序即阅读顺序，找当前章的下一章
    final index = chapters.indexWhere((c) => c.epId == _epId);
    return ComicReaderState(
      pages: pages,
      chapterTitle: index >= 0 ? chapters[index].title : '',
      nextEpId: (index >= 0 && index + 1 < chapters.length)
          ? chapters[index + 1].epId
          : null,
      nextEpTitle: (index >= 0 && index + 1 < chapters.length)
          ? chapters[index + 1].title
          : null,
      readyIndexes: {},
    );
  }

  /// 视窗进入第 index 张 image，确保本张 + 预取前后各两张
  /// 只在异步完成回调里写 state
  void notifyVisible(int index) {
    for (final int i in [index, index + 1, index + 2, index - 1, index - 2]) {
      unawaited(_touch(i));
    }
  }

  /// ensure index page
  Future<void> _touch(int index) async {
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null || index < 0 || index >= current.pages.length) return;

    final loader = ref.read(comicImageLoaderProvider);
    try {
      // ensure 视窗图片的下载，若没下则下载
      await loader.ensure(
        current.pages[index],
        sourceKey: _sourceKey,
        comicId: _comicId,
        epId: _epId,
      );
    } catch (e) {
      // 单张失败不打断 other page , error 由 index page 自己展示
      logError('[ComicReader] ensure 失败 p$index: $e');
      return;
    }
    if (!ref.mounted) return;

    final latest = state.value;
    if (latest == null || latest.readyIndexes.contains(index)) return;
    // set state with readyIndexes
    state = AsyncData(
      latest.copyWith(readyIndexes: {...latest.readyIndexes, index}),
    );
  }
}
