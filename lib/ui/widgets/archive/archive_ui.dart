import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:movies/ui/theme/archive_tokens.dart';

/// 「纸与档案」公共控件库。
///
/// 纪律：内容用 [PaperPanel]（实心纸 + 0.6/0.7 发丝线 + 四角对位标），
/// 只有导航与真正浮起的层才用 [FrostedHeader] / [GlassCapsule]。

// ─────────────────────────────────────────────────────────
// 文字：档案编号 / 区块头 / 报头 / 路由标题
// ─────────────────────────────────────────────────────────

/// 等宽档案编号。`WK-00001`、`01 / TRENDING`、`01 / 04` 都用它。
class ArchiveCode extends StatelessWidget {
  const ArchiveCode(
    this.text, {
    super.key,
    this.inverse = false,
    this.color,
  });

  final String text;
  final bool inverse;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textScaler: TextScaler.noScaling,
      style: ArchiveType.code.copyWith(
        color: color ?? (inverse ? tone.surface : tone.muted),
      ),
    );
    if (!inverse) return label;
    return ColoredBox(
      color: tone.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: label,
      ),
    );
  }
}

/// 区块头：编号 → 渐隐细线 → 3×3 方块，下面是大标题与副标。
class ArchiveSection extends StatelessWidget {
  const ArchiveSection({
    super.key,
    required this.title,
    required this.code,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String code;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: ArchiveCode(code),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Divider(
                height: 1,
                thickness: ArchiveGeometry.dividerWidth,
                color: tone.hairline,
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 3,
              height: 3,
              child: ColoredBox(color: tone.ink),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArchiveType.section.copyWith(color: tone.ink),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: ArchiveType.meta.copyWith(color: tone.muted),
          ),
        ],
      ],
    );
  }
}

/// 首页报头：品牌方章 + 大标题 + 档案地址。
class ArchiveMasthead extends StatelessWidget {
  const ArchiveMasthead({
    super.key,
    required this.title,
    required this.code,
    this.brand = true,
  });

  final String title;
  final String code;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Row(
      children: [
        if (brand) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tone.ink,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              Icons.movie_filter_outlined,
              size: 17,
              color: tone.surface,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: ArchiveType.masthead.copyWith(color: tone.ink),
                ),
                const SizedBox(height: 3),
                ArchiveCode(code),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 路由标题：标题 + 下方档案地址，整体居中于导航面。
class ArchiveRouteTitle extends StatelessWidget {
  const ArchiveRouteTitle({
    super.key,
    required this.title,
    required this.code,
  });

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: constraints.maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArchiveType.routeTitle.copyWith(color: tone.ink),
              ),
              const SizedBox(height: 3),
              ArchiveCode(code),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 线条与对位标
// ─────────────────────────────────────────────────────────

/// 四角对位标。纸面板的「印刷裁切线」。
class ArchiveRegistration extends StatelessWidget {
  const ArchiveRegistration({
    super.key,
    required this.child,
    this.inset = 0,
    this.visible = true,
  });

  final Widget child;
  final double inset;
  final bool visible;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: visible
        ? _RegistrationPainter(
            color: ArchiveTone.of(
              context,
            ).ink.withValues(alpha: 0.32),
            inset: inset,
          )
        : null,
    child: child,
  );
}

class _RegistrationPainter extends CustomPainter {
  const _RegistrationPainter({required this.color, required this.inset});

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = ArchiveGeometry.hairlineWidth
      ..style = PaintingStyle.stroke;
    final r = (Offset.zero & size).deflate(inset + 0.5);
    final length = math.min(7.0, math.min(r.width, r.height) / 3);
    if (length <= 0) return;
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx * length, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + dy * length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RegistrationPainter oldDelegate) =>
      color != oldDelegate.color || inset != oldDelegate.inset;
}

/// 档案底纹：48px 网格 + 两个十字对位标，只画在页头。
class ArchiveBackdrop extends StatelessWidget {
  const ArchiveBackdrop({super.key, this.height = 240});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: MediaQuery.paddingOf(context).top + height,
          width: double.infinity,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BackdropPainter(
                color: tone.ink,
                top: MediaQuery.paddingOf(context).top,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.color, required this.top});

  final Color color;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = math.min(size.height, top + 240);
    final grid = Paint()
      ..color = color.withValues(alpha: 0.045)
      ..strokeWidth = 0.5;
    for (var x = 24.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, bottom), grid);
    }
    for (var y = top + 4; y < bottom; y += 48) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), grid);
    }
    final mark = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    final y = top + 60;
    for (final x in [24.0, size.width - 24]) {
      canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), mark);
      canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), mark);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      color != oldDelegate.color || top != oldDelegate.top;
}

