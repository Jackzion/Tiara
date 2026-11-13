import 'package:flutter/material.dart';

import 'archive_tokens.dart';

export 'archive_tokens.dart';

/// 换成纸/墨体系。新代码请优先用 [ArchiveType] 与 Theme 的 textTheme。
const roboto = TextStyle(color: ArchivePalette.ink);

final largeTitle = ArchiveType.display.copyWith(color: ArchivePalette.ink);
final heading1 = ArchiveType.section.copyWith(color: ArchivePalette.ink);
final heading2 = ArchiveType.title.copyWith(color: ArchivePalette.ink);
final body1Regular = ArchiveType.bodyRegular.copyWith(
  color: ArchivePalette.ink,
);
final body1Bold = ArchiveType.bodyRegular.copyWith(
  color: ArchivePalette.ink,
  fontWeight: FontWeight.w700,
);
final body2Regular = ArchiveType.body.copyWith(
  color: ArchivePalette.ink,
  fontWeight: FontWeight.w400,
);
final body2Bold = ArchiveType.body.copyWith(
  color: ArchivePalette.ink,
  fontWeight: FontWeight.w700,
);
final body3Regular = ArchiveType.meta.copyWith(color: ArchivePalette.muted);
final body3Bold = ArchiveType.meta.copyWith(
  color: ArchivePalette.ink,
  fontWeight: FontWeight.w700,
);
final caption = ArchiveType.micro.copyWith(color: ArchivePalette.muted);
final verySmallText = ArchiveType.micro.copyWith(
  fontSize: 10,
  color: ArchivePalette.muted,
);

// ── 旧配色名 → 纸与档案（保留名字，值全部换掉） ────────────
const screenBackground = ArchivePalette.background; // 页面底
const searchBarBackground = ArchivePalette.surface; // 面板/弹层底
const surfaceBar = ArchivePalette.surface; // 顶栏/抽屉
const primaryButton = ArchivePalette.ink; // 主操作 = 墨
const accentAmber = ArchivePalette.ink; // 强调 = 墨（不再是琥珀）
const accentAmberLight = ArchivePalette.inkSoft;
const accentAmberDeep = ArchivePalette.ink;
const textMuted = ArchivePalette.muted;
const textSoft = ArchivePalette.inkSoft;
const posterBorder = ArchivePalette.muted;
const buttonGrey = ArchivePalette.raised;
const dividerLine = ArchivePalette.hairline;
const onAccent = ArchivePalette.milk;
const dangerRed = ArchivePalette.error;
const successGreen = ArchivePalette.success;
const iconPlaceholder = ArchivePalette.faint;

