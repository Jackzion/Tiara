import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movies/services/comic_source/comic_rule_catalog.dart';

/// Phase 0 smoke：
/// ① 离线：init.js + 内联最小规则，证明引擎可用
/// ② 联网：RuleCatalogService 下载 copy_manga.js → 装载 → name 正确
///
/// 运行（Windows，② 需要网络）：
///   flutter test integration_test/js_engine_smoke_test.dart -d windows
///
/// 为什么不是 `flutter test`：flutter_qjs 是 FFI 插件，测试 VM 加载不到
/// flutter_qjs_plugin.dll；必须走 Windows 目标（integration_test）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 建引擎 + 注入 Host stub + 装载 init.js。
  FlutterQjs startEngine() {
    final engine = FlutterQjs();
    // 事件循环：Promise / setTimeout 依赖它，保持后台运行
    unawaited(engine.dispatch());

    // Phase 0 的 Host stub：任何 Host API 调用都明确报错（真现在 Phase 2b）
    final setGlobal = engine.evaluate('(key, value) => { this[key] = value; }')
        as JSInvokable;
    setGlobal([
      'sendMessage',
      (dynamic msg) {
        final method = (msg is Map) ? msg['method'] : msg;
        throw 'Host API 未实现: $method';
      },
    ]);
    setGlobal(['appVersion', '1.0.0']);
    setGlobal.free();
    return engine;
  }

  testWidgets('① 离线 hello-world：init.js + 内联规则', (tester) async {
    final engine = startEngine();

    final initJs = await rootBundle.loadString('assets/init.js');
    engine.evaluate(initJs, name: '<init>');

    engine.evaluate(
      '''
      class DemoSource extends ComicSource {
        name = "演示源";
        key = "demo";
        version = "1.0.0";
      }
      ''',
      name: '<demo>',
    );
    expect(engine.evaluate('new DemoSource().name'), '演示源');

    engine.close();
  });

  testWidgets('② 启动同步下载 copy_manga.js 并装载', (tester) async {
    final catalog = RuleCatalogService();
    final downloaded = await catalog.syncOnStartup(onlyKeys: ['copy_manga']);
    expect(downloaded, contains('copy_manga'), reason: 'copy_manga 应下载成功');

    final dir = await catalog.ruleDir();
    final file = File('${dir.path}${Platform.pathSeparator}copy_manga.js');
    expect(await file.exists(), isTrue);
    // ignore: avoid_print
    print('[smoke] 规则落盘位置: ${file.path}');

    // manifest 台账应已记录版本
    final manifestFile =
        File('${dir.path}${Platform.pathSeparator}manifest.json');
    expect(await manifestFile.exists(), isTrue);
    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    expect(manifest['copy_manga']?['version'], '1.4.3');

    final engine = startEngine();
    final initJs = await rootBundle.loadString('assets/init.js');
    engine.evaluate(initJs, name: '<init>');

    final ruleJs = await file.readAsString();
    engine.evaluate(ruleJs, name: '<copy_manga>');
    expect(engine.evaluate('new CopyManga().name'), '拷贝漫画');
    expect(engine.evaluate('new CopyManga().key'), 'copy_manga');

    engine.close();
  });
}