// ─────────────────────────────────────────────────────────
// 纸面板 / 玻璃 / 遮罩
// ─────────────────────────────────────────────────────────

/// 按压缩放：同一套物理（纸面板 0.975 / 控件 0.97）。
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = ArchiveGeometry.tapScale,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final MouseCursor cursor;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : widget.cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed && !reduce ? widget.scale : 1,
          duration: reduce
              ? Duration.zero
              : (_pressed ? ArchiveMotion.contact : ArchiveMotion.enter),
          curve: ArchiveMotion.settle,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 纸面板：surface 底 + 0.7 发丝线 + 四角对位标。内容永远用它。
class PaperPanel extends StatelessWidget {
  const PaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = ArchiveGeometry.panelRadius,
    this.background,
    this.onTap,
    this.registration = true,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? background;
  final VoidCallback? onTap;
  final bool registration;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final body = _PaperPanelBody(
      padding: padding,
      radius: radius,
      background: background,
      onTap: onTap,
      registration: registration,
      border: border,
      child: child,
    );
    return margin == null ? body : Padding(padding: margin!, child: body);
  }
}

/// 按下时整块纸面缩到 0.975；用 InkWell 的 highlight 驱动，避免与手势竞争。
class _PaperPanelBody extends StatefulWidget {
  const _PaperPanelBody({
    required this.child,
    required this.padding,
    required this.radius,
    required this.background,
    required this.onTap,
    required this.registration,
    required this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? background;
  final VoidCallback? onTap;
  final bool registration;
  final bool border;

  @override
  State<_PaperPanelBody> createState() => _PaperPanelBodyState();
}

class _PaperPanelBodyState extends State<_PaperPanelBody> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      side: widget.border
          ? BorderSide(
              color: tone.hairline,
              width: ArchiveGeometry.hairlineWidth,
            )
          : BorderSide.none,
    );
    final content = ArchiveRegistration(
      visible: widget.registration,
      child: Padding(padding: widget.padding, child: widget.child),
    );
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _pressed && !reduce ? ArchiveGeometry.tapScale : 1,
        duration: reduce
            ? Duration.zero
            : (_pressed ? ArchiveMotion.contact : ArchiveMotion.enter),
        curve: ArchiveMotion.settle,
        child: Material(
          color: widget.background ?? tone.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: widget.onTap == null
              ? content
              : InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: (pressed) =>
                      setState(() => _pressed = pressed),
                  hoverColor: tone.raisedHigh,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  child: content,
                ),
        ),
      ),
    );
  }
}

/// 玻璃面：奶白半透 + 细分模糊 + 发丝线。只给导航/浮层。
class GlassCapsule extends StatelessWidget {
  const GlassCapsule({
    super.key,
    required this.child,
    this.radius = ArchiveGeometry.pillRadius,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.82,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tone.milk.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.65),
              width: ArchiveGeometry.hairlineWidth,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 顶部玻璃导航面：模糊 + 奶白纱 + 向下羽化，不铺不透明 footer。
class FrostedHeader extends StatelessWidget {
  const FrostedHeader({
    super.key,
    required this.child,
    this.height = ArchiveGeometry.toolbarHeight,
    this.feather = 32,
    this.horizontalPadding = 16,
  });

  final Widget child;
  final double height;
  final double feather;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final veil = tone.milk.withValues(alpha: 0.78);
    return SizedBox(
      height: top + height + feather,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + height,
            // BackdropFilter 必须由 ClipRect 收边：否则它会把整个场景当作
            // backdrop 做模糊，整页都会糊掉（只在导航条内生效才正确）。
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: ColoredBox(color: veil),
              ),
            ),
          ),
          Positioned(
            top: top + height,
            left: 0,
            right: 0,
            height: feather,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [veil, veil.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: horizontalPadding,
            right: horizontalPadding,
            height: height,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 页面骨架：对角纸渐变 + 页头底纹 + 可选顶栏。
class Atmosphere extends StatelessWidget {
  const Atmosphere({super.key, required this.child, this.backdrop = true});

  final Widget child;
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.pageStart, tone.pageEnd],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdrop) const ArchiveBackdrop(),
          child,
        ],
      ),
    );
  }
}

/// 页面：Atmosphere + 固定玻璃顶栏 + 内容。
class ArchivePage extends StatelessWidget {
  const ArchivePage({
    super.key,
    required this.title,
    required this.code,
    required this.child,
    this.leading,
    this.actions = const [],
    this.showHeader = true,
  });

