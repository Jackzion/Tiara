import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:movies/state/comic_source_controller.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

/// 选图源结果（Phase 3 阅读器的入参前身）
class ComicSelection {
  const ComicSelection({
    required this.sourceKey,
    required this.comicId,
    required this.epId,
    required this.title,
    required this.epTitle,
  });

  final String sourceKey;
  final String comicId;
  final String epId;
  final String title;
  final String epTitle;

  @override
  String toString() => 'ComicSelection($sourceKey, $comicId, $epId)';
}

/// 便捷入口：弹出选图源面板，返回 ComicSelection（取消则 null）
/// 用法对称 showSourceSheet（video）
Future<ComicSelection?> showComicSourceSheet(
  BuildContext context, {
  required String keyword,
  required int animeId,
  required String animeTitle,
}) {
  return showModalBottomSheet<ComicSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ComicSourceSheet(
      keyword: keyword,
      animeId: animeId,
      animeTitle: animeTitle,
    ),
  );
}

class ComicSourceSheet extends ConsumerStatefulWidget {
  const ComicSourceSheet({
    super.key,
    required this.keyword,
    required this.animeId,
    required this.animeTitle,
  });

  /// 搜索关键词（一般传中文标题，无则日文）
  final String keyword;

  /// Bangumi ID（进 ComicSelection 之外的留参，阅读历史等后续用）
  final int animeId;
  final String animeTitle;

  @override
  ConsumerState<ComicSourceSheet> createState() => _ComicSourceSheetState();
}

class _ComicSourceSheetState extends ConsumerState<ComicSourceSheet> {
  @override
  Widget build(BuildContext context) {
    final sheetAsync = ref.watch(comicSourceControllerProvider(widget.keyword));
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
              Expanded(
                child: sheetAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('图源加载失败：$e', style: body2Regular)),
                  data: (state) => _buildBody(scrollController, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 顶部把手 + 标题 + 关键词（对称视频面板）
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
          Text('选择图源', style: heading1),
          addVerticalSpace(4),
          Text(
            '关键词：${widget.keyword}',
            style: body3Regular.copyWith(color: posterBorder),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController controller, ComicSheetState state) {
    // 错误态①：图源未就绪（规则未装载 / 仓库为空）
    if (state.rows.isEmpty) {
      return const _EmptyHint('图源未就绪（规则未装载）');
    }
    // 错误态③：无匹配（所有行都出结果了，但全空）
    final allSettled = state.rows.every(
      (r) => r.status != ComicSourceRowStatus.pending,
    );
    final anyMatch = state.rows.any((r) => r.matches.isNotEmpty);
    if (allSettled && !anyMatch) {
      return const _EmptyHint('无匹配图源');
    }
    // 包一层不透明 Material：ListTile 的水波纹要有 Material 承载
    // （modal bottom sheet 透明背景 + 自绘 Container 会触发「ink splashes may be invisible」）
    return Material(
      color: searchBarBackground,
      child: ListView.builder(
        controller: controller,
        itemCount: state.rows.length,
        itemBuilder: (context, index) =>
            _buildSourceSection(state.rows[index], state),
      ),
    );
  }

  /// 每个源一节：源名 + 状态 chip + 匹配列表（点开展章节）
  Widget _buildSourceSection(ComicSourceRow row, ComicSheetState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, size: 16, color: posterBorder),
              const SizedBox(width: 6),
              Text(row.sourceName, style: body2Bold),
              const SizedBox(width: 8),
              _StatusChip(status: row.status),
            ],
          ),
          addVerticalSpace(6),
          switch (row.status) {
            ComicSourceRowStatus.pending => const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            ComicSourceRowStatus.empty => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '无结果',
                style: body3Regular.copyWith(color: posterBorder),
              ),
            ),
            // 错误态②：规则抛错，只影响本行
            ComicSourceRowStatus.error => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '错误：${row.errorMessage ?? '未知'}',
                style: body3Regular.copyWith(color: dangerRed),
              ),
            ),
            ComicSourceRowStatus.success => Column(
              children: [
                for (final match in row.matches.take(30))
                  _buildMatchTile(match, state),
                if (row.matches.length > 30)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      '仅显示前 30 条，共 ${row.matches.length} 条',
                      style: body3Regular.copyWith(color: posterBorder),
                    ),
                  ),
              ],
            ),
          },
        ],
      ),
    );
  }

  /// 一条匹配；选中时展开章节列表
  Widget _buildMatchTile(ComicMatch match, ComicSheetState state) {
    final isSelected =
        state.selected != null &&
        state.selected!.sourceKey == match.sourceKey &&
        state.selected!.comicId == match.comicId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: match.comic.cover != null
              ? Image.network(
                  match.comic.cover!,
                  width: 36,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: posterBorder),
                )
              : const Icon(Icons.menu_book, color: posterBorder),
          title: Text(match.title, style: body2Regular),
          subtitle: match.comic.subtitle == null
              ? null
              : Text(
                  match.comic.subtitle!,
                  style: body3Regular.copyWith(color: posterBorder),
                ),
          trailing: const Icon(Icons.chevron_right, color: posterBorder),
          onTap: () => _onTapMatch(match),
        ),
        // 选中项：展开章节（顺序即阅读顺序）
        if (isSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: state.chapters.isEmpty
                ? Text('暂无章节', style: body3Regular.copyWith(color: posterBorder))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final chapter in state.chapters)
                        ActionChip(
                          label: Text(chapter.title, style: body3Regular),
                          onPressed: () => _onTapChapter(match, chapter),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  /// 点匹配项 → 拉章节
  Future<void> _onTapMatch(ComicMatch match) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: searchBarBackground,
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('正在获取章节列表…', style: body2Regular),
          ],
        ),
      ),
    );
    try {
      await ref
          .read(comicSourceControllerProvider(widget.keyword).notifier)
          .select(match);
      if (!mounted) return;
      Navigator.of(context).pop(); // 关 loading
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      logError('[ComicSourceSheet]获取章节失败：$e');
      // 210 = 图源 API 限频（拷贝漫画等），给用户可行动的话术
      final msg = e.toString().contains('210')
          ? '访问太频繁，请稍后再试'
          : '获取章节失败：$e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// 点章节 → pop(ComicSelection)
  void _onTapChapter(ComicMatch match, ComicChapter chapter) {
    Navigator.of(context).pop(
      ComicSelection(
        sourceKey: match.sourceKey,
        comicId: match.comicId,
        epId: chapter.epId,
        title: match.title,
        epTitle: chapter.title,
      ),
    );
  }
}

/// 空态提示（图源未就绪 / 无匹配）
class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: body2Regular.copyWith(color: posterBorder)),
    );
  }
}

/// 搜索状态 chip
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ComicSourceRowStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ComicSourceRowStatus.pending => ('搜索中', accentAmber),
      ComicSourceRowStatus.success => ('可用', successGreen),
      ComicSourceRowStatus.empty => ('空', buttonGrey),
      ComicSourceRowStatus.error => ('失败', dangerRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: body3Regular.copyWith(color: color)),
    );
  }
}
