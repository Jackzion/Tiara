import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/services/js/host_convert.dart';
import 'package:movies/services/js/host_html.dart';
import 'package:movies/services/js/host_network.dart';

/// QuickJS 引擎服务（应用级单例，keepAlive——引擎启动成本高）
/// 装载链：init.js → 规则 js → ComicSource.sources.key
/// JS 一切 Host API 经 init.js sendMessage 落到 [_messageReceiver]
class JsEngineService {
  JsEngineService({
    required this.hostNetwork,
    required this.hostConvert,
    required this.hostHtml,
  });

  /// SendMessage.http 的 Host 实现
  final HostNetwork hostNetwork;

  /// SendMessage.http 的 Host 实现
  final HostHtml hostHtml;

  /// SendMessage.convert 的 Host 实现
  final HostConvert hostConvert;

  /// QuickJS 引擎实例 , 用来运行 JS 代码
  FlutterQjs? _engine;

  /// 规则 KV（key → dataMap）；规则跑出来的数据（可写，如登录 token）
  final Map<String, Map<String, dynamic>> _kv = {};

  /// 规则 settings 默认值（load_setting 兜底，装载时一次性提取）
  final Map<String, Map<String, dynamic>> _settingsDefaults = {};

  /// 确保引擎初始化, 未初始化则加载 init.js 初始化并且 map _messageReceiver to sendMessage
  Future<void> ensureInit() async {
    if (_engine != null) return;
    final engine = FlutterQjs();
    // js engine await for event，事件循环：Promise/setTimeout 依赖它
    unawaited(engine.dispatch());
    // 设置可执行句柄 ，把 JS 函数递回 Dart 时包装成 JSInvokable ，Dart 侧用句柄(参数列表) 的方式调用它
    // evaluate 就是「让引擎执行一段 JS 源码字符串」
    final setGlobal = engine.evaluate(
      '(key, value) => { this[key] = value; }',
    ) as JSInvokable;
    // 注入 _messageReceiver 到 JS 环境
    // this['sendMessage'] = _messageReceiver的JS包装;
    setGlobal(['sendMessage', _messageReceiver]);
    setGlobal(['appVersion', '1.0.0']);
    // 注释放句柄，避免内存泄漏
    setGlobal.free();
    // host 抛出的字符串（如 'Host API 未实现: xxx'）在 JS 里是 throw "string"，
    // 规则的 catch(err) 拿不到 err.message。这里统一包成 Error。
    engine.evaluate('''
      (function () {
        var raw = sendMessage;
        this.sendMessage = function (msg) {
          try {
            return raw(msg);
          } catch (e) {
            throw (e instanceof Error) ? e : new Error(String(e));
          }
        };
      }).call(this)
    ''', name: '<host-wrapper>');
    // evaluate init.js
    engine.evaluate(
      await rootBundle.loadString('assets/init.js'),
      name: '<init>',
    );
    _engine = engine;
  }

  /// 运行 JS 代码（可选 name 用于调试）
  /// name 只用于 Error Message
  dynamic runCode(String js, [String? name]) =>
      _engine!.evaluate(js, name: name);

