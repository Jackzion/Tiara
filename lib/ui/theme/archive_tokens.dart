import 'package:flutter/material.dart';

/// 纸与档案（Paper & Archive）设计令牌。
/// 规则：内容永远是纸（实心 + 发丝线），玻璃只做导航与控件。
abstract final class ArchivePalette {
  // ── 纸（浅色主色板） ────────────────────────────────────
  static const background = Color(0xFFF4F3EF); // 页面底色
  static const surface = Color(0xFFFDFCFA); // 面板/卡片底
  static const milk = Color(0xFFFEFDF8); // 玻璃奶白、封面纸底
  static const raised = Color(0xFFF2F0E9); // 书脊、次级面
  static const raisedHigh = Color(0xFFEDEBE4); // 悬停/按下底

  // ── 墨 ─────────────────────────────────────────────────
  static const ink = Color(0xFF181818); // 正文
  static const inkSoft = Color(0xFF3A3C38); // 次级标题
  static const muted = Color(0xFF646B62); // 元信息（带苔绿偏移）
  static const faint = Color(0xFF8E958C); // 占位/禁用

  // ── 线 ─────────────────────────────────────────────────
  static const hairline = Color(0xFFD8DBD5); // 发丝线（不是纯灰）
  static const hairlineStrong = Color(0xFFC3C7BF); // 强调线/角标

  // ── 状态（去饱和） ─────────────────────────────────────
  static const error = Color(0xFF9E3B34); // 砖红，非纯红
  static const success = Color(0xFF4C7A5B); // 苔绿
  static const warning = Color(0xFF8A6A2F); // 陈金

  // ── 深色（夜间纸） ─────────────────────────────────────
  static const darkBackground = Color(0xFF191919);
  static const darkSurface = Color(0xFF242424);
  static const darkRaised = Color(0xFF2D2D2D);
  static const darkRaisedHigh = Color(0xFF3A3A3A);
  static const darkOutline = Color(0xFF3C3C3C);
  static const darkInk = Color(0xFFF2F2F2);
  static const darkMuted = Color(0xFFB7B7B7);
  static const darkMilk = Color(0xFFF6F6F6);

  // ── 遮罩：暖灰纱，不用纯黑 ─────────────────────────────
  /// 模态遮罩（搜索、弹层）。压暗到能看清纸卡，但不是纯黑。
  static const scrim = Color(0x8C4A4740);

  /// 更强的遮罩（对话框/菜单）。
  static const scrimStrong = Color(0xB34A4740);

  /// 图片上的压暗层（海报角标底）。
  static const inkVeil = Color(0x99181818);
  static const inkVeilSoft = Color(0x6647433D);
}

/// 字号阶梯。大标题负字距，编号正字距。
abstract final class ArchiveType {
  /// 档案编号（mono）。全 App 的「标牌字体」。
  static const code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 9,
    height: 1.35,
    letterSpacing: 1.05,
    fontWeight: FontWeight.w500,
  );

  /// 首页报头。
  static const masthead = TextStyle(
    fontSize: 23,
    height: 1.18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
  );

  /// 区块标题。
  static const section = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  /// 路由标题（导航栏中央）。
  static const routeTitle = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  /// 卡片/列表主标题。
  static const title = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  /// 大号书名（详情页/宽屏）。
  static const display = TextStyle(
    fontSize: 28,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const bodyRegular = TextStyle(fontSize: 14, height: 1.65);

  static const meta = TextStyle(fontSize: 12, height: 1.5);

  static const micro = TextStyle(fontSize: 11, height: 1.4);
}

/// 几何常量。内容区圆角极小，只有控件是胶囊/全圆。
abstract final class ArchiveGeometry {
  static const panelRadius = 4.0; // 纸面板
  static const coverRadius = 3.0; // 封面
  static const pillRadius = 999.0; // 仅控件

  static const hairlineWidth = 0.7; // 描边
  static const dividerWidth = 0.6; // 分隔线

  static const pagePadding = 24.0; // 页面左右边距
  static const toolbarHeight = 56.0; // 玻璃工具条
  static const headerHeight = 48.0; // 导航内容高度
  static const sectionGap = 28.0; // 区块间距
  static const itemGap = 16.0; // 卡片间距

  static const contentMaxWidth = 720.0; // 单列内容
  static const wideMaxWidth = 1280.0; // 宽屏内容

  static const controlHeight = 48.0; // 最小命中高度
  static const iconControlSize = 46.0;
  static const tapScale = 0.975; // 纸面板按压
}

/// 动效词表：接触 120ms / 入场 420ms / 退场 320ms。
abstract final class ArchiveMotion {
  static const contact = Duration(milliseconds: 120);
  static const enter = Duration(milliseconds: 420);
  static const exit = Duration(milliseconds: 320);

