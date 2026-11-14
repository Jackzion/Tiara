import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:movies/ui/theme/archive_tokens.dart';

class ArchiveWindowBar extends StatelessWidget {
  const ArchiveWindowBar({super.key, this.title = 'TIARA ARCHIVE'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);

    return WindowTitleBarBox(
      child: Container(
        decoration: BoxDecoration(
          color: tone.surface,
          border: Border(
            bottom: BorderSide(
              color: tone.hairline,
              width: ArchiveGeometry.hairlineWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            // 1. 左侧：档案编号/Logo 区 (不可拖拽，或者也可以做成拖拽)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // 模拟一个极简的档案图标
                  Icon(Icons.inventory_2_outlined, size: 14, color: tone.muted),
                  const SizedBox(width: 8),
                  // 使用你的 ArchiveType.code 字体
                  Text(
                    title,
                    style: ArchiveType.code.copyWith(color: tone.muted),
                  ),
                ],
              ),
            ),

            // 2. 中间：拖拽区 (Expanded 撑满剩余空间)
            Expanded(
              child: MoveWindow(
                // 可以在这里加一个小手光标，提示用户可拖拽
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    height: ArchiveGeometry.headerHeight, // 48.0，适合拖拽的高度
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

            // 3. 右侧：极简窗口控制按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ArchiveWindowButton(
                  icon: Icons.remove,
                  onTap: () => appWindow.minimize(),
                ),
                _ArchiveWindowButton(
                  icon: Icons.crop_square, // 最大化/还原图标
                  onTap: () => appWindow.maximizeOrRestore(),
                ),
                _ArchiveWindowButton(
                  icon: Icons.close,
                  isClose: true,
                  onTap: () => appWindow.close(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 自定义的极简控制按钮
class _ArchiveWindowButton extends StatefulWidget {
  const _ArchiveWindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  @override
  State<_ArchiveWindowButton> createState() => _ArchiveWindowButtonState();
}

class _ArchiveWindowButtonState extends State<_ArchiveWindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);

    // 悬停颜色逻辑：普通按钮悬停用 raised，关闭按钮悬停用砖红
    Color bgColor = Colors.transparent;
    Color iconColor = tone.muted;

    if (_isHovered) {
      if (widget.isClose) {
        bgColor = ArchivePalette.error;
        iconColor = ArchivePalette.milk; // 白底/奶白图标
      } else {
        bgColor = tone.raised;
        iconColor = tone.ink;
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ArchiveMotion.contact, // 120ms，你的设计令牌中的接触响应时间
          width: 46, // ArchiveGeometry.iconControlSize 近似值
          height: ArchiveGeometry.headerHeight, // 48
          color: bgColor,
          child: Icon(
            widget.icon,
            size: 14, // 保持图标纤细小巧
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
