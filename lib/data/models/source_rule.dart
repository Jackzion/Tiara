

class SourceRule {
  /// 规则名（同名导入覆盖，比较时用 name.toLowerCase()）
  final String name;

  /// 站点根 URL
  final String baseUrl;

  /// 搜索 URL，必须含 @keyword 占位符
  final String searchURL;

  /// 搜索结果列表 XPath
  final String searchList;

  /// 结果标题 XPath
  final String searchName;

  /// 结果详情页链接 XPath
  final String searchResult;

  /// 线路容器 XPath
  final String chapterRoads;

  /// 分集链接 XPath
  final String chapterResult;

  /// 请求 UA，空 = 用默认
  final String userAgent;

  /// 反盗链 Referer，空 = 不加
  final String referer;

  /// 搜索是否走 POST
  final bool usePost;

  /// 是否旧 iframe 解析（本期暂不实现，仅存字段）
  final bool useLegacyParser;

  /// Kazumi api 版本号，仅原样保留，Phase 2 不校验
  final String api;

  const SourceRule({
    required this.name,
    required this.baseUrl,
    required this.searchURL,
    required this.searchList,
    required this.searchName,
    required this.searchResult,
    required this.chapterRoads,
    required this.chapterResult,
    required this.userAgent,
    required this.referer,
    required this.usePost,
    required this.useLegacyParser,
    required this.api,
  });

  /// 规则名（小写，用于比较则名）
  String get nameKey => name.trim().toLowerCase();

  /// 必填校验。返回 null 表示通过，否则是错误文案。
  String? validate() {
    if (name.trim().isEmpty) return 'name 不能为空';
    if (baseUrl.trim().isEmpty) return 'baseURL 不能为空';
    if (searchURL.trim().isEmpty) return 'searchURL 不能为空';
    if (!searchURL.contains('@keyword')) {
      return 'searchURL 必须包含 @keyword';
    }
    if (searchList.trim().isEmpty) return 'searchList 不能为空';
    if (searchName.trim().isEmpty) return 'searchName 不能为空';
    if (searchResult.trim().isEmpty) return 'searchResult 不能为空';
    if (chapterRoads.trim().isEmpty) return 'chapterRoads 不能为空';
    if (chapterResult.trim().isEmpty) return 'chapterResult 不能为空';
    return null;
  }

  /// 解析社区完整规则时，未知字段一律忽略，不报错。
  factory SourceRule.fromJson(Map<String, dynamic> json) {
    return SourceRule(
      api: json['api']?.toString() ?? '1',
      name: json['name'] as String? ?? '',
      // 注意：JSON 里是 baseURL，Dart 属性名用 baseUrl（Dart 风格）
      baseUrl: json['baseURL'] as String? ?? '',
      searchURL: json['searchURL'] as String? ?? '',
      searchList: json['searchList'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      searchResult: json['searchResult'] as String? ?? '',
      chapterRoads: json['chapterRoads'] as String? ?? '',
      chapterResult: json['chapterResult'] as String? ?? '',
      userAgent: json['userAgent'] as String? ?? '',
      referer: json['referer'] as String? ?? '',
      usePost: json['usePost'] as bool? ?? false,
      useLegacyParser: json['useLegacyParser'] as bool? ?? false,
      // searchMode / apiRuleConfig / antiCrawlerConfig 等：直接无视
    );
  }

  /// 写出时保持 Kazumi 字段名，保证与 Kazumi rules 互通。
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'api': api,
      'type': 'anime',
      'name': name,
      'baseURL': baseUrl,
      'searchURL': searchURL,
      'searchList': searchList,
      'searchName': searchName,
      'searchResult': searchResult,
      'chapterRoads': chapterRoads,
      'chapterResult': chapterResult,
      'userAgent': userAgent,
      'referer': referer,
      'usePost': usePost,
      'useLegacyParser': useLegacyParser,
    };
  }

  @override
  String toString() => 'SourceRule($name)';
}