/// 浅色纸主题。`brightness` 只影响灰阶与少许语义色，版式完全一致。
ThemeData createTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: ArchivePalette.ink,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  );
  final scheme = base.copyWith(
    primary: dark ? ArchivePalette.darkInk : ArchivePalette.ink,
    onPrimary: dark ? ArchivePalette.ink : ArchivePalette.milk,
    secondary: dark ? ArchivePalette.darkMuted : ArchivePalette.inkSoft,
    onSecondary: dark ? ArchivePalette.ink : ArchivePalette.milk,
    surface: dark ? ArchivePalette.darkSurface : ArchivePalette.surface,
    onSurface: dark ? ArchivePalette.darkInk : ArchivePalette.ink,
    onSurfaceVariant: dark ? ArchivePalette.darkMuted : ArchivePalette.muted,
    surfaceContainerLowest: dark
        ? ArchivePalette.darkBackground
        : ArchivePalette.milk,
    surfaceContainerLow: dark
        ? ArchivePalette.darkSurface
        : ArchivePalette.background,
    surfaceContainer: dark
        ? ArchivePalette.darkRaised
        : ArchivePalette.raised,
    surfaceContainerHigh: dark
        ? ArchivePalette.darkRaisedHigh
        : ArchivePalette.raisedHigh,
    surfaceContainerHighest: dark
        ? ArchivePalette.darkRaisedHigh
        : ArchivePalette.raisedHigh,
    outline: dark ? ArchivePalette.darkOutline : ArchivePalette.hairlineStrong,
    outlineVariant: dark ? ArchivePalette.darkOutline : ArchivePalette.hairline,
    error: dark ? const Color(0xFFD08B84) : ArchivePalette.error,
    onError: dark ? ArchivePalette.ink : ArchivePalette.milk,
    surfaceTint: Colors.transparent,
  );
  final tone = ArchiveTone.forScheme(scheme);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [tone],
    scaffoldBackgroundColor: tone.pageEnd,
    canvasColor: tone.surface,
    dividerColor: tone.hairline,
    splashFactory: InkRipple.splashFactory,
    textTheme: TextTheme(
      displayLarge: ArchiveType.display.copyWith(color: scheme.onSurface),
      displayMedium: ArchiveType.display.copyWith(color: scheme.onSurface),
      displaySmall: ArchiveType.masthead.copyWith(color: scheme.onSurface),
      headlineLarge: ArchiveType.display.copyWith(color: scheme.onSurface),
      headlineMedium: ArchiveType.section.copyWith(color: scheme.onSurface),
      headlineSmall: ArchiveType.routeTitle.copyWith(color: scheme.onSurface),
      titleLarge: ArchiveType.masthead.copyWith(color: scheme.onSurface),
      titleMedium: ArchiveType.title.copyWith(color: scheme.onSurface),
      titleSmall: ArchiveType.title.copyWith(
        fontSize: 13,
        color: scheme.onSurface,
      ),
      bodyLarge: ArchiveType.bodyRegular.copyWith(color: scheme.onSurface),
      bodyMedium: ArchiveType.body.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: ArchiveType.meta.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: ArchiveType.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelMedium: ArchiveType.micro.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelSmall: ArchiveType.code.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    iconTheme: IconThemeData(color: scheme.onSurface, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: tone.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: ArchiveType.routeTitle.copyWith(
        color: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface, size: 20),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tone.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 60,
      indicatorColor: tone.active.withValues(alpha: 0.10),
      labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return ArchiveType.micro.copyWith(
          color: selected ? scheme.onSurface : tone.muted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 20,
          color: selected ? scheme.onSurface : tone.muted,
        );
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: tone.surface,
      selectedItemColor: scheme.onSurface,
      unselectedItemColor: tone.muted,
      selectedLabelStyle: ArchiveType.micro.copyWith(
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: ArchiveType.micro,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: tone.surface,
      indicatorColor: tone.active.withValues(alpha: 0.10),
      selectedIconTheme: IconThemeData(color: scheme.onSurface, size: 20),
      unselectedIconTheme: IconThemeData(color: tone.muted, size: 20),
      selectedLabelTextStyle: ArchiveType.body.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: ArchiveType.body.copyWith(color: tone.muted),
    ),
    dividerTheme: DividerThemeData(
      color: tone.hairline,
      thickness: ArchiveGeometry.dividerWidth,
      space: ArchiveGeometry.dividerWidth,
    ),
    // 刻意不设 inputDecorationTheme：全局搜索有一个「常驻树上、关闭时靠透明度
    // 隐身」的输入框，主题层的 filled/边框会把它画成一条永远存在的纸条。
    // 需要纸感的表单各自显式声明 decoration。
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: ArchiveType.body.copyWith(
        color: scheme.onInverseSurface,
      ),
      actionTextColor: scheme.onInverseSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tone.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius + 2),
        side: BorderSide(
          color: tone.hairline,
          width: ArchiveGeometry.hairlineWidth,
        ),
      ),
      titleTextStyle: ArchiveType.section.copyWith(color: scheme.onSurface),
      contentTextStyle: ArchiveType.body.copyWith(color: tone.muted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tone.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: tone.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tone.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius),
        side: BorderSide(
          color: tone.hairline,
          width: ArchiveGeometry.hairlineWidth,
        ),
      ),
      textStyle: ArchiveType.body.copyWith(color: scheme.onSurface),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius + 1),
      ),
      textStyle: ArchiveType.micro.copyWith(color: scheme.onInverseSurface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.onSurface.withValues(alpha: 0.65),
      linearTrackColor: scheme.onSurface.withValues(alpha: 0.08),
      linearMinHeight: 3,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tone.raised,
      side: BorderSide(
        color: tone.hairline,
        width: ArchiveGeometry.hairlineWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius + 1),
      ),
      labelStyle: ArchiveType.micro.copyWith(color: scheme.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
  );
}
