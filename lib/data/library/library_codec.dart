import 'dart:convert';

import 'package:movies/data/database/models/rules_model.dart';
import 'package:movies/data/models/source_rule.dart';

/// `Road` / `SourceRule` 与 JSON 的互转。
///
/// 续看要能「不进搜索、直接开播」，就必须把当次解析出的规则与线路一起存下来；
/// 这两个类型本身没有 toJson/fromJson，这里集中处理，避免散落在各页面。
Map<String, dynamic> roadToJson(Road road) => {
  'name': road.name,
  'data': road.data,
  'identifier': road.identifier,
};

Road roadFromJson(Map<String, dynamic> json) => Road(
  name: json['name'] as String? ?? '',
  data: (json['data'] as List?)?.map((e) => '$e').toList() ?? const [],
  identifier: (json['identifier'] as List?)?.map((e) => '$e').toList() ??
      const [],
);

String encodeRoads(List<Road> roads) =>
    jsonEncode([for (final road in roads) roadToJson(road)]);

List<Road> decodeRoads(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map) roadFromJson(Map<String, dynamic>.from(item)),
    ];
  } catch (_) {
    return const [];
  }
}

String? encodeRule(SourceRule? rule) =>
    rule == null ? null : jsonEncode(rule.toJson());

SourceRule? decodeRule(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return SourceRule.fromJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}
