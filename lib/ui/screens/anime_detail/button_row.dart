import 'package:flutter/material.dart';
import 'package:movies/ui/theme/archive_tokens.dart';

/// 收藏按钮点击回调类型
typedef OnFavoriteSelected = void Function();

/// 详情页动作行：收藏 / 评分 / 分享。
///
/// 纸底 + 发丝线的小方钮；选中只加 10% 墨，不做心跳循环动画。
class ButtonRow extends StatelessWidget {
  final bool favoriteSelected;
  final OnFavoriteSelected onFavoriteSelected;

  const ButtonRow({
    super.key,
    required this.favoriteSelected,
    required this.onFavoriteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Row(
      children: [
        _ActionButton(
          icon: favoriteSelected ? Icons.favorite : Icons.favorite_border,
          label: favoriteSelected ? '已收藏' : '收藏',
          selected: favoriteSelected,
          iconColor: favoriteSelected ? ArchivePalette.error : null,
          onTap: onFavoriteSelected,
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.thumb_up_alt_outlined,
          label: '评分',
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionButton(icon: Icons.ios_share, label: '分享', onTap: () {}),
        const Spacer(),
        // 右侧留一枚档案副号，平衡动作行的重量
        Text(
          'WK-ENTRY',
          style: ArchiveType.code.copyWith(color: tone.hairline),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final fg = tone.ink;
    return SizedBox(
      height: 40,
      child: Material(
        color: selected ? tone.raisedHigh : tone.milk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius),
          side: BorderSide(
            color: selected ? tone.hairlineStrong : tone.hairline,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: tone.raisedHigh,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor ?? fg),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: ArchiveType.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
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
