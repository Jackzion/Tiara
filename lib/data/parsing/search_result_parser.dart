import 'package:movies/data/models/anime.dart';

/// 解析 Bangumi 搜索结果（searchSubjects 响应体）
List<Anime> parseSearchResults(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return [];
  }
  final items = data['data'];
  if (items is! List<dynamic>) {
    return [];
  }
  return items
      .whereType<Map<String, dynamic>>()
      .map(Anime.fromBangumi)
      .toList();
}

/// 提取条目的在看人数（放送日历排序用）
int collectionDoing(Map<String, dynamic> json) {
  final collection = json['collection'] as Map<String, dynamic>?;
  final doing = collection?['doing'];
  return doing is num ? doing.toInt() : 0;
}
