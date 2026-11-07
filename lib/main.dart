import 'dart:async';

import 'package:colorize_lumberdash/colorize_lumberdash.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movies/providers.dart';
import 'package:movies/services/comic_source/comic_rule_catalog.dart';
import 'package:movies/ui/search/global_search_scope.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/system_proxy.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/utils/webview_probe.dart';

void main() async {
  // pod_player 在 Windows/Linux/macOS 底层用 media_kit,
  // 必须显式初始化，否则视频播放会直接报 "Error while playing video"
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // 桌面端限制窗口最小尺寸，避免过小导致布局不可用
  if (isDesktop()) {
    await DesktopWindow.setWindowSize(const Size(700, 600));
    await DesktopWindow.setMinWindowSize(const Size(700, 600));
  }

  // 全局应用系统代理（API 请求与图片加载都走代理）
  applySystemProxy();

  // 初始化 lumberdash 日志工具
  putLumberdashToWork(withClients: [ColorizeLumberdash()]);

  // 启动 APP 前检测 webView2 是否可用
  final ok = await probeHeadlessWebview();
  debugPrint('WebView2 available: $ok');
  
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // 首帧定格后异步触发一次 fetch commic rule
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(RuleCatalogService().syncOnStartup());
    });

    return MaterialApp.router(
      routerConfig: router.config(),
      title: 'Tiara',
      debugShowCheckedModeBanner: false,
      theme: createTheme(),
      // 全局搜索：包在路由子树外，Idle 吃可打印键 / Ctrl+K 唤起 Overlay
      builder: (context, child) {
        return GlobalSearchScope(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
