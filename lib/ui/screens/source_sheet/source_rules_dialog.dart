import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/source_rule.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/screens/source_sheet/source_import_dialog.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

class SourceRulesDialog extends ConsumerStatefulWidget {
  const SourceRulesDialog({super.key});

  @override
  ConsumerState<SourceRulesDialog> createState() => _SourceRulesDialogState();
}

class _SourceRulesDialogState extends ConsumerState<SourceRulesDialog> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(rulesRepositoryProvider.future),
      builder: (context, snapshot) {
        final repo = snapshot.data;
        final rules = repo?.getAll() ?? const <SourceRule>[];

        return AlertDialog(
          backgroundColor: searchBarBackground,
          title: Text('Source Rules (${rules.length})', style: heading1),
          content: SizedBox(
            width: 480,
            height: 360,
            child: !snapshot.hasData
                ? const Center(child: CircularProgressIndicator())
                : rules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('还没有规则', style: body2Regular),
                        const SizedBox(height: 12),
                        Text(
                          '点 Import 粘贴 Kazumi 规则 JSON',
                          style: body3Regular.copyWith(color: posterBorder),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: rules.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return ListTile(
                        dense: true,
                        title: Text(rule.name, style: body2Bold),
                        subtitle: Text(
                          rule.baseUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body3Regular.copyWith(color: posterBorder),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: ArchivePalette.muted,
                          ),
                          onPressed: () => _confirmDelete(rule),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: body2Regular),
            ),
            addHorizontalSpace(4),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await showSourceImportDialog(context);
                // 再打开 Sources 可见新数据
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Import', style: body2Bold),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(SourceRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: searchBarBackground,
        title: Text('删除 ${rule.name}?', style: heading2),
        content: Text('删除后需重新导入。', style: body2Regular),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: body2Regular),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: body2Bold),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final repo = await ref.read(rulesRepositoryProvider.future);
    await repo.removeByName(rule.name);
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${rule.name}')),
      );
    }
  }
}

Future<void> showSourceRulesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const SourceRulesDialog(),
  );
}
