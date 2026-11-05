/// Bangumi JSON 通用解析辅助
/// Anime / AnimeDetails 等模型共用，避免各写一份

/// 解析日期字符串（如 2023-09-29）
DateTime? parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

/// 解析整型（数字或字符串）
int? parseInt(dynamic value) {
  if (value == null) {
    return null;
  }
  return value is num ? value.toInt() : int.tryParse(value.toString());
}

/// 解析浮点（数字或字符串）
double? parseDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  return value is num ? value.toDouble() : double.tryParse(value.toString());
}

/// 从日期字符串提取年份
int? parseYear(String? date) {
  if (date == null || date.length < 4) {
    return null;
  }
  return int.tryParse(date.substring(0, 4));
}

/// 汇总收藏统计（想看/在看/看过/搁置/抛弃）
int? parseCollectionTotal(Map<String, dynamic>? collection) {
  if (collection == null) {
    return null;
  }
  var total = 0;
  var hasValue = false;
  for (final value in collection.values) {
    if (value is num) {
      total += value.toInt();
      hasValue = true;
    }
  }
  return hasValue ? total : null;
}
