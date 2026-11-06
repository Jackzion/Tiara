import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 请求计时拦截器
/// 类似 Java AOP 的环绕通知：onRequest 记开始时间，onResponse / onError 计算耗时并打印
/// 注册一次即可覆盖该 Dio 实例的所有请求，无需在每个方法里手写 Stopwatch
///
/// 用法：dio.interceptors.add(TimingInterceptor(tag: 'AniList'));
class TimingInterceptor extends Interceptor {
  /// 日志标签（对应项目里的 [Tag] 风格）
  final String tag;

  TimingInterceptor({required this.tag});

  /// Stopwatch 在 extra 中的存放键
  static const String _stopwatchKey = 'timing_interceptor_stopwatch';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 在请求发出前启动计时（不含外层 throttle 等待时间）
    options.extra[_stopwatchKey] = Stopwatch()..start();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, result: '${response.statusCode}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, result: 'ERR ${err.type.name}');
    super.onError(err, handler);
  }

  /// 停止计时并打印耗时
  void _log(RequestOptions options, {required String result}) {
    final stopwatch = options.extra[_stopwatchKey] as Stopwatch?;
    stopwatch?.stop();
    final ms = stopwatch?.elapsedMilliseconds;
    // GraphQL 请求统一打到同一个 URL，附带 variables 便于区分查询内容
    final data = options.data;
    final variables = data is Map && data['variables'] != null
        ? ' ${data['variables']}'
        : '';
    debugPrint(
        '[$tag] ${options.method} ${options.uri} => $result in ${ms}ms$variables');
  }
}
