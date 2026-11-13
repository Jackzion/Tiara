import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/database/models/rules_model.dart';
import 'package:movies/data/models/play_context.dart';
import 'package:movies/data/models/source_rule.dart';
import 'package:movies/network/rule_engine.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/screens/source_sheet/source_import_dialog.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

/// 单个源的搜索状态
enum SourceSearchStatus { pending, success, empty, error }

/// 单个源在面板里的一行数据
class _SourceRow {
  final SourceRule rule;
  SourceSearchStatus status;
  List<SearchItem> items;
  String? errorMessage;

  _SourceRow(this.rule) : status = SourceSearchStatus.pending, items = const [];
}

/// 视频源选择底部面板
///
/// 打开时对所有已导入规则并行 search；点结果 → queryChapters → pop(PlayContext)
class SourceSheet extends ConsumerStatefulWidget {
  /// 搜索关键词（一般传番剧中名，无则日名）
  final String keyword;

  /// Bangumi ID
  final int animeId;

  /// 详情页标题（进 PlayContext.title 时可用站内结果名覆盖）
  final String animeTitle;

  /// 用户点的集号（1-based），可空
  final int? preferredEpisode;

  const SourceSheet({
    super.key,
    required this.keyword,
    required this.animeId,
    required this.animeTitle,
    this.preferredEpisode,
  });

  @override
  ConsumerState<SourceSheet> createState() => _SourceSheetState();
}

class _SourceSheetState extends ConsumerState<SourceSheet> {
  /// 搜索结果行列表
  final List<_SourceRow> _rows = [];

  /// 搜索取消令牌
  /// 打开时创建，关闭时销毁
  /// 用于取消并行 search
  late final CancelToken _cancelToken;