  final String title;
  final String code;
  final Widget child;
  final Widget? leading;
  final List<Widget> actions;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArchiveTone.of(context).pageEnd,
      body: Atmosphere(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            if (showHeader)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FrostedHeader(
                  child: ArchiveHeaderBar(
                    leading: leading ?? const SizedBox.shrink(),
                    title: ArchiveRouteTitle(title: title, code: code),
                    actions: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 导航栏：标题始终居中于导航面，而不是剩余空间。
class ArchiveHeaderBar extends StatelessWidget {
  const ArchiveHeaderBar({
    super.key,
    required this.title,
    required this.leading,
    this.actions = const [],
  });

  final Widget title;
  final Widget leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: ArchiveGeometry.headerHeight,
    child: CustomMultiChildLayout(
      delegate: _HeaderLayout(),
      children: [
        LayoutId(id: 'leading', child: leading),
        LayoutId(id: 'title', child: title),
        LayoutId(
          id: 'actions',
          child: Row(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      ],
    ),
  );
}

class _HeaderLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final side = BoxConstraints(
      maxWidth: size.width / 2,
      maxHeight: size.height,
    );
    final leading = layoutChild('leading', side);
    final actions = layoutChild('actions', side);
    positionChild('leading', Offset(0, (size.height - leading.height) / 2));
    positionChild(
      'actions',
      Offset(size.width - actions.width, (size.height - actions.height) / 2),
    );
    final gutter = math.max(leading.width, actions.width) + 8;
    final title = layoutChild(
      'title',
      BoxConstraints(
        maxWidth: math.max(0, size.width - gutter * 2),
        maxHeight: size.height,
      ),
    );
    positionChild(
      'title',
      Offset((size.width - title.width) / 2, (size.height - title.height) / 2),
    );
  }

  @override
  bool shouldRelayout(_HeaderLayout oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────
// 按钮
// ─────────────────────────────────────────────────────────

/// 圆形图标按钮：46 圆形 + 发丝线，纸底墨字。
class ArchiveIconButton extends StatelessWidget {
  const ArchiveIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.size = ArchiveGeometry.iconControlSize,
    this.iconSize = 20,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final enabled = onPressed != null;
    final fg = filled
        ? tone.surface
        : tone.ink.withValues(alpha: enabled ? 1 : 0.35);
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: filled ? tone.ink : tone.milk,
            shape: CircleBorder(
              side: BorderSide(
                color: filled ? Colors.transparent : tone.hairline,
                width: ArchiveGeometry.hairlineWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              hoverColor: tone.raisedHigh,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: Icon(icon, size: iconSize, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// 胶囊主按钮：墨底奶白字。
class ArchivePillButton extends StatelessWidget {
  const ArchivePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final enabled = onPressed != null;
    final fg = tone.surface.withValues(alpha: enabled ? 1 : 0.6);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: height,
        child: Material(
          color: tone.ink,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            hoverColor: Colors.white.withValues(alpha: 0.08),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArchiveType.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 次级按钮：纸底 + 发丝线，极小圆角。
class ArchiveTextButton extends StatelessWidget {
  const ArchiveTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.selected,
    this.icon,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool? selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final enabled = onPressed != null;
    final fg = (selected == true ? tone.ink : tone.ink).withValues(
      alpha: enabled ? 1 : 0.4,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: selected == true ? tone.raisedHigh : tone.milk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius),
          side: BorderSide(
            color: selected == true ? tone.hairlineStrong : tone.hairline,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: tone.raisedHigh,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 40,
              minWidth: 64,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: ArchiveType.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(color: fg, size: 16),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 遮罩与布局工具
// ─────────────────────────────────────────────────────────

/// 浅灰纱遮罩：替代纯黑，保留纸感；可选背景模糊。
class ArchiveScrim extends StatelessWidget {
  const ArchiveScrim({
    super.key,
    this.strong = false,
    this.blur = 0,
    this.onTap,
    this.child,
  });

  final bool strong;
  final double blur;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final veil = ColoredBox(
      color: strong ? tone.scrimStrong : tone.scrim,
    );
    final content = blur > 0
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: veil,
            ),
          )
        : veil;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child == null ? content : Stack(fit: StackFit.expand, children: [content, child!]),
    );
  }
}

/// 页面内容内边距：左右 24，顶部让过玻璃条，底部留白。
EdgeInsets archivePagePadding(BuildContext context, {double extraTop = 0}) {
  final media = MediaQuery.of(context);
  return EdgeInsets.fromLTRB(
    ArchiveGeometry.pagePadding,
    media.padding.top + ArchiveGeometry.toolbarHeight + 20 + extraTop,
    ArchiveGeometry.pagePadding,
    media.padding.bottom + 40,
  );
}

/// 列表项之间的发丝线。
class ArchiveDivider extends StatelessWidget {
  const ArchiveDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: Divider(
      height: 1,
      thickness: ArchiveGeometry.dividerWidth,
      color: ArchiveTone.of(context).hairline,
    ),
  );
}
