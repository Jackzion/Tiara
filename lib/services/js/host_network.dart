import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Network/fetch 的 Host 实现（消息形状对标 Venera js_engine.dart:_http）
class HostNetwork {
  HostNetwork({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              responseType: ResponseType.plain,
              validateStatus: (status) => true, // 非 2xx 也回状态码，规则自己判
            ),
          );
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
    if (body is! Uint8List && body is List<int>)
      body = Uint8List.fromList(body);
    // 错误放返回值里不抛（init.js 检查 result.error 后 throw）
    return {
      'status': response?.statusCode,
      'headers': respHeaders,
      'body': body,
      'error': error,
    };
  }
}
