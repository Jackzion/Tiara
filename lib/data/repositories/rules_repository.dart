import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:movies/data/models/source_rule.dart';
import 'package:movies/utils/prefs.dart';

/// 把 [RuleImportResult] 合并进仓库后的结果（给 UI 弹 SnackBar 用）
class RuleMergeResult {
  /// 本次真正新写入/覆盖的条数（成功解析且通过 validate）
  final int importedCount;

  /// 解析阶段失败原因（原样来自 parser）
  final List<String> failures;

  /// 与**已有库**同名覆盖的条数（批内 duplicate 之外）
  final int overwrittenCount;

  /// 本次新出现的名字条数
  final int addedCount;

  const RuleMergeResult({
    required this.importedCount,
    required this.failures,
    required this.overwrittenCount,
    required this.addedCount,
  });

  bool get hasFailures => failures.isNotEmpty;
}

/// 规则仓库：SourceRule 列表 ⇄ SharedPreferences 字符串
///
/// 解析粘贴文本请先走 RuleImportParser.parse，再调用 merge(result.rules)。
/// 本类不负责解析 JSON 形态，只负责「和已有列表合并 + 持久化」。
class RulesRepository {
  // 整表 json 的存储 key
  static const String _storageKey = 'SourceRuleJson';

  final Prefs _prefs;
  List<SourceRule>? _cache;

  RulesRepository(this._prefs);

  /// 全部规则（内存缓存；损坏/空返回空列表）
  List<SourceRule> getAll() {
    final cache = _cache;
    // 缓存直接返回
    if (cache != null) {
      return List.unmodifiable(cache);
    }
    // 从 SharedPreferences 读取
    try {
      final raw = _prefs.getString(_storageKey);
      // 为空或损坏，返回空列表
      if (raw == null || raw.isEmpty) {
        _cache = const [];
        return const [];
      }
      // 解析 JSON 到 SourceRule 列表
      final decode = jsonDecode(raw);
      if (decode is! List) {
        _cache = const [];
        return const [];
      }
      final list = <SourceRule>[];
      for (final item in decode) {
        list.add(SourceRule.fromJson(item));
      }
      _cache = list;
      return List.unmodifiable(list);
    } catch (e) {
      debugPrint('RulesRepository getAll error: $e');
      _cache = const [];
      return const [];
    }
  }

  /// 按名字取（忽略大小写）
  SourceRule? getByName(String name) {
    final key = name.trim().toLowerCase();
    for (final r in getAll()) {
      if (r.name.toLowerCase() == key) {
        return r;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 写
  // ---------------------------------------------------------------------------

  /// 将 parser 解析出的规则合并进已有库并落盘。
  ///
  /// - 与已有同名（`nameKey`）→ 覆盖，overwrittenCount++
  /// - 新名字 → addedCount++
  /// - rules 为空则不写盘（避免误清空）
  Future<RuleMergeResult> mergeRules(
    List<SourceRule> rules, {
    List<String> failures = const [],
    int batchDuplicateCount = 0,
  }) async {
    if (rules.isEmpty) {
      return RuleMergeResult(
        importedCount: 0,
        failures: failures,
        overwrittenCount: 0,
        addedCount: 0,
      );
    }

    final merged = List<SourceRule>.of(getAll());
    final indexByName = <String, int>{
      for (var i = 0; i < merged.length; i++) merged[i].nameKey: i,
    };
    var addCount = 0;
    var overwriteCount = 0;

    for (final r in rules) {
      final existing = indexByName[r.nameKey];
      if (existing != null) {
        merged[existing] = r;
        overwriteCount++;
      } else {
        indexByName[r.nameKey] = merged.length;
        merged.add(r);
        addCount++;
      }
    }

    await _saveAll(merged);
    debugPrint(
      '[RulesRepository] merge: +$addCount ~$overwriteCount total=${merged.length}',
    );
    return RuleMergeResult(
      importedCount: addCount + overwriteCount,
      failures: failures,
      overwrittenCount: overwriteCount,
      addedCount: addCount,
    );
  }

  Future<void> _saveAll(List<SourceRule> rules) async {
    _cache = List<SourceRule>.of(rules);
    final encoded = jsonEncode(rules.map((r) => r.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  Future<void> removeByName(String name) async {
    final rules = getAll();
    final index = rules.indexWhere((r) => r.name.toLowerCase() == name.toLowerCase());
    if (index != -1) {
      rules.removeAt(index);
      await _saveAll(rules);
    }
  }
}
