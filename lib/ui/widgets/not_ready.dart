import 'package:flutter/material.dart';
import 'package:movies/ui/theme/archive_tokens.dart';

/// 加载中占位组件。
class NotReady extends StatelessWidget {
  const NotReady({super.key, this.label = '正在载入'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ArchivePalette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ArchivePalette.ink,
                backgroundColor: ArchivePalette.hairline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: ArchiveType.code.copyWith(color: ArchivePalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 整页级错误占位。
class ArchiveLoadError extends StatelessWidget {
  const ArchiveLoadError({
    super.key,
    required this.message,
    this.label = '载入失败',
  });

  final String message;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ArchivePalette.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ERROR / LOAD',
                  style: ArchiveType.code.copyWith(
                    color: ArchivePalette.error,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: ArchiveType.section.copyWith(
                    color: ArchivePalette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  message,
                  style: ArchiveType.meta.copyWith(
                    color: ArchivePalette.muted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
