import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movies/services/video_source/video_source.dart';
import 'package:webview_windows/webview_windows.dart';

/// WebView 取流服务
///
/// 职责：输入「分集页 URL」→ 输出「m3u8/mp4 直链」。
///
/// 并发模型（对齐 Kazumi，故意做简）：
/// - 应用内只保留 **一个** HeadlessWebview 实例；
/// - 同一时刻只为 **一次** resolve 服务：新的 parseVideoSource 会取消上一次；
/// - 任务按调用顺序串行执行（新任务排队等旧任务让出 WebView）。
class WebviewVideoSourceService{
  /// 无头 WebView 本体。null = 还没创建（懒初始化）
  HeadlessWebview? _webview;
  /// 本次 loadUrl 产生的流订阅；unload 时全部取消，防止旧监听重复触发
  final List<StreamSubscription> _subscriptions  = [];
  /// 「解析事件」广播喇叭：内部实现往里 add，resolve 侧 .first 等第一个
  final StreamController<VideoSource> _resolvedController  = StreamController<VideoSource>.broadcast();
  /// 当前进行中的请求；新请求会把它标为取消
  _ParseRequest? _activeRequest;
  /// 串行队列的队尾：等上一个任务彻底结束才跑下一个
  Future<void> _queueTail = Future.value();
  /// 默认超时
  static const Duration defaultTimeout = Duration(seconds: 10);
  /// 服务是否已销毁；销毁后拒绝新的 parse
  bool _disposed = false;


  /// 解析分集页，返回可直接播放的直链。
  /// [pageUrl] 分集 HTML 页地址（不是 m3u8 本身）。
  /// [timeout] 等待媒体事件的最长时间。
  Future<VideoSource> parseVideoSource(String pageUrl, {Duration timeout = defaultTimeout}){
    if(_disposed){
      throw const VideoSourceCanceledException();
    }
    // 作废上次请求
    _activeRequest?.cancel();

    // 登记本次请求
    final request = _ParseRequest();
    _activeRequest = request;

    // 排队到队尾：等 _queueTail 完成后再跑 request，避免资源没清除
    // runParse list
    final result = _queueTail.then((value) => _runParse(request,pageUrl,timeout));

    // 更新链尾。注意：链尾吞掉错误，避免「未被 listen 的 Future」报警；
    // Future 的规则：上游以错误完成时，【onValue 根本不会被调用】，错误直接顺延下去
    // 显示定义空 onError，吃掉报错，使后续 future 顺利执行
    _queueTail = result.then<void>((value){},onError:(_){});

    return result;
  }

  /// 取消当前进行中的解析任务。
  void cancel() {
    _activeRequest?.cancel();
  }

  /// 销毁：不再接受新任务 → 取消进行中的 → 等队列排空 → 销毁 WebView。
  /// 一般只在 provider dispose 或 App 退出时调用。
  Future<void> dispose() async{
    _disposed = true;
    _activeRequest?.cancel();
    final tail = _queueTail;
    try{
      await tail;
    } catch(_){// 在途任务可能因取消抛错，这里忽略
    }
    await _unloadPage();
    final wv = _webview;
    _webview = null;
    try {
      await wv?.dispose();
    } catch (e) {
      debugPrint('[VideoSource] dispose webview error: $e');
    }
  }

