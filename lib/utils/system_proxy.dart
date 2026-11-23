import 'dart:io';

/// Windows 系统代理（WinINET / IE 设置）读取。
///
/// WebView2 走系统代理；youtube_explode 与 mpv 默认不走。
/// 取流签名绑定出口 IP，解析和播必须用同一条出口。
class SystemProxy {
  /// findProxy 字符串，例如 `PROXY 127.0.0.1:7890; DIRECT` 或 `DIRECT`。
  ///
  /// Dart findProxy 只认 `PROXY host:port; DIRECT` 形态——Windows 注册表的
  /// 分协议代理（`http=…;https=…`）必须先归一化，否则 HttpClient 直接抛
  /// "Invalid proxy configuration"。
  static String findProxyRule() {
    final hostPort = resolveHostPort();
    if (hostPort == null) {
      return 'DIRECT';
    }
    return 'PROXY $hostPort; DIRECT';
  }

  /// 代理 `host:port`；无代理返回 null。
  /// 全应用单一出口（取流签名与播放/解析出口一致性要求）。
  static String? resolveHostPort() {
    if (!Platform.isWindows) {
      return _fromEnv();
    }
    final fromReg = _fromWindowsRegistry();
    return fromReg ?? _fromEnv();
  }

  /// mpv / media_kit 的 `http-proxy` 值（带 scheme）。
  static String? resolveMpvHttpProxy() {
    final hp = resolveHostPort();
    return hp == null ? null : 'http://$hp';
  }

  static String? _fromWindowsRegistry() {
    try {
      // 整键查询（需要 ProxyEnable 判断开关状态）
      final r = Process.runSync('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      ]);
      final out = r.stdout.toString();
      // 系统未启用代理时无视 ProxyServer 残留值（关掉 Clash 系统代理后
      // 注册表值常留着不动，不查开关会把流量打进已死的代理）
      if (!RegExp(r'ProxyEnable\s+REG_DWORD\s+0x1', caseSensitive: false)
          .hasMatch(out)) {
        return null;
      }
      final m = RegExp(r'ProxyServer\s+REG_SZ\s+(\S+)').firstMatch(out);
      final raw = m?.group(1);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return normalizeHostPort(raw);
    } catch (_) {
      return null;
    }
  }

  static String? _fromEnv() {
    final env = Platform.environment;
    final raw = env['HTTPS_PROXY'] ??
        env['https_proxy'] ??
        env['HTTP_PROXY'] ??
        env['http_proxy'];
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return normalizeHostPort(raw);
  }

  /// 归一化为 findProxy 需要的 `host:port`：
  /// - Windows 分协议形态 `http=h:p;https=h:p;socks=h:p` → 单出口取
  ///   https（加密流量优先），缺省退 http / socks
  /// - 剥 scheme（http://、socks5://…）、用户认证、路径
  static String? normalizeHostPort(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    // 分协议形态：以 `scheme=` 起头（Windows ProxyServer 的写法）
    if (RegExp(r'^[a-z0-9+.\-]+=', caseSensitive: false).hasMatch(s)) {
      final map = <String, String>{};
      for (final part in s.split(';')) {
        final kv = part.trim().split('=');
        if (kv.length != 2) continue;
        final host = kv[1].trim();
        if (host.isNotEmpty) {
          map[kv[0].trim().toLowerCase()] = host;
        }
      }
      s = map['https'] ?? map['http'] ?? map['socks'] ?? '';
    }
    if (s.isEmpty) return null;
    // 去 scheme
    s = s.replaceFirst(RegExp(r'^[a-z0-9+.\-]+://', caseSensitive: false), '');
    // 去用户认证（Dart findProxy 不支持凭据）与路径
    final at = s.lastIndexOf('@');
    if (at >= 0) {
      s = s.substring(at + 1);
    }
    final slash = s.indexOf('/');
    if (slash > 0) {
      s = s.substring(0, slash);
    }
    return s.isEmpty ? null : s;
  }
}

/// 启动时调用：让进程内 `HttpClient`（Dio/AniList/图片等）统一走系统代理。
void applySystemProxy() {
  final rule = SystemProxy.findProxyRule();
  if (rule == 'DIRECT') {
    return;
  }
  HttpOverrides.global = _SystemProxyHttpOverrides(rule);
}

class _SystemProxyHttpOverrides extends HttpOverrides {
  _SystemProxyHttpOverrides(this._rule);
  final String _rule;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => _rule;
    return client;
  }
}
