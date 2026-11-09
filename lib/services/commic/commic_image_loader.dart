import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/api/request_throttle.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:path_provider/path_provider.dart';

/// 单图加载失败（UI 单张错误态用，带 imageKey 便于定位）
class ComicImageException implements Exception {
  final String message;
  final String imageKey;
  ComicImageException(this.message, this.imageKey);
  @override
  String toString() => 'ComicImageException($imageKey): $message';
}

class ComicImageLoader {

  ComicImageLoader({Dio? dio, RequestThrottle? throttle})
      : _dio = dio ?? Dio(),
        _throttle = throttle ??
            RequestThrottle(interval: const Duration(milliseconds: 300));
  
  final Dio _dio;

  final RequestThrottle _throttle;

  /// 并发上限：避免打爆图源站 / 本机 socket
  static const int _maxConcurrent = 4;

  // 当时下载中 activate task 数量
  int _active = 0;
  // 超过 _maxConcurrent 的下载要进入等待队列，控制并发下载 task count
  final List<Completer<void>> _queue = [];

  /// 在途去重：同 cacheKey 只发一次请求
  final Map<String, Future<File>> _inflight = {};

  /// get cache dir - 缓存图片 fileDir
  Future<Directory> _cacheDir() async {
    // get app dir
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}comic_cache');
    if (!await dir.exists()) {
      dir.create(recursive: true);
    }
    return dir;
  }

  /// get cache key - 缓存图片 fileName
  String cacheKey({
    required String imageKey,
    required String sourceKey,
    required String comicId,
    required String epId,
  }) {
    return '$imageKey@$sourceKey@$comicId@$epId';
  }

  String _fileNameFor(String cacheKey) {
    return md5.convert(utf8.encode(cacheKey)).toString();
  }

  /// 删除某一页缓存（单张重试前调用）
  Future<void> evict({
    required String imageKey,
    required String sourceKey,
    required String comicId,
    required String epId,
  }) async {
    final dir = await _cacheDir();
    // get cache key
    final key = cacheKey(
      imageKey: imageKey,
      sourceKey: sourceKey,
      comicId: comicId,
      epId: epId,
    );
    // delete the file by key
    final file = File(
      '${dir.path}${Platform.pathSeparator}${_fileNameFor(key)}',
    );
    if (await file.exists()) {
      await file.delete();
    }
    _inflight.remove(key);
    logMessage('[ComicCache] evict $key');
  }

  /// 清空磁盘缓存 - clear all cache
  Future<void> clearCache() async {
    // delete the comic cache dir
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _inflight.clear();
    logMessage('[ComicCache] cleared');
  }

  /// 确保该页图片就绪，返回本地文件（缓存命中则零网络）
  Future<File> ensure(
    ComicPage page, {
    required String sourceKey,
    required String comicId,
    required String epId,
  }) {
    final key = cacheKey(
      imageKey: page.imageKey,
      sourceKey: sourceKey,
      comicId: comicId,
      epId: epId,
    );
    return _inflight.putIfAbsent(
      key,
      () =>
          _withPermit(() => _ensure(key, page))
              .whenComplete(() => _inflight.remove(key)),
    );
  }

  /// 预取入缓存（吞异常，不打扰 UI）
  Future<void> prefetch(
    ComicPage page, {
    required String sourceKey,
    required String comicId,
    required String epId,
  }) async {
    try {
      await ensure(page, sourceKey: sourceKey, comicId: comicId, epId: epId);
    } catch (e) {
      logMessage('[ComicPrefetch] skip ${page.imageKey}: $e');
    }
  }

  /// 简易并发上限（信号量语义）
  Future<T> _withPermit<T>(Future<T> Function() task) async {
    // 当超过 _maxConcurrent 最大并行下载量，造 Completer 作为 token 加入队列，等待其他 task 完成后 complete 释放
    if (_active >= _maxConcurrent) {
      final waiter = Completer<void>();
      _queue.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      // 下载逻辑
      return await task();
    } finally {
      _active--;
      if (_queue.isNotEmpty) {
        // 释放等待队列里的 token
        _queue.removeAt(0).complete();
      }
    }
  }

  /// 确认 comicPage cache file 是否存在，不存在则下载
  Future<File> _ensure(String cacheKey, ComicPage page) async {
    final dir = await _cacheDir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${_fileNameFor(cacheKey)}',
    );

    // 命中短路：存在且非空才算命中
    if (await file.exists()) {
      if (await file.length() > 0) {
        logMessage('[ComicCache] hit $cacheKey');
        return file;
      }
      // file not exit , delete the cache file
      await file.delete();
    }

    // 下载（失败重试 1 次）
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _download(page, file);
        logMessage('[ComicDL] ok ${page.imageKey} attempt=$attempt');
        return file;
      } catch (e) {
        lastError = e;
        logMessage('[ComicDL] fail ${page.imageKey} attempt=$attempt: $e');
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    throw ComicImageException(page.imageKey, '$lastError');
  }

  /// 下载 comicPage 图片到 cache file
  Future<void> _download(ComicPage page, File target) async {
    // imageLoadingConfig 是 onImageLoad 的原始 Map：{url, method, headers, data}
    final config = page.imageLoadingConfig;

    // onResponse / modifyImage（JS 函数值）
    if (config != null &&
        (config.containsKey('onResponse') ||
            config.containsKey('modifyImage'))) {
      logMessage(
        '[ComicDL] warn ${page.imageKey}: onResponse/modifyImage，按原图下载',
      );
    }

    // 依 imageLoadingConfig 组装请求参数
    final url = (config?['url'] as String?) ?? page.imageKey;
    final method = ((config?['method'] as String?) ?? 'GET').toUpperCase();
    final headers = <String, String>{
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Tiara/1.0',
      ...?((config?['headers'] as Map?)?.cast<String, String>()),
    };
    // 限制请求 token
    await _throttle.wait();
    // get temp file path
    final tmp = File('${target.path}.part');

    final response = await _dio.request<List<int>>(
      url,
      options: Options(
        method: method,
        headers: headers,
        responseType: ResponseType.bytes,
        validateStatus: (s) => s != null && s < 500,
      ),
      data: config?['data'],
    );

    final status = response.statusCode ?? 0;
    final bytes = response.data;
    if (status != 200 || bytes == null || bytes.isEmpty) {
      throw ComicImageException(page.imageKey, 'HTTP $status');
    }

    // write and rename the cache file
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(target.path);
  }
}