  /// 是否正在加载规则
  bool _loadingRules = true;

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    // 面板关闭时取消所有在途 HTTP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 确保能拿到 ModalRoute 做 dispose 钩子；简单起见在 dispose 里 cancel
    });
    _startSearch();
  }

  @override
  void dispose() {
    // 面板关闭时取消所有在途 HTTP
    _cancelToken.cancel();
    super.dispose();
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
              // 顶部把手 + 标题 + 关键词
              Padding(
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
                    Text('选择视频源', style: heading1),
                    addVerticalSpace(4),
                    Text(
                      '关键词：${widget.keyword}'
                      '${widget.preferredEpisode != null ? '  ·  目标第 ${widget.preferredEpisode} 集' : ''}',
                      style: body3Regular.copyWith(color: posterBorder),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  void _startSearch() async {
    // 加载所有规则
    final ruleRepo = await ref.read(rulesRepositoryProvider.future);
    final rules = ruleRepo.getAll();

    // 先判断组件是否还存活 if(!mounted) ，避免在 dispose 后调用 setState
    if (!mounted) return;
    // init search rows
    setState(() {
      _loadingRules = false;
      _rows
        ..clear()
        ..addAll(rules.map(_SourceRow.new));
    });
    if (rules.isEmpty) return;

    // 并行搜所有源；单个失败不影响其它
    final engine = ref.read(ruleEngineProvider);
    await Future.wait(rules.map((rule) => _searchOne(engine, rule)));
    // 若组件还存活，更新所有行的状态
    if (mounted) setState(() {});
  }

  /// 对单个源 search 并更新 search_row 行状态
  Future<void> _searchOne(RuleEngine engine, SourceRule rule) async {
    // 找到对应行
    final row = _rows.firstWhere((r) => r.rule.nameKey == rule.nameKey);
    try {
      // search Items
      final items = await engine.search(
        rule,
        widget.keyword,
        cancelToken: _cancelToken,
      );

      if (_cancelToken.isCancelled) return;

      // 级联操作更新 sourceRow 状态和 items
      // 级联操作对连续操作对象能省对象名
      row
        ..items = items
        ..status = items.isEmpty
            ? SourceSearchStatus.empty
            : SourceSearchStatus.success;
    } catch (e) {
      if (!mounted) return;
      row
        ..status = SourceSearchStatus.error
        ..errorMessage = e.toString();
    }
  }

  /// 点某条搜索结果：拉线路分集 → pop(PlayContext)
  Future<void> _onTapItem(_SourceRow row, SearchItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(ruleEngineProvider);

    // 显示 loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: searchBarBackground,
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在获取播放列表…', style: body2Regular),
          ],
        ),
      ),
    );

    try {
      // 拉线路分集
      final roads = await engine.queryChapters(
        row.rule,
        item.src,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // 关 loading dialog

      // 构建 PlayContext
      final contextArgs = PlayContext(
        animeId: widget.animeId,
        title: item.name,
        rule: row.rule,
        detailUrl: item.src,
        roads: roads,
        preferredEpisode: widget.preferredEpisode,
      );
      // 把 PlayContext 交给路由（上层 pop 整个 Sheet）
      // 详情页（打开者）可直接使用： final result = await showModalBottomSheet<PlayContext>(...);
      Navigator.of(context).pop(contextArgs);
    } on ChapterEmptyException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('未能获取播放列表：$e')));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('未能获取播放列表：$e')));
    }
  }

  Widget _buildBody(ScrollController scrollController) {
    // 加载中
    if (_loadingRules) {
      return const Center(child: CircularProgressIndicator());
    }
    // 没有规则 - 提示导入规则 showSourceImportDialog
    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('还没有导入规则', style: body2Regular),
            addVerticalSpace(12),
            ElevatedButton.icon(
              onPressed: () async {
                // 等待导入规则完成
                await showSourceImportDialog(context);
                // 导入完成后，重新搜索
                if (mounted) {
                  setState(() => _rows.clear());
                  _startSearch();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('导入规则'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _rows.length,
      itemBuilder: (context, index) => _buildSourceSection(_rows[index]),
    );
  }

  /// 每个源的搜索结果项
  Widget _buildSourceSection(_SourceRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, size: 16, color: posterBorder),
              const SizedBox(width: 6),
              Text(row.rule.name, style: body2Bold),
              const SizedBox(width: 8),
              _StatusChip(status: row.status),
            ],
          ),
          addVerticalSpace(6),
          switch (row.status) {
            SourceSearchStatus.pending => const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            SourceSearchStatus.empty => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '无结果',
                  style: body3Regular.copyWith(color: posterBorder),
                ),
              ),
            SourceSearchStatus.error => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '错误：${row.errorMessage ?? '未知'}',
                  style: body3Regular.copyWith(color: dangerRed),
                ),
              ),
            SourceSearchStatus.success => Column(
                children: [
                  // 对 search_row 的每个 searchItem 显示  ListTile 组件
                  // 最多显示 30 条
                  for (final item in row.items.take(30))
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(item.name, style: body2Regular),
                      trailing: Icon(
                        Icons.play_arrow,
                        color: posterBorder,
                      ),
                      onTap: () => _onTapItem(row, item),
                    ),
                  if (row.items.length > 30)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        '仅显示前 30 条，共 ${row.items.length} 条',
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
}

/// 搜索状态芯片
class _StatusChip extends StatelessWidget {
  final SourceSearchStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SourceSearchStatus.pending => ('搜索中', accentAmber),
      SourceSearchStatus.success => ('可用', successGreen),
      SourceSearchStatus.empty => ('空', posterBorder),
      SourceSearchStatus.error => ('失败', dangerRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: body3Regular.copyWith(color: color)),
    );
  }
}

/// 便捷入口：弹出选源面板，返回 PlayContext（取消则 null）
Future<PlayContext?> showSourceSheet(
  BuildContext context, {
  required String keyword,
  required int animeId,
  required String animeTitle,
  int? preferredEpisode,
}) {
  // 造一条 ModalBottomSheetRoute 并 push —— 浮层出现（动画、遮罩、手势） -> pop -> future.value -> playContext
  return showModalBottomSheet<PlayContext>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SourceSheet(
      keyword: keyword,
      animeId: animeId,
      animeTitle: animeTitle,
      preferredEpisode: preferredEpisode,
    ),
  );
}