/// 搜索结果条目（search.load 返回的 comics[] 项；面板三字段够用）
class ComicItem {
  const ComicItem({
    required this.id,
    required this.title,
    this.cover,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? cover;
  final String? subtitle;

  factory ComicItem.fromJson(Map<String, dynamic> json) => ComicItem(
        id: '${json['id']}',
        title: '${json['title']}',
        cover: json['cover'] as String?,
        subtitle: json['subtitle'] as String?,
      );
}

/// 一次搜索匹配：某源搜到的一条候选漫画（matchSearch 结果项）
class ComicMatch {
  const ComicMatch({required this.sourceKey, required this.comic});

  /// 命中的图源 key
  final String sourceKey;

  /// 该源内的漫画条目
  final ComicItem comic;

  /// 便捷转发（loadInfo/loadEp 的入参）
  String get comicId => comic.id;
  String get title => comic.title;

  /// 标题精确命中（matchSearch 置顶判定）
  bool exact(String keyword) => comic.title == keyword;
}

/// 章节（epId → 章名）
class ComicChapter {
  const ComicChapter({required this.epId, required this.title});
  final String epId;
  final String title;
}

/// 一页图（imageKey + 可选加载配置）
class ComicPage {
  const ComicPage({required this.imageKey, this.imageLoadingConfig});
  final String imageKey;
  final Map<String, dynamic>? imageLoadingConfig;
}

/// 已装载的图源规则（Dart 侧门面，闭包由解析器装配）
class ComicSource {
  const ComicSource({
    required this.key,
    required this.name,
    required this.version,
    required this.loadComicInfo,
    required this.loadComicPages,
    required this.searchLoad,
    this.getImageLoadingConfig,
    this.settingsDefaults = const {},
  });

  final String key;
  final String name;
  final String version;

  /// settings 默认值（load_setting 兜底，装载时一次性提取）
  final Map<String, dynamic> settingsDefaults;

  /// comic.loadInfo(id) → {title, cover, chapters: {epId: 章名}, ...}
  final Future<Map<String, dynamic>> Function(String comicId) loadComicInfo;

  /// comic.loadEp(comicId, epId) → {images: string[]}
  final Future<List<String>> Function(String comicId, String epId)
  loadComicPages;

  /// search.load(keyword, [], 1) → comics 条目（matchSearch 用）
  final Future<List<ComicItem>> Function(String keyword) searchLoad;

  /// comic.onImageLoad(imageKey, comicId, epId) → ImageLoadingConfig（可选）
  /// 返回值可空（Future<...?>）：规则无 onImageLoad 时为 null
  final Future<Map<String, dynamic>?> Function(
    String imageKey,
    String comicId,
    String epId,
  )?
  getImageLoadingConfig;
}