  Future<VideoSource> _runParse(_ParseRequest request, String pageUrl, Duration timeout) async {
    request.throwIfNotCurrent(_activeRequest);
    
    // 懒初始化
    await _ensureWebview();
    request.throwIfNotCurrent(_activeRequest);

    // 清除上一页的监听和页面
    await _unloadPage();
    
    // 注册监听 - streamController listen 返回 StreamSubscription
    // 监听 m3u8 事件
    _subscriptions.add(_webview!.onM3USourceLoaded.listen((data) {
      // onData
      final url = (data['url'] ?? '');
      if(url.isEmpty){
        return;
      }
      debugPrint('[VideoSource] m3u8: $url');
      _notifyResolved(VideoSource(url, format: VideoSourceFormat.hls));
    }));
    // 监听 video 事件
    _subscriptions.add(_webview!.onVideoSourceLoaded.listen((data) {
      // onData
      final url = (data['url'] ?? '');
      if(url.isEmpty){
        return;
      }
      debugPrint('[VideoSource] video: $url');
      _notifyResolved(VideoSource(url)); // format 默认 auto
    }));

    // 加载分集页
    await _webview!.loadUrl(pageUrl);
    request.throwIfNotCurrent(_activeRequest);

    // ---- 三方竞争：媒体事件 / 取消 / 超时 ----
    // first 也是监听 ， 用 onData 触发到第一个事件，作为解析结果
    final mediaFuture = _resolvedController.stream.first.timeout(
      timeout,
      // 超时处理：取消请求
      onTimeout: (){
        request.throwIfNotCurrent(_activeRequest);
        throw VideoSourceTimeoutException(timeout);
      }
    );

    final cancelFuture = request.cancelled.then<VideoSource>((value) => throw VideoSourceCanceledException());
    try{
      final source =  await Future.any([mediaFuture, cancelFuture]);
      request.throwIfNotCurrent(_activeRequest);
      return source;
    } finally {
      // 无论成功失败，都释放页面和监听
      await _unloadPage();
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    }
  }

  /// 确保 WebView 已初始化，
  /// 已存在则直接返回，不存在则创建并初始化。
  Future<void> _ensureWebview() async{
    if(_webview != null){
      return;
    }
    final wv = HeadlessWebview();
    await wv.run();
    // 不允许页面弹新窗口，保持无头模式
    await wv.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    _webview = wv;
    debugPrint('[VideoSource] HeadlessWebview ready');
  }

  /// 取消全部旧订阅，并把当前页跳到 about:blank。
  /// （webview_windows 没有 unload API，Kazumi 也是用跳空白页代替。）
  ///
  /// 可重入：媒体事件命中时的 `_notifyResolved` 和 `_runParse` 的 finally
  /// 可能几乎同时调用本方法。必须「先摘下列表再清空」，否则一边 for-in、
  /// 一边 clear() 会抛 Concurrent modification during iteration。
  Future<void> _unloadPage() async {
    // 先把当前订阅拷贝出来，并立刻清空原列表
    // 之后并发再进来时看到的是空列表，不会和本次迭代打架 
    // 避免 _notifyResolved 里 unawaited(_unloadPage()) and _runParse 的 finally 里 await _unloadPage() 触发并发问题
    final subs = List<StreamSubscription>.from(_subscriptions);
    _subscriptions.clear();

    // ② 对拷贝出来的快照逐个 cancel（对齐 Kazumi：不 await cancel，
    //    避免在 await 空隙里再被插入修改）
    for (final s in subs) {
      try {
        s.cancel();
      } catch (_) {}
    }

    // ③ 页面跳空白页释放资源
    final wv = _webview;
    if (wv == null) return;
    try {
      await wv.executeScript('window.location.href = "about:blank";');
    } catch (_) {}
  }

  /// 通知 resolve 侧解析结果
  void _notifyResolved(VideoSource videoSource) {
    if(_resolvedController.isClosed){
      return;
    }
    // 通知 resolve 侧
    _resolvedController.add(videoSource);
    // 命中后尽快释放页面和监听（监听已由 _resolvedController 消费一次）
    unawaited(_unloadPage());
  }
}

/// 单次解析请求的 [取消开关]
class _ParseRequest{
  final Completer<void> _cancelled = Completer<void>();

  /// 取消信号：cancel 后该 Future 立刻完成
  Future<void> get cancelled => _cancelled.future;

  void cancel(){
    if(!_cancelled.isCompleted){
      _cancelled.complete();
    }
  }

  /// 在每个 await 前后检查：我是否仍是「当前有效请求」？
  /// 不是 → 抛 Cancelled，让过期任务闭嘴，避免污染 UI。
  void throwIfNotCurrent(_ParseRequest? current){
    if(_cancelled.isCompleted || !identical(current, this)){
      throw const VideoSourceCanceledException();
    }
  }
}