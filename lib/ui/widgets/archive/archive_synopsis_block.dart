import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movies/ui/theme/archive_tokens.dart';

/// 可折叠体区区块 widget
/// 结构（对照设计稿）：
/// - Header：`01 / SYNOPSIS` 码 + 发丝线 + 12px 折叠箭头
/// - Title：大标题（23/32，字距 0.5）
/// - Body：折叠态固定高度裁切 + 底部 48px 渐隐
///
/// 交互：点击切换折叠/展开（箭头 180° 翻转，300ms ease-out 原位增减高度）。
/// **原位折叠语义**：展开在文档流内长高（不浮层覆盖）；折叠态整棵子树
/// 滚动锁定（目录等内部滚动容器也不响应），滚动交给外层页面；
/// 展开态内容超出最大高度时内部滚动。
/// 内容不超出折叠高度时自动退化为普通区块（无渐隐/箭头/交互）。
class ArchiveSynopsisBlock extends StatefulWidget {
  const ArchiveSynopsisBlock({
    super.key,
    required this.code,
    required this.title,
    required this.child,
    this.collapsedHeight = 130,
    this.expandedHeight = 342,
    this.fadeColor,
  });

  /// 头部档案码（如 `01 / SYNOPSIS`）
  final String code;

  /// 大标题（如 `剧情简介`）
  final String title;

  /// 正文体
  final Widget child;

  /// 折叠态体区高度（设计稿 212 − 82 = 130）
  final double collapsedHeight;

  /// 展开态体区最大高度（设计稿 342），超出内部滚动
  final double expandedHeight;

  /// 渐隐遮罩底色（默认页面底色；放在异色面板上时传面板色）
  final Color? fadeColor;

  @override
  State<ArchiveSynopsisBlock> createState() => _ArchiveSynopsisBlockState();
}

class _ArchiveSynopsisBlockState extends State<ArchiveSynopsisBlock> {
  final _bodyKey = GlobalKey();
  bool _expanded = false;

  /// 内容是否超出折叠高度。null = 未测（首帧必须先按封顶排版，
  /// 否则未裁切的正文会造成瞬时溢出报错）。
  bool? _overflowing;

  /// 内容实测高度（展开态高度 = min(内容, expandedHeight)）
  double _contentHeight = 0;

  @override
  void initState() {
    super.initState();
    _scheduleOverflowCheck();
  }

  @override
  void didUpdateWidget(covariant ArchiveSynopsisBlock old) {
    super.didUpdateWidget(old);
    if (old.child != widget.child ||
        old.collapsedHeight != widget.collapsedHeight) {
      _scheduleOverflowCheck();
    }
  }

  void _scheduleOverflowCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      _contentHeight = box.size.height;
      final overflowing = box.size.height > widget.collapsedHeight;
      if (overflowing != _overflowing) {
        setState(() => _overflowing = overflowing);
      }
    });
  }

  void _toggle() {
    if (_overflowing != true) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tone),
          Padding(
            // TitleBlock 的上内边距（设计稿 12）
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.title,
              style: TextStyle(
                // 设计稿 Title：23/32 Bold，字距 0.5
                fontSize: 23,
                height: 32 / 23,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: tone.ink,
              ),
            ),
          ),
          Padding(
            // BodyBlock 的上内边距（设计稿 16）
            padding: const EdgeInsets.only(top: 16),
            child: _buildSlot(tone),
          ),
        ],
      ),
    );
  }

  /// 头部：码 + 发丝线 + 箭头（16px 行高，间距 10，设计稿 Header）
  Widget _buildHeader(ArchiveTone tone) {
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          Text(
            widget.code,
            style: TextStyle(
              // 设计稿 SectionIndex：11/16，字距 1.7
              fontSize: 11,
              height: 16 / 11,
              letterSpacing: 1.7,
              color: tone.muted,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(height: 1, thickness: ArchiveGeometry.dividerWidth),
          ),
          const SizedBox(width: 10),
          if (_overflowing == true)
            SizedBox(
              width: 12,
              height: 12,
              child: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: tone.muted,
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  /// 正文槽位：原位折叠，高度切换瞬时生效（不作高度动画 ——
  /// IntrinsicHeight 的内在尺寸缓存不会跟随动画高度重算，会引发
  /// 两栏结构的持续溢出；箭头翻转仍保留 300ms 过渡）。
  ///
  /// 三态：未测（首帧）先按折叠高度封顶排版，杜绝未裁切正文的瞬时溢出；
  /// 确认放得下 → 自然高度；确认超出 → 折叠交互。
  Widget _buildSlot(ArchiveTone tone) {
    final measured = KeyedSubtree(key: _bodyKey, child: widget.child);
    final bg = widget.fadeColor ?? ArchivePalette.background;

    // 折叠态同时锁住子树里的滚动容器（目录、分页列表等）：
    // 内部不再响应拖动/滚轮，滚动交给外层页面。
    final body = _expanded
        ? measured
        : ScrollConfiguration(
            behavior: const _LockedScrollBehavior(),
            child: measured,
          );

    final double target;
    if (_overflowing == false) {
      target = _contentHeight; // 放得下：自然高度
    } else if (_overflowing == true && _expanded) {
      target = math.min(_contentHeight, widget.expandedHeight);
    } else {
      target = widget.collapsedHeight; // 折叠 / 未测
    }

    return SizedBox(
      height: target,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              // 仅展开态允许滚动
              physics: _expanded ? null : const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(right: 8),
              child: body,
            ),
          ),
          if (_overflowing == true && !_expanded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: IgnorePointer(
                // 设计稿 FadeMask：48px 透明 → 底色
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bg.withValues(alpha: 0),
                        bg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 折叠态下让子树里所有滚动容器拒绝用户滚动（拖动、滚轮、键盘），
/// 滚动事件因此留给外层页面，而不是卡在目录/列表里。
class _LockedScrollBehavior extends ScrollBehavior {
  const _LockedScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const NeverScrollableScrollPhysics();
}