  /// 装载一条规则（类名从 class X extends ComicSource 行提取，对标 parser.dart:86-131）
  Future<String> loadRule(String js, {String name = '<rule>'}) async {
    // 确保引擎初始化
    await ensureInit();
    // normalize js
    final normalized = js.replaceAll('\r\n', '\n');
    final line = normalized
        .split('\n')
        .firstWhere((e) => e.trim().startsWith('class '));
    // 检查是否 extends ComicSource
    if (!line.contains('extends ComicSource')) {
      throw 'Invalid Content: 首个 class 行必须 extends ComicSource';
    }
    // 提取类名
    final className = line
        .split('class')[1]
        .split('extends ComicSource')
        .first
        .trim();
    // 实例化
    runCode(
      '(() => { $normalized\n this["temp"] = new $className()\n }).call()',
      name,
    );
    // 注册到 js engine 中的 ComicSource.sources
    final key = runCode('this["temp"].key') as String;
    runCode('ComicSource.sources.$key = this["temp"]');
    // source.settings 默认值一次性提取到 Dart
    final raw = runCode(
      'JSON.stringify(Object.fromEntries(Object.entries(ComicSource.sources.$key.settings || {}).map(([k, v]) => [k, v.default])))',
    );
    _settingsDefaults[key] = (jsonDecode(raw as String) as Map)
        .cast<String, dynamic>();
    // 调用规则的 init()
    // copy_manga 等规则在里面初始化实例字段（author_path_word_dict 等），不调会炸
    final hasInit =
        runCode('ComicSource.sources.$key.init != null') as bool? ?? false;
    if (hasInit) {
      // fire-and-forget（init 可能是 async）；失败只记日志不阻塞装载
      runCode('''
        (() => {
          try {
            const p = ComicSource.sources.$key.init();
            if (p && typeof p.catch === 'function') {
              p.catch((e) => console.log('init() failed: ' + e));
            }
          } catch (e) {
            console.log('init() failed: ' + e);
          }
        })()
      ''');
    }
    return key;
  }

  /// 处理 JS 发送的消息
  /// 所有 Host API 都经 init.js sendMessage 落到 [_messageReceiver]
  Object? _messageReceiver(dynamic message) {
    if (message is! Map) return null;
    final method = message['method'];
    // 不同 method 处理不同逻辑
    switch (method) {
      case 'http':
        return hostNetwork.handle(Map<String, dynamic>.from(message));
      case 'html':
        return hostHtml.handle(Map<String, dynamic>.from(message));
      case 'convert':
        return hostConvert.handle(Map<String, dynamic>.from(message));
      case 'delay':
        return Future.delayed(Duration(milliseconds: message['time'] as int));
      case 'log':
        logMessage('[JS:${message['title']}] ${message['content']}');
      case 'random':
        final min = (message['min'] as num?)?.toDouble() ?? 0;
        final max = (message['max'] as num?)?.toDouble() ?? 1;
        final r = math.Random();
        return message['type'] == 'int'
            ? min.toInt() + r.nextInt((max - min).toInt() + 1)
            : min + r.nextDouble() * (max - min);
      case 'load_data':
        return _kv[message['key']]?[message['data_key']];
      case 'save_data':
        (_kv[message['key']] ??= {})[message['data_key']] = message['data'];
      case 'delete_data':
        _kv[message['key']]?.remove(message['data_key']);
      case 'load_setting':
        final key = message['key'] as String;
        final settingKey = message['setting_key'] as String;
        return _kv[key]?['settings']?[settingKey] ??
            _settingsDefaults[key]?[settingKey];
      case 'uuid':
        return _uuidV4();
      case 'isLogged':
        // 只有一个 key（规则 key）。没有显式 token 即视为未登录，
        // 让规则走「需要登录」分支，而不是抛错。
        final ruleKey = message['key'] as String?;
        if (ruleKey == null) return false;
        final data = _kv[ruleKey];
        if (data == null) return false;
        for (final tokenKey in const [
          'token',
          'access_token',
          'refresh_token',
          'auth',
          'cookie',
          'cookies',
        ]) {
          final value = data[tokenKey];
          if (value is String && value.isNotEmpty) return true;
          if (value is Map && value.isNotEmpty) return true;
        }
        return false;
      case 'getPlatform':
        return _platformName;
      case 'getLocale':
        return _localeTag;
      default:
        final fn = message['function'];
        final label = fn == null ? '$method' : '$method/$fn';
        logError('[host] 未实现 $label : key=${message['key']}');
        throw 'Host API 未实现: $label';
    }
    return null;
  }

  /// v4 UUID（createUuid 只要求"每次不同"）
  static String _uuidV4() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  /// init.js 约定的平台名：android / ios / windows / macos / linux
  static String get _platformName => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.windows => 'windows',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'linux',
  };

  /// [languageCode]_[countryCode]，如 zh_CN
  static String get _localeTag => ui.PlatformDispatcher.instance.locale
      .toLanguageTag()
      .replaceAll('-', '_');

  void dispose() {
    _engine?.close();
    _engine?.port.close();
    _engine = null;
  }
}
