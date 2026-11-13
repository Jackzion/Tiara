import 'package:flutter/material.dart';

import 'package:movies/ui/widgets/archive/archive_ui.dart';

typedef OnMoreClicked = void Function();

/// 分类区块头：档案编号 + 细线 + 标题 + 右侧次级动作。
class TitleRow extends StatelessWidget {
  final String text;
  final OnMoreClicked onMoreClicked;

  /// 档案地址，如 `01 / TRENDING`。为空时只显示标题。
  final String? code;

  const TitleRow({
    super.key,
    required this.text,
    required this.onMoreClicked,
    this.code,
  });

  @override
  Widget build(BuildContext context) {
    return ArchiveSection(
      title: text.trim(),
      code: code ?? text.trim().toUpperCase(),
      trailing: ArchiveTextButton(
        onPressed: onMoreClicked,
        child: const Text('全部'),
      ),
    );
  }
}
