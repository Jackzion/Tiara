import 'package:flutter_test/flutter_test.dart';
import 'package:movies/utils/system_proxy.dart';

void main() {
  group('SystemProxy.normalizeHostPort', () {
    test('Windows 分协议形态 → 单一 host:port（https 优先）', () {
      // 报错现场：注册表 ProxyServer 的完整形态
      expect(
        SystemProxy.normalizeHostPort(
          'http=127.0.0.1:6666;https=127.0.0.1:6666',
        ),
        '127.0.0.1:6666',
      );
      // http/https 不同端口时取 https
      expect(
        SystemProxy.normalizeHostPort(
          'http=127.0.0.1:7890;https=127.0.0.1:6666',
        ),
        '127.0.0.1:6666',
      );
      // 只有 http 时用 http
      expect(
        SystemProxy.normalizeHostPort('http=127.0.0.1:7890'),
        '127.0.0.1:7890',
      );
      // 只有 socks 时用 socks
      expect(
        SystemProxy.normalizeHostPort('socks=127.0.0.1:1080'),
        '127.0.0.1:1080',
      );
      // 全空 → null
      expect(SystemProxy.normalizeHostPort('http=;https='), isNull);
    });

    test('裸 host:port / 带 scheme / 路径 / 认证', () {
      expect(SystemProxy.normalizeHostPort('127.0.0.1:7890'), '127.0.0.1:7890');
      expect(
        SystemProxy.normalizeHostPort('http://127.0.0.1:7890/'),
        '127.0.0.1:7890',
      );
      expect(
        SystemProxy.normalizeHostPort('socks5://127.0.0.1:1080'),
        '127.0.0.1:1080',
      );
      expect(
        SystemProxy.normalizeHostPort(
          'http://user:pass@proxy.example.com:8080',
        ),
        'proxy.example.com:8080',
      );
      expect(SystemProxy.normalizeHostPort(''), isNull);
    });
  });
}
