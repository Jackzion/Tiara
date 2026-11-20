import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lumberdash/lumberdash.dart';
import 'package:path_provider/path_provider.dart';

/// 章节正文磁盘缓存（模式对标 ComicImageLoader）。
///
/// - 命中零网络；文件名 = md5(sourceKey@bookId@chapterId)，定长非完整性校验
/// - 在途去重：同章并发只取一次
/// - `.part` 原子写：崩溃不留半截文件
/// - 简化 CacheEpoch：清缓存/删章先 bump 世代，迟到写入丢弃
class NovelTextLoader {
  NovelTextLoader();

  static const String _cacheDirName = 'novel_cache';

  final Map<String, Future<String>> _inflight = {};
  int _epoch = 0;

  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir =
        Directory('${base.path}${Platform.pathSeparator}$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileNameFor(String cacheKey) =>
      md5.convert(utf8.encode(cacheKey)).toString();

  static String cacheKey({
    required String sourceKey,
    required String bookId,
    required String chapterId,
  }) =>
      '$sourceKey@$bookId@$chapterId';

  /// 确保该章正文就绪（缓存命中则零网络）。[fetch] 为回源闭包。
  Future<String> ensure({
    required String sourceKey,
    required String bookId,
    required String chapterId,
    required Future<String> Function() fetch,
  }) {
    final key = cacheKey(
      sourceKey: sourceKey,
      bookId: bookId,
      chapterId: chapterId,
    );
    return _inflight.putIfAbsent(
      key,
      () => _ensure(key, fetch).whenComplete(() {
        // 注意：必须用块语句（防 whenComplete 自引用死锁）
        _inflight.remove(key);
      }),
    );
  }

  Future<String> _ensure(
    String cacheKey,
    Future<String> Function() fetch,
  ) async {
    final dir = await _cacheDir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${_fileNameFor(cacheKey)}',
    );

    // 命中短路：存在且非空才算命中
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        logMessage('[NovelCache] hit $cacheKey');
        return content;
      }
      await file.delete();
    }

    final text = await fetch();
    if (text.trim().isEmpty) {
      throw const NovelTextException('章节正文为空');
    }
    // 原子写；写入前校验世代（防止 evict 后迟到写入复活缓存）
    final epoch = _epoch;
    final tmp = File('${file.path}.part');
    await tmp.writeAsString(text, flush: true);
    if (epoch != _epoch) {
      await tmp.delete();
      logMessage('[NovelCache] drop stale $cacheKey');
    } else {
      await tmp.rename(file.path);
    }
    return text;
  }

  /// 删除某章缓存（规则变更/强制刷新用）
  Future<void> evict({
    required String sourceKey,
    required String bookId,
    required String chapterId,
  }) async {
    _epoch++;
    final dir = await _cacheDir();
    final key = cacheKey(
      sourceKey: sourceKey,
      bookId: bookId,
      chapterId: chapterId,
    );
    final file = File(
      '${dir.path}${Platform.pathSeparator}${_fileNameFor(key)}',
    );
    if (await file.exists()) {
      await file.delete();
    }
    _inflight.remove(key);
    logMessage('[NovelCache] evict $key');
  }

  /// 清空磁盘缓存
  Future<void> clearCache() async {
    _epoch++;
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _inflight.clear();
    logMessage('[NovelCache] cleared');
  }
}

/// 章节正文获取失败
class NovelTextException implements Exception {
  const NovelTextException(this.detail);

  final String detail;

  @override
  String toString() => 'NovelTextException($detail)';
}