  static const ease = Curves.easeOutCubic;
  static const retract = Curves.easeInCubic;
  static const settle = Cubic(0.2, 1.08, 0.34, 1);

  static const spring = SpringDescription(
    mass: 0.64,
    stiffness: 270,
    damping: 19,
  );
}

/// 随明暗切换的语义色。控件直接读它，而不是各自三元判断。
@immutable
class ArchiveTone extends ThemeExtension<ArchiveTone> {
  const ArchiveTone({
    required this.pageStart,
    required this.pageEnd,
    required this.surface,
    required this.milk,
    required this.raised,
    required this.raisedHigh,
    required this.ink,
    required this.muted,
    required this.hairline,
    required this.hairlineStrong,
    required this.active,
    required this.track,
    required this.thumb,
    required this.scrim,
    required this.scrimStrong,
  });

  final Color pageStart, pageEnd, surface, milk, raised, raisedHigh;
  final Color ink, muted, hairline, hairlineStrong, active, track, thumb;
  final Color scrim, scrimStrong;

  /// 优先读主题扩展；遇到没有扩展的嵌套 ThemeData 时按当前 ColorScheme 现算，
  /// 避免因为某个包自建 Theme 而整页崩掉。
  static ArchiveTone of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ArchiveTone>() ??
        ArchiveTone.forScheme(theme.colorScheme);
  }

  factory ArchiveTone.forScheme(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    return ArchiveTone(
      pageStart: dark ? ArchivePalette.darkSurface : ArchivePalette.surface,
      pageEnd: dark ? ArchivePalette.darkBackground : ArchivePalette.background,
      surface: dark ? ArchivePalette.darkSurface : ArchivePalette.surface,
      milk: dark ? ArchivePalette.darkRaised : ArchivePalette.milk,
      raised: dark ? ArchivePalette.darkRaised : ArchivePalette.raised,
      raisedHigh: dark
          ? ArchivePalette.darkRaisedHigh
          : ArchivePalette.raisedHigh,
      ink: dark ? ArchivePalette.darkInk : ArchivePalette.ink,
      muted: dark ? ArchivePalette.darkMuted : ArchivePalette.muted,
      hairline: dark ? ArchivePalette.darkOutline : ArchivePalette.hairline,
      hairlineStrong: dark
          ? const Color(0xFF4A4A4A)
          : ArchivePalette.hairlineStrong,
      // 开关/滑块的「开启」是中灰，不是黑，也不是品牌色
      active: dark
          ? Color.lerp(s.surface, s.primary, .62)!
          : const Color(0xFF868580),
      track: Color.lerp(
        s.surface,
        s.onSurface,
        dark ? .16 : .10,
      )!,
      thumb: dark ? s.onSurface : ArchivePalette.milk,
      scrim: dark ? const Color(0xB3121212) : ArchivePalette.scrim,
      scrimStrong: dark
          ? const Color(0xD90F0F0F)
          : ArchivePalette.scrimStrong,
    );
  }

  @override
  ArchiveTone copyWith({
    Color? pageStart,
    Color? pageEnd,
    Color? surface,
    Color? milk,
    Color? raised,
    Color? raisedHigh,
    Color? ink,
    Color? muted,
    Color? hairline,
    Color? hairlineStrong,
    Color? active,
    Color? track,
    Color? thumb,
    Color? scrim,
    Color? scrimStrong,
  }) => ArchiveTone(
    pageStart: pageStart ?? this.pageStart,
    pageEnd: pageEnd ?? this.pageEnd,
    surface: surface ?? this.surface,
    milk: milk ?? this.milk,
    raised: raised ?? this.raised,
    raisedHigh: raisedHigh ?? this.raisedHigh,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    hairline: hairline ?? this.hairline,
    hairlineStrong: hairlineStrong ?? this.hairlineStrong,
    active: active ?? this.active,
    track: track ?? this.track,
    thumb: thumb ?? this.thumb,
    scrim: scrim ?? this.scrim,
    scrimStrong: scrimStrong ?? this.scrimStrong,
  );

  @override
  ArchiveTone lerp(ArchiveTone? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return ArchiveTone(
      pageStart: c(pageStart, other.pageStart),
      pageEnd: c(pageEnd, other.pageEnd),
      surface: c(surface, other.surface),
      milk: c(milk, other.milk),
      raised: c(raised, other.raised),
      raisedHigh: c(raisedHigh, other.raisedHigh),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      hairline: c(hairline, other.hairline),
      hairlineStrong: c(hairlineStrong, other.hairlineStrong),
      active: c(active, other.active),
      track: c(track, other.track),
      thumb: c(thumb, other.thumb),
      scrim: c(scrim, other.scrim),
      scrimStrong: c(scrimStrong, other.scrimStrong),
    );
  }
}
