import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Network/fetch 的 Host 实现（消息形状对标 Venera js_engine.dart:_http）
///
/// 与 Venera 对齐的关键点：请求带 **cookie 会话**（Venera 的 AppDio 全程挂
/// CookieManagerSql）。拷贝漫画等源按会话身份限流——无 cookie 的裸请求会被
/// 当成陌生客户端，频繁触发 210「请求过于频繁」。
class HostNetwork {
  HostNetwork({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              responseType: ResponseType.plain,
              validateStatus: (status) => true, // 非 2xx 也回状态码，规则自己判
            ),
          ) {
    // set cookie interceptor
    _dio.interceptors.add(_CookieJar());
  }

  final Dio _dio;

  /// 处理 Network/fetch 请求
  Future<Map<String, dynamic>> handle(Map<String, dynamic> req) async {
    String? error;
    Response? response;
    try {
      final headers = Map<String, dynamic>.from(req['headers'] ?? {});
      headers['User-Agent'] ??= 'Tiara/1.0';
      response = await _dio.request(
        req['url'] as String,
        data: req['data'],
        options: Options(
          method: req['http_method'] as String,
          responseType: req['bytes'] == true
              ? ResponseType.bytes
              : ResponseType.plain,
          headers: headers,
        ),
      );
    } catch (e) {
      error = e.toString();
    }
    final respHeaders = <String, String>{};
    response?.headers.forEach((n, v) => respHeaders[n] = v.join(','));
    dynamic body = response?.data;
    if (body is! Uint8List && body is List<int>) body = Uint8List.fromList(body);
    // 错误放返回值里不抛（init.js 检查 result.error 后 throw）
    return {
      'status': response?.statusCode,
      'headers': respHeaders,
      'body': body,
      'error': error,
    };
  }
}

/// 极简 Cookie 罐（host → {name: value}）：保持规则请求的会话连续性。
/// 只做两件事：吸收 Set-Cookie、回带 Cookie 头。
class _CookieJar extends Interceptor {
  final Map<String, Map<String, String>> _cookies = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final jar = _cookies[options.uri.host];
    if (jar != null && jar.isNotEmpty) {
      options.headers['cookie'] = [
        for (final e in jar.entries) '${e.key}=${e.value}',
      ].join('; ');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _absorb(response.headers['set-cookie'], response.requestOptions.uri.host);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _absorb(err.response?.headers['set-cookie'], err.requestOptions.uri.host);
    handler.next(err);
  }

  void _absorb(List<String>? setCookies, String host) {
    if (setCookies == null) return;
    final jar = (_cookies[host] ??= {});
    for (final raw in setCookies) {
      final pair = raw.split(';').first; // "name=value; Path=/; ..."
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      jar[pair.substring(0, eq).trim()] = pair.substring(eq + 1).trim();
    }
  }
}
