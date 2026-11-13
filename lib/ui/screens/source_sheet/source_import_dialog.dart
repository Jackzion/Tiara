import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/rule_import_parser.dart';
import 'package:movies/utils/utils.dart';

class SourceImportDialog extends ConsumerStatefulWidget {
  const SourceImportDialog({super.key});

  @override
  ConsumerState<SourceImportDialog> createState() => _SourceImportDialogState();
}

class _SourceImportDialogState extends ConsumerState<SourceImportDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: searchBarBackground,
      title: Text('Import Source Rules', style: heading1),
      content: SizedBox(
        width: 480,
        child: Column(
          children: [
            Text(
              '支持单条 JSON / JSON 数组 / 多行 / kazumi:// 链接',
              style: body2Regular.copyWith(color: posterBorder),
            ),
            addVerticalSpace(12),
            TextField(
              controller: _textController,
              maxLines: 10,
              minLines: 1,
              style: body2Regular,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                filled: true,
                fillColor: ArchivePalette.raised,
                hintText: '{ "name": "...", "baseURL": "...", ... }',
                hintStyle: body3Regular.copyWith(color: posterBorder),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArchiveGeometry.panelRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: body2Regular),
        ),
        addHorizontalSpace(4),
        TextButton(
          onPressed: _importing ? null : () => _pasteFromClipboard(),
          child: Text('Paste', style: body2Regular),
        ),
        addHorizontalSpace(4),
        TextButton(
          onPressed: _importing ? null : () => _doImport(),
          child: _importing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Import', style: body2Bold),
        ),
      ],
    );
  }

  /// 从剪贴板粘贴文本
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;

    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('剪贴板是空的')));
      return;
    }
    _textController.text = text;
  }

  /// 导入文本规则
  Future<void> _doImport() async {
    // 避免重复点击
    if (_importing) return;
    setState(() {
      _importing = true;
    });

    // pop 之前抓住 messenger 避免 context 失效
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 解析 ruleParser
      final parseResult = RuleImportParser.parse(_textController.text);

      // 合并入库
      final rulesRepository = await ref.read(rulesRepositoryProvider.future);
      final merged = await rulesRepository.mergeRules(
        parseResult.rules,
        failures: parseResult.failures,
        batchDuplicateCount: parseResult.duplicateCount,
      );

      if (merged.importedCount == 0 && merged.failures.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('没有解析到规则')));
        return;
      }
      if (!mounted) return;

      if (merged.importedCount == 0) {
        // 全部解析失败：不写盘，提示错误
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text('导入失败：${merged.failures.join('；')}')),
        );
        return;
      }

      // 部分解析成功：提示成功
      Navigator.of(context).pop();
      final buf = StringBuffer('导入 ${merged.importedCount} 条');
      buf.write('（新增 ${merged.addedCount}，覆盖 ${merged.overwrittenCount}）');
      if (merged.hasFailures) {
        buf.write('；失败 ${merged.failures.length}');
      }
      messenger.showSnackBar(SnackBar(content: Text(buf.toString())));
      if (merged.hasFailures) {
        debugPrint('[Import] failures:\n${merged.failures.join('\n')}');
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }
}

/// 显示导入对话框
Future<void> showSourceImportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const SourceImportDialog(),
  );
}
