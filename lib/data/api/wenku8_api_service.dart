import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/api/request_throttle.dart';

/// wenku8 App XML API 客户端（经社区中继）。
///
/// 协议（docs/wenku8-api-协议调研.md §7.5，逆向 libcpp.so 并 curl 实证）：
/// - 端点：`POST https://wenku8-relay.mewx.org/`（官方 app.wenku8.com 已死，仅中继可用）
/// - body：`appver={魔改版本}&timetoken={毫秒}&request={URLENCODED(base64(action))}`
/// - 魔改 appver：HMAC-SHA256(salt, "raw|salt|分钟") hex[12:20] 拼接
/// - 响应：UTF-8 XML（`<result>/<metadata>/<package>`）或纯文本正文
/// - 节奏：连发会被限流/超时，全局 ≥2s 间隔（实测结论）
class Wenku8ApiService {
  Wenku8ApiService({Dio? dio, RequestThrottle? throttle})
      : _dio = dio ?? Dio(),
        _throttle = throttle ??
            RequestThrottle(interval: const Duration(seconds: 2)) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
        'user-agent': 'Android',
      },
      // 中继返回 UTF-8 XML/纯文本
      responseType: ResponseType.plain,
      validateStatus: (s) => s != null && s < 500,
    );
  }

  /// 中继端点（官方 app.wenku8.com/android.php 已失效，勿用）
  static const String endpoint = 'https://wenku8-relay.mewx.org/';

  /// 版本基串与盐（逆向 libcpp.so 实证；1.23→nano-mewx，其他→unknown）
  static const String rawVersion = '1.30';
  static const Map<String, String> _salts = {
    '1.30': 'digital-bento',
    '1.23': 'nano-mewx',
  };

  final Dio _dio;
  final RequestThrottle _throttle;

  /// 魔改 appver：HMAC-SHA256(key=salt, msg="raw|salt|分钟") 取 hex[12:20]。
  /// [at] 仅测试用（时间桶 = floor(unix秒/60)，服务端按分钟校验）。
  static String magicAppver({DateTime? at}) {
    final now = at ?? DateTime.now();
    final minute = now.millisecondsSinceEpoch ~/ 1000 ~/ 60;
    final salt = _salts[rawVersion] ?? 'unknown';
    final msg = '$rawVersion|$salt|$minute';
    final mac = Hmac(sha256, utf8.encode(salt))
        .convert(utf8.encode(msg))
        .toString();
    return '$rawVersion-$salt-${mac.substring(12, 20)}';
  }

  /// 发送一个 action 串，返回响应文本（XML/纯文本）
  Future<String> _call(String action, {bool retried = false}) async {
    await _throttle.wait();
    final request = Uri.encodeComponent(base64Encode(utf8.encode(action)));
    final body =
        'appver=${Uri.encodeComponent(magicAppver())}'
        '&timetoken=${DateTime.now().millisecondsSinceEpoch}'
        '&request=$request';
    try {
      final res = await _dio.post<String>(endpoint, data: body);
      final text = res.data?.trim() ?? '';
      // appver 校验失败 / 中继拒绝（正常不该发生）
      if (text.contains('Bad request')) {
        throw Wenku8ApiException(action, 'appver 校验失败');
      }
      // 空响应 = 中继抖动，重试一次
      if (text.isEmpty && !retried) {
        logMessage('[Wenku8Api] empty response, retry: $action');
        await Future.delayed(const Duration(seconds: 2));
        return await _call(action, retried: true);
      }
      return text;
    } catch (e) {
      if (!retried && e is! Wenku8ApiException) {
        // 超时/网络抖动：退避 2s 重试一次
        logMessage('[Wenku8Api] fail ($e), retry: $action');
        await Future.delayed(const Duration(seconds: 2));
        return _call(action, retried: true);
      }
      rethrow;
    }
  }

  // ── action 构造（词表见协议调研 §2.2）────────────────────────

  /// 列表（带摘要）：action=novellist
  Future<String> novellist(String sort, int page) =>
      _call('action=novellist&sort=$sort&page=$page&t=0');

  /// 搜索（书名/作者）：action=search
  Future<String> search(String keyword, {int page = 1, String type = 'articlename'}) =>
      _call('action=search&searchtype=$type'
          '&searchkey=${Uri.encodeComponent(keyword)}&page=$page&t=0');

  /// 书籍元数据：action=book&do=meta
  Future<String> bookMeta(int aid) =>
      _call('action=book&do=meta&aid=$aid&t=0');

  /// 分卷目录：action=book&do=list
  Future<String> bookCatalog(int aid) =>
      _call('action=book&do=list&aid=$aid&t=0');

  /// 章节正文：action=book&do=text（纯文本 + <!--image--> 插图标记）
  Future<String> bookText(int aid, int cid) =>
      _call('action=book&do=text&aid=$aid&cid=$cid&t=0');

  /// 封面图地址（调研 §4：img.wenku8.com 固定模式）
  static String coverUrl(int aid) =>
      'https://img.wenku8.com/image/${aid ~/ 1000}/$aid/${aid}s.jpg';
}

/// API 调用失败（重试耗尽后抛出）
class Wenku8ApiException implements Exception {
  const Wenku8ApiException(this.action, this.detail);

  final String action;
  final String detail;

  @override
  String toString() => 'Wenku8ApiException($action): $detail';
}
