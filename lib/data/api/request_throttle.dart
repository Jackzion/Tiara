import 'dart:async';

/// 请求节流器
/// 串行化请求并保证最小间隔，避免触发 API 限流
class RequestThrottle {
  /// 最小请求间隔
  final Duration interval;

  /// 上一次请求发起时间
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// 请求排队锁
  Future<void> _lock = Future.value();

  RequestThrottle({this.interval = const Duration(seconds: 1)});

  /// 等待轮到本次请求（与上一次请求至少间隔 [interval]）
  Future<void> wait() {
    // 获取前个任务 future 令牌
    final previous = _lock;
    // 创建新任务 future 令牌
    final done = Completer<void>();
    // 更新请求排队锁为新任务 future 令牌
    _lock = done.future;
    return previous.then((_) {
      final elapsed = DateTime.now().difference(_lastRequestTime);
      final delay = elapsed < interval ? interval - elapsed : Duration.zero;
      return Future.delayed(delay);
    }).whenComplete(() {
      // 更新上一次请求发起时间
      _lastRequestTime = DateTime.now();
      // complete 手动触发 done
      done.complete();
    });
  }
}
