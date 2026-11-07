import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 内置源清单条目（assets/index.json，字段对齐 venera-configs）
class ComicSourceRuleEntry {
  /// 内置源清单条目
  //   {
  //     "name": "Source Name",
  //     "url": "https://example.com/source.js",
  //     "filename": "Relative path to the source file",
  //     "version": "1.0.0",
  //     "description": "A brief description of the source"
  //   }
  // ]
  const ComicSourceRuleEntry({
    required this.name,
    required this.key,
    required this.fileName,
    required this.version,
    this.description,
    this.url,
  });

  final String name;
  final String key;
  final String fileName;
  final String version;
  final String? description;

  /// 可选：独立下载地址；为空则用 [RuleCatalogService.remoteBase] + fileName
  final String? url;

  factory ComicSourceRuleEntry.fromJson(Map<String, dynamic> json) =>
      ComicSourceRuleEntry(
        name: json['name'] as String,
        key: json['key'] as String,
        fileName: json['fileName'] as String,
        version: json['version'] as String,
        description: json['description'] as String?,
        url: json['url'] as String?,
      );
}

/// 规则目录服务：解析内置清单 + 启动同步下载规则 .js。
class RuleCatalogService {
  final Dio _dio;
  RuleCatalogService({Dio? dio}) : _dio = dio ?? Dio();

  /// 规则下载基址（venera-configs 仓库的 CDN 镜像）。
  /// 条目自带 url 时优先用 url。
  static const remoteBase =
      'https://cdn.jsdelivr.net/gh/venera-app/venera-configs@main';

  /// 读内置清单 -> ruleEntry
  /// 从 assets/index.json 读取内置源清单。
  Future<List<ComicSourceRuleEntry>> loadCatalog() async {
    final raw = await rootBundle.loadString('assets/index.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ComicSourceRuleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取规则落盘目录
  Future<Directory> ruleDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}comic_source');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 加载 manifest.json
  /// manifest.json -> 维护已下载 coumic_source.js 的版本清单
  Future<Map<String, dynamic>> _loadManifest(Directory dir) async {
    final file = File('${dir.path}${Platform.pathSeparator}manifest.json');
    if (!await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// 保存 manifest.json
  Future<void> _saveManifest(Directory dir, Map<String, dynamic> manifest) {
    final file = File('${dir.path}${Platform.pathSeparator}manifest.json');
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
  }

  /// 启动同步：清单逐条「本地缺失或版本落后 → 下载」。
  /// [onlyKeys]：只同步指定 key，可选，为 null 则 download all
  /// 返回本次实际下载成功的 key 列表。单条失败只记日志，不阻塞其它条。
  Future<List<String>> syncOnStartup({List<String>? onlyKeys}) async {
    // 加载 rule index.json 清单
    final entries = await loadCatalog();
    final dir = await ruleDir();
    // 加载 manifest 已同步的维护清单
    final manifest = await _loadManifest(dir);
    final downloaded = <String>[];

    for (final entry in entries) {
      // 若已指定 onlyKey 则只下载指定源
      if (onlyKeys != null && !onlyKeys.contains(entry.key)) continue;

      final localVersion =
          (manifest[entry.key] as Map<String, dynamic>?)?['version'] as String?;
      final file = File(
        '${dir.path}${Platform.pathSeparator}${entry.fileName}',
      );
      final exists = await file.exists();
      // 简单三段 semver：本地 ≥ 清单 则跳过
      if (exists &&
          localVersion != null &&
          _cmpVer(localVersion, entry.version) >= 0) {
        continue;
      }
      // get the new commic source from venera server
      final url = entry.url ?? '$remoteBase/${entry.fileName}';
      try {
        final res = await _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: {'cache-time': 'no'}, // 绕开缓存拿新规则
          ),
        );
        final js = res.data ?? '';
        // 落盘前做最小校验：必须是个 ComicSource 规则
        if (!js.contains('extends ComicSource')) {
          throw FormatException('下载内容不是合法规则: $url');
        }
        // write as js file locally
        await file.writeAsString(js);
        // update manifest file
        manifest[entry.key] = {
          'version': entry.version,
          'fileName': entry.fileName,
          'downloadedAt': DateTime.now().toIso8601String(),
        };
        // update downloaded
        downloaded.add(entry.key);
      } catch (e) {
        // 单条失败不阻塞启动；规则缺失时 UI 空态兜底（Phase 2d）
        // ignore: avoid_print
        print('[RuleCatalog] 下载失败 ${entry.key}: $e');
      }
    }

    await _saveManifest(dir, manifest);
    return downloaded;
  }

  /// 比较版本号
  /// a > b 返回 1；相等 0；a < b 返回 -1。只比前三段数字。
  static int _cmpVer(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    for (var i = 0; i < 3; i++) {
      final na = i < pa.length ? (int.tryParse(pa[i]) ?? 0) : 0;
      final nb = i < pb.length ? (int.tryParse(pb[i]) ?? 0) : 0;
      if (na != nb) return na.compareTo(nb);
    }
    return 0;
  }
}
