import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

/// 选书结果（NovelReader 的入参）
class NovelSelection {
  const NovelSelection({
    required this.sourceKey,
    required this.bookId,
    required this.chapterId,
    required this.title,
    required this.chapterTitle,
  });

  final String sourceKey;
  final String bookId;
  final String chapterId;
  final String title;
  final String chapterTitle;

  @override
  String toString() => 'NovelSelection($sourceKey, $bookId, $chapterId)';
}

/// 便捷入口：弹出选书面板，返回 NovelSelection（取消则 null）
Future<NovelSelection?> showNovelSourceSheet(
  BuildContext context, {
  required String keyword,
  required int animeId,
  required String animeTitle,
}) {
  return showModalBottomSheet<NovelSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NovelSourceSheet(
      keyword: keyword,
      animeId: animeId,
      animeTitle: animeTitle,
    ),
  );
}

class NovelSourceSheet extends ConsumerStatefulWidget {
  const NovelSourceSheet({
    super.key,
    required this.keyword,
    required this.animeId,
    required this.animeTitle,
  });

  /// 搜索关键词（一般传中文标题）
  final String keyword;

  /// Bangumi ID（留参，阅读历史等后续用）
  final int animeId;
  final String animeTitle;

  @override
  ConsumerState<NovelSourceSheet> createState() => _NovelSourceSheetState();
}

class _NovelSourceSheetState extends ConsumerState<NovelSourceSheet> {
  /// 搜索结果（null = 搜索中）
  List<NovelMatch>? _matches;
  String? _error;

  /// 选中书 + 章节目录
  NovelMatch? _selected;
  List<NovelChapter>? _chapters;
  bool _loadingChapters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search();
    });
  }

  Future<void> _search() async {
    setState(() {
      _matches = null;
      _error = null;
    });
    try {
      final repo = ref.read(novelRepositoryProvider);
      final matches = await repo.matchSearch(widget.keyword);
      if (!mounted) return;
      setState(() => _matches = matches);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _onTapMatch(NovelMatch match) async {
    setState(() {
      _selected = match;
      _chapters = null;
      _loadingChapters = true;
    });
    try {
      final repo = ref.read(novelRepositoryProvider);
      final detail = await repo.loadInfo(match.sourceKey, match.bookId);
      if (!mounted) return;
      setState(() {
        _chapters = detail.chapters;
        _loadingChapters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingChapters = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('获取目录失败：$e')));
    }
  }

  void _onTapChapter(NovelMatch match, NovelChapter chapter) {
    Navigator.of(context).pop(
      NovelSelection(
        sourceKey: match.sourceKey,
        bookId: match.bookId,
        chapterId: chapter.chapterId,
        title: match.title,
        chapterTitle: chapter.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: searchBarBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  /// 顶部把手 + 标题 + 关键词
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: buttonGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          addVerticalSpace(12),
          Text('选择书源', style: heading1),
          addVerticalSpace(4),
          Text(
            '关键词：${widget.keyword}',
            style: body3Regular.copyWith(color: posterBorder),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('搜索失败：$_error', style: body2Regular),
            addVerticalSpace(8),
            TextButton(onPressed: _search, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_matches == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_matches!.isEmpty) {
      return Center(
        child: Text(
          '无匹配书籍',
          style: body2Regular.copyWith(color: posterBorder),
        ),
      );
    }
    return Material(
      color: searchBarBackground,
      child: ListView.builder(
        controller: controller,
        itemCount: _matches!.length,
        itemBuilder: (context, index) => _buildMatchTile(_matches![index]),
      ),
    );
  }

  /// 一条匹配；选中时展开章节目录
  Widget _buildMatchTile(NovelMatch match) {
    final isSelected = _selected?.sourceKey == match.sourceKey &&
        _selected?.bookId == match.bookId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: match.novel.cover != null
              ? Image.network(
                  match.novel.cover!,
                  cacheWidth: 96,
                  width: 36,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image, color: posterBorder),
                )
              : const Icon(Icons.menu_book, color: posterBorder),
          title: Text(match.title, style: body2Regular),
          subtitle: match.novel.subtitle == null
              ? null
              : Text(
                  match.novel.subtitle!,
                  style: body3Regular.copyWith(color: posterBorder),
                ),
          trailing: const Icon(Icons.chevron_right, color: posterBorder),
          onTap: () => _onTapMatch(match),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _loadingChapters
                ? const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : _chapters == null || _chapters!.isEmpty
                    ? Text(
                        '暂无章节',
                        style: body3Regular.copyWith(color: posterBorder),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final chapter in _chapters!.take(200))
                            ActionChip(
                              label: Text(
                                chapter.volumeTitle == null ||
                                        chapter.volumeTitle!.isEmpty
                                    ? chapter.title
                                    : '${chapter.volumeTitle} · ${chapter.title}',
                                style: body3Regular,
                              ),
                              onPressed: () => _onTapChapter(match, chapter),
                            ),
                        ],
                      ),
          ),
      ],
    );
  }
}
