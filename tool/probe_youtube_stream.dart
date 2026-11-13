// 临时探测：youtube_explode 能否解析 PV 直链（走系统代理）
// 运行: dart run tool/probe_youtube_stream.dart
import 'dart:io';

import 'package:http/io_client.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// 读 Windows WinINET 代理（IE/WebView2 同款），失败则 DIRECT
/// Dart HttpClient.findProxy 只认 `host:port`，不要带 scheme。
String _hostPort(String raw) {
  var s = raw.trim();
  s = s.replaceFirst(RegExp(r'^https?://'), '');
  // 去掉路径/多余参数
  final slash = s.indexOf('/');
  if (slash > 0) s = s.substring(0, slash);
  return s;
}

String _windowsProxy() {
  try {
    final r = Process.runSync('reg', [
      'query',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v',
      'ProxyServer',
    ]);
    final out = r.stdout.toString();
    final m = RegExp(r'ProxyServer\s+REG_SZ\s+(\S+)').firstMatch(out);
    if (m != null && m.group(1)!.isNotEmpty) {
      return 'PROXY ${_hostPort(m.group(1)!)}; DIRECT';
    }
  } catch (_) {}
  final env = Platform.environment['HTTPS_PROXY'] ??
      Platform.environment['https_proxy'] ??
      Platform.environment['HTTP_PROXY'] ??
      Platform.environment['http_proxy'];
  if (env != null && env.isNotEmpty) {
    return 'PROXY ${_hostPort(env)}; DIRECT';
  }
  return 'DIRECT';
}

Future<void> main() async {
  const id = '7rxIZ3z0S4s';
  final proxy = _windowsProxy();
  logMessage('proxy → $proxy');

  final io = HttpClient()..findProxy = (_) => proxy;
  final client = IOClient(io);
  final yt = YoutubeExplode(YoutubeHttpClient(client));
  try {
    final video = await yt.videos.get(id);
    logMessage('title: ${video.title}');
    logMessage('duration: ${video.duration}');

    final manifest = await yt.videos.streamsClient.getManifest(id);
    logMessage('--- muxed (${manifest.muxed.length}) ---');
    for (final s in manifest.muxed) {
      logMessage('  ${s.qualityLabel} ${s.bitrate} ${s.size}');
      logMessage('    ${s.url}');
    }
    logMessage('--- hls (${manifest.hls.length}) ---');
    for (final s in manifest.hls) {
      logMessage('  ${s.url}');
    }
    logMessage('--- videoOnly top3 ---');
    for (final s in manifest.videoOnly.take(3)) {
      logMessage('  ${s.qualityLabel} ${s.bitrate}');
    }

    if (manifest.muxed.isNotEmpty) {
      final muxed = manifest.muxed.withHighestBitrate();
      logMessage('PICK muxed: ${muxed.qualityLabel}');
      logMessage('PICK url: ${muxed.url}');
    } else if (manifest.hls.isNotEmpty) {
      logMessage('PICK hls: ${manifest.hls.first.url}');
    } else {
      logMessage('PICK: no muxed/hls');
    }
  } catch (e, st) {
    logMessage('FAILED: $e');
    logMessage(st.toString());
  } finally {
    yt.close();
  }
}
