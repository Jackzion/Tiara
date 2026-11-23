import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:movies/utils/system_proxy.dart';

/// wenku8 图片防盗链头（协议调研 §4）。
Map<String, String>? wenku8ImageHeaders(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  final isWenku8Image = host.endsWith('.wenku8.com') ||
      host.endsWith('.wenku8.net') ||
      host.endsWith('.wkcdn.com') ||
      host.endsWith('.777743.xyz');
  if (!isWenku8Image) return null;
  return const {
    'Referer': 'https://www.wenku8.cc/',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  };
}

/// 双路图片加载：先按系统代理路径请求，失败（403/超时/断连）立刻换
/// 直连重试，两路都失败才抛错。
///
/// 为什么不用 Image.network：运行环境里「直连」与「代理」的可用性会摇摆
/// （实测 2026-11-23：上午直连通/代理拒，下午直连超时代理通），单路策略
/// 必然在某个时段全挂；两路互补才能稳定。
class ResilientNetworkImage extends ImageProvider<ResilientNetworkImage> {
  const ResilientNetworkImage(
    this.url, {
    this.headers,
    this.scale = 1.0,
  });

  final String url;
  final Map<String, String>? headers;
  final double scale;

  static const Duration _attemptTimeout = Duration(seconds: 15);

  @override
  Future<ResilientNetworkImage> obtainKey(
    ImageConfiguration configuration,
  ) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    ResilientNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      _loadAndDecode(decode),
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
        yield DiagnosticsProperty<String>('URL', url);
      },
    );
  }

  Future<ImageInfo> _loadAndDecode(ImageDecoderCallback decode) async {
    final bytes = await fetchWithFallback();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image, scale: scale);
  }

  /// ① 系统代理路径 → ② 直连；两路都失败抛最后一次错误
  Future<Uint8List> fetchWithFallback() async {
    Object? lastError;
    StackTrace? lastStack;
    for (final viaProxy in const [true, false]) {
      try {
        return await _fetchOne(viaProxy: viaProxy);
      } catch (e, st) {
        lastError = e;
        lastStack = st;
      }
    }
    Error.throwWithStackTrace(lastError!, lastStack!);
  }

  Future<Uint8List> _fetchOne({required bool viaProxy}) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    client.findProxy = (_) => viaProxy ? SystemProxy.findProxyRule() : 'DIRECT';
    try {
      final req = await client.getUrl(uri).timeout(_attemptTimeout);
      headers?.forEach(req.headers.set);
      final res = await req.close().timeout(_attemptTimeout);
      if (res.statusCode != 200 && res.statusCode != 206) {
        throw HttpException('HTTP ${res.statusCode}', uri: uri);
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in res.timeout(_attemptTimeout)) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ResilientNetworkImage &&
      other.url == url &&
      other.scale == scale &&
      _mapEquals(other.headers, headers);

  @override
  int get hashCode => Object.hash(url, scale, headers);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
