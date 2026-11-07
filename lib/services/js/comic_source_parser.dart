import 'dart:convert';

import 'package:movies/data/models/comic_source.dart';
import 'package:movies/services/js/js_engine_service.dart';

class ComicSourceParser {
  ComicSourceParser(this.engine);
  final JsEngineService engine;

  /// 创建并解析一个漫画来源
  /// [js] 是漫画来源的 JS 代码
  /// [fileName] 是漫画来源的文件名
  Future<ComicSource> createAndParse(String js, String fileName) async {
    // 1) 装载规则到 js engine（类名提取 + new + 挂载 + settings 提取）
    final key = await engine.loadRule(js, name: '<$fileName>');

    // 2) 校验标识
    final name = engine.runCode('ComicSource.sources.$key.name') as String;
    final version =
        engine.runCode('ComicSource.sources.$key.version') as String?;
    if (key.isEmpty || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(key)) {
      throw 'key($key) is invalid';
    }

    // 3) 装配闭包
    // comic.loadInfo(id)
    // → {title, cover, chapters: {epId: 章名}, ...}
    Future<Map<String, dynamic>> loadComicInfo(String comicId) async {
      final res = await engine.runCode(
        'ComicSource.sources.$key.comic.loadInfo(${jsonEncode(comicId)})',
      );
      return Map<String, dynamic>.from(res as Map);
    }
    // comic.loadEp(comicId, epId)
    // → {images: string[]}
    Future<List<String>> loadComicPages(String comicId, String epId) async {
      final res = await engine.runCode(
        'ComicSource.sources.$key.comic.loadEp(${jsonEncode(comicId)}, ${jsonEncode(epId)})',
      );
      return List<String>.from((res as Map)['images'] as List);
    }

    // search.load(keyword, [], 1)
    // → {comics: [{id, title, cover, ...}], maxPage}
    Future<List<ComicItem>> searchLoad(String keyword) async {
      final res = await engine.runCode(
        'ComicSource.sources.$key.search.load(${jsonEncode(keyword)}, [], 1)',
      );
      final comics = (res as Map)['comics'] as List? ?? const [];
      return [
        for (final c in comics)
          ComicItem.fromJson(Map<String, dynamic>.from(c as Map)),
      ];
    }

    // comic.onImageLoad(imageKey, comicId, epId)
    // → ImageLoadingConfig（可选），单张图的下载方法参数 ->  { url, method, headers, data }
    Future<Map<String, dynamic>?> getImageLoadingConfig(
      String imageKey,
      String comicId,
      String epId,
    ) async {
      final exists =
          engine.runCode('ComicSource.sources.$key.comic.onImageLoad != null')
              as bool? ??
          false;
      if (!exists) return null;
      final res = await engine.runCode(
        'ComicSource.sources.$key.comic.onImageLoad(${jsonEncode(imageKey)}, ${jsonEncode(comicId)}, ${jsonEncode(epId)})',
      );
      return Map<String, dynamic>.from(res as Map);
    }

    return ComicSource(
      key: key,
      name: name,
      version: version ?? '1.0.0',
      loadComicInfo: loadComicInfo,
      loadComicPages: loadComicPages,
      searchLoad: searchLoad,
      getImageLoadingConfig: getImageLoadingConfig,
    );
  }
}
