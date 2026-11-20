import 'dart:async';
import 'dart:convert';

import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'novel_reader_controller.g.dart';

/// 小说阅读器状态：一章的段落 + 目录位置 + 上下章 + 恢复段落。
class NovelReaderState {
  const NovelReaderState({
    required this.bookTitle,
    required this.chapterTitle,
    required this.paragraphs,
    required this.chapterIndex,
    required this.chapterCount,
    required this.initialParagraph,
    this.prevChapterId,
    this.prevChapterTitle,
    this.nextChapterId,
    this.nextChapterTitle,
  });

  /// 书名（顶栏兜底）
  final String bookTitle;

  /// 章名（顶栏主显示）
  final String chapterTitle;

  /// 本章段落（正文以 \n\n 分段；插图段为 <!--image--> 标记串）
  final List<String> paragraphs;

  /// 当前章下标（0 起）与总章数（进度显示用）
  final int chapterIndex;
  final int chapterCount;

  /// 书库恢复的目标段落（0 = 从头读）
  final int initialParagraph;

  /// 上一章 / 下一章（无则 null）
  final String? prevChapterId;
  final String? prevChapterTitle;
  final String? nextChapterId;
  final String? nextChapterTitle;

  NovelReaderState copyWith({
    String? bookTitle,
    String? chapterTitle,
    List<String>? paragraphs,
    int? chapterIndex,
    int? chapterCount,
    int? initialParagraph,
    String? prevChapterId,
    String? prevChapterTitle,
    String? nextChapterId,
    String? nextChapterTitle,
  }) {
    return NovelReaderState(
      bookTitle: bookTitle ?? this.bookTitle,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      paragraphs: paragraphs ?? this.paragraphs,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterCount: chapterCount ?? this.chapterCount,
      initialParagraph: initialParagraph ?? this.initialParagraph,
      prevChapterId: prevChapterId ?? this.prevChapterId,
      prevChapterTitle: prevChapterTitle ?? this.prevChapterTitle,
      nextChapterId: nextChapterId ?? this.nextChapterId,
      nextChapterTitle: nextChapterTitle ?? this.nextChapterTitle,
    );
  }
}

/// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）
@riverpod
class NovelReaderController extends _$NovelReaderController {
  late String _sourceKey;
  late String _bookId;
  late String _chapterId;

  @override
  Future<NovelReaderState> build(
    String sourceKey,
    String bookId,
    String chapterId,
  ) async {
    _sourceKey = sourceKey;
    _bookId = bookId;
    _chapterId = chapterId;
    final repo = ref.read(novelRepositoryProvider);

    // 目录 + 本章正文
    final detail = await repo.loadInfo(sourceKey, bookId);
    final text = await repo.loadText(sourceKey, bookId, chapterId);
    final paragraphs = [
      for (final p in text.split('\n\n'))
        if (p.trim().isNotEmpty) p.trim(),
    ];

    // chapters 顺序即阅读顺序，定位当前章的上下章
    final chapters = detail.chapters;
    final index = chapters.indexWhere((c) => c.chapterId == chapterId);

    // 书库恢复：上次读到的段落（仅当上次就是本章时生效）
    var initialParagraph = 0;
    try {
      final saved = await ref
          .read(libraryRepositoryProvider)
          .findNovel(sourceKey: sourceKey, bookId: bookId);
      if (saved?.lastUnitId == chapterId && saved?.playParamsJson != null) {
        final progress = NovelProgress.fromJson(
          jsonDecode(saved!.playParamsJson!) as Map<String, dynamic>,
        );
        initialParagraph = progress.paragraphIndex.clamp(0, paragraphs.length);
      }
    } catch (e) {
      // 进度损坏不阻塞阅读
      logError('[NovelReader] 读取进度失败: $e');
    }

    return NovelReaderState(
      bookTitle: detail.title,
      chapterTitle: index >= 0 ? chapters[index].title : chapterId,
      paragraphs: paragraphs,
      chapterIndex: index >= 0 ? index : 0,
      chapterCount: chapters.length,
      initialParagraph: initialParagraph,
      prevChapterId: (index > 0) ? chapters[index - 1].chapterId : null,
      prevChapterTitle: (index > 0) ? chapters[index - 1].title : null,
      nextChapterId:
          (index >= 0 && index + 1 < chapters.length)
              ? chapters[index + 1].chapterId
              : null,
      nextChapterTitle:
          (index >= 0 && index + 1 < chapters.length)
              ? chapters[index + 1].title
              : null,
    );
  }

  /// 阅读位置变化时调用：把「读到哪」落库（fire-and-forget，失败不影响阅读）。
  void touchProgress(int paragraphIndex, double fraction, {double? fontSize}) {
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    unawaited(
      ref
          .read(libraryRepositoryProvider)
          .saveNovelRead(
            sourceKey: _sourceKey,
            bookId: _bookId,
            title: current.bookTitle,
            chapterId: _chapterId,
            chapterTitle: current.chapterTitle,
            progress: NovelProgress(
              paragraphIndex: paragraphIndex,
              fraction: fraction.clamp(0, 1),
              fontSize: fontSize,
            ),
          )
          .catchError((Object e) {
            logError('[NovelReader] 保存进度失败: $e');
          }),
    );
  }
}
