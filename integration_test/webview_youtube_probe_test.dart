import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movies/services/video_source/webview_video_source_service.dart';
import 'package:webview_windows/webview_windows.dart';

/// 实况探测：现有 WebviewVideoSourceService 能否从 YouTube 页爬到媒体直链。
///
/// 运行（Windows，需要 WebView2）：
///   flutter test integration_test/webview_youtube_probe_test.dart -d windows
///
/// 目标页：https://www.youtube.com/watch?v=7rxIZ3z0S4s
///
/// 两轮：
/// 1) 走业务服务 parseVideoSource（用户关心的「现在的 service」）
/// 2) 无头 WebView 裸听 onVideoSourceLoaded / onM3USourceLoaded / url / title，
///    判断是「页面没播起来」还是「事件没挂钩」。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const pageUrl = 'https://www.youtube.com/watch?v=7rxIZ3z0S4s';
  const timeout = Duration(seconds: 25);

  testWidgets('① WebviewVideoSourceService.parseVideoSource', (tester) async {
    final service = WebviewVideoSourceService();
    // ignore: avoid_print
    print('[YT-1] service parse → $pageUrl (timeout: $timeout)');

    try {
      final source = await service.parseVideoSource(pageUrl, timeout: timeout);
      // ignore: avoid_print
      print('[YT-1] SUCCESS: $source');
      expect(source.url, isNotEmpty);
    } catch (e) {
      // ignore: avoid_print
      print('[YT-1] FAILED: $e');
      // 这里不 fail，留给第 ② 轮收集证据；最后统一结论
    } finally {
      await service.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('② HeadlessWebview 裸听媒体事件（诊断）', (tester) async {
    final wv = HeadlessWebview();
    final logs = <String>[];
    final subs = <StreamSubscription>[];

    void log(String s) {
      logs.add(s);
      // ignore: avoid_print
      print('[YT-2] $s');
    }

    subs.add(wv.url.listen((u) => log('url → $u')));
    subs.add(wv.title.listen((t) => log('title → $t')));
    subs.add(wv.loadingState.listen((s) => log('loadingState → $s')));
    subs.add(wv.onLoadError.listen((e) => log('loadError → $e')));
    subs.add(
      wv.onVideoSourceLoaded.listen((d) {
        log('onVideoSourceLoaded → ${d['url']}  ct=${d['contentType']}');
      }),
    );
    subs.add(
      wv.onM3USourceLoaded.listen((d) {
        log('onM3USourceLoaded → ${d['url']}  ct=${d['contentType']}');
      }),
    );

    try {
      await wv.run();
      await wv.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      log('webview ready, loading…');
      await wv.loadUrl(pageUrl);
      await Future<void>.delayed(const Duration(seconds: 5));

      // 尝试强制播放：有时 headless 下 autoplay 被策略拦住，点了才拉流
      try {
        final playResult = await wv.executeScript('''
(function () {
  var v = document.querySelector('video');
  if (v) { v.muted = true; v.play(); return 'video.play() called, paused=' + v.paused; }
  var btn = document.querySelector('button.ytp-large-play-button') || document.querySelector('.ytp-play-button');
  if (btn) { btn.click(); return 'clicked play button'; }
  return 'no video/play button found';
})()
''');
        log('forcePlay → $playResult');
      } catch (e) {
        log('forcePlay failed: $e');
      }

      // 等待窗口内出现媒体事件，或到时
      final deadline = DateTime.now().add(timeout);
      var sawMedia = false;
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (logs.any((l) => l.contains('onVideoSourceLoaded') || l.contains('onM3USourceLoaded'))) {
          sawMedia = true;
          // 再多等 2s 收集后续分片
          await Future<void>.delayed(const Duration(seconds: 2));
          break;
        }
      }

      // 探一下 video 标签状态，判断播放器是否起来
      try {
        final vstat = await wv.executeScript('''
(function () {
  var v = document.querySelector('video');
  if (!v) return 'no <video> tag';
  return 'src=' + (v.currentSrc || v.src || '(empty)') +
    ' networkState=' + v.networkState +
    ' readyState=' + v.readyState +
    ' paused=' + v.paused +
    ' currentTime=' + v.currentTime;
})()
''');
        log('video.tag → $vstat');
      } catch (e) {
        log('read video.tag failed: $e');
      }

      // 抓一页标题/URL，判断是否卡在同意页/登录墙
      try {
        final title = await wv.executeScript('document.title');
        log('document.title → $title');
      } catch (e) {
        log('read title failed: $e');
      }
      try {
        final href = await wv.executeScript('location.href');
        log('location.href → $href');
      } catch (e) {
        log('read href failed: $e');
      }

      log('sawMedia=$sawMedia  logCount=${logs.length}');
      if (!sawMedia) {
        log('结论：25s 内未捕获任何 onVideoSourceLoaded / onM3USourceLoaded');
      }
    } finally {
      for (final s in subs) {
        unawaited(s.cancel());
      }
      await wv.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
