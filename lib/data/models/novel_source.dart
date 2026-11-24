/// 搜索结果条目（search.load 返回的 novels[] 项；选源面板三字段够用）
class NovelItem {
  const NovelItem({
    required this.id,
    required this.title,
    this.cover,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? cover;
  final String? subtitle;

  factory NovelItem.fromJson(Map<String, dynamic> json) => NovelItem(
        id: '${json['id']}',
        title: '${json['title']}',
        cover: json['cover'] as String?,
        subtitle: json['subtitle'] as String?,
      );
}

/// 一次搜索匹配：某源搜到的一条候选小说（matchSearch 结果项）
class NovelMatch {
  const NovelMatch({required this.sourceKey, required this.novel});

  /// 命中的书源 key
  final String sourceKey;

  /// 该源内的小说条目
  final NovelItem novel;

  /// 便捷转发（loadInfo/loadText 的入参）
  String get bookId => novel.id;
  String get title => novel.title;

  /// 标题精确命中（matchSearch 置顶判定）
  bool exact(String keyword) => novel.title == keyword;
}

/// 章节（chapterId → 章名，可带分卷归属）
class NovelChapter {
  const NovelChapter({
    required this.chapterId,
    required this.title,
    this.volumeTitle,
  });

  final String chapterId;
  final String title;

  /// 分卷名（无分卷的书为空/来源不提供分卷时为 null）
  final String? volumeTitle;

  factory NovelChapter.fromJson(Map<String, dynamic> json) => NovelChapter(
        chapterId: '${json['chapterId']}',
        title: '${json['title']}',
        volumeTitle: json['volumeTitle'] as String?,
      );
}

/// 一本书的详情（loadInfo 的结构化返回；chapters 顺序即阅读顺序）
class NovelDetail {
  const NovelDetail({
    required this.title,
    required this.chapters,
    this.cover,
    this.author,
    this.intro,
  });

  final String title;
  final String? cover;
  final String? author;
  final String? intro;

  /// 章节目录（chapterId 稳定；正文按需 loadText）
  final List<NovelChapter> chapters;

  /// loadInfo(id) → {title, cover, author, intro, chapters, ...} 的解析。
  /// chapters 兼容两种形态：Map（chapterId → 章名）或
  /// List<Map>（{chapterId, title, volumeTitle}，携带分卷信息）。
  factory NovelDetail.fromInfo(Map<String, dynamic> info) {
    final raw = info['chapters'];
    List<NovelChapter> chapters;
    if (raw is List) {
      chapters = [
        for (final c in raw)
          NovelChapter.fromJson(Map<String, dynamic>.from(c as Map)),
      ];
    } else {
      final map = (raw as Map?) ?? const {};
      chapters = [
        for (final e in map.entries)
          NovelChapter(chapterId: '${e.key}', title: '${e.value}'),
      ];
    }
    return NovelDetail(
      title: '${info['title'] ?? ''}',
      cover: info['cover'] as String?,
      author: info['author'] as String?,
      intro: info['intro'] as String?,
      chapters: chapters,
    );
  }
}

/// 章内阅读进度（序列化进 library_entry.playParamsJson）。
///
/// kind 字段与动画的播放参数 JSON 区分；坐标是段落级锚点，
/// 换排版/换字号不漂移（chapterId 另存于 lastUnitId）。
class NovelProgress {
  const NovelProgress({
    this.paragraphIndex = 0,
    this.fraction = 0,
    this.textOffset = 0,
    this.fontSize,
    this.layoutKey,
  });

  /// 与动画 playParamsJson 的区分标记
  static const String kind = 'novel-progress';

  /// 段落号（章内，0 起）
  final int paragraphIndex;

  /// 段内/章内进度比例（0–1，兜底恢复用）
  final double fraction;

  /// 段内 UTF-16 偏移（精确锚点）
  final int textOffset;

  /// 记录时字号（恢复时提示排版已变用，可空）
  final double? fontSize;

  /// 排版参数指纹（分页重排的缓存键，可空）
  final String? layoutKey;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'paragraphIndex': paragraphIndex,
        'fraction': fraction,
        'textOffset': textOffset,
        if (fontSize != null) 'fontSize': fontSize,
        if (layoutKey != null) 'layoutKey': layoutKey,
      };

  factory NovelProgress.fromJson(Map<String, dynamic> json) => NovelProgress(
        paragraphIndex: (json['paragraphIndex'] as num?)?.toInt() ?? 0,
        fraction: (json['fraction'] as num?)?.toDouble() ?? 0,
        textOffset: (json['textOffset'] as num?)?.toInt() ?? 0,
        fontSize: (json['fontSize'] as num?)?.toDouble(),
        layoutKey: json['layoutKey'] as String?,
      );
}

class NovelSource {
  const NovelSource({
    required this.key,
    required this.name,
    required this.version,
    required this.loadBookInfo,
    required this.loadBookText,
    required this.searchLoad,
    this.settingsDefaults = const {},
  });

  final String key;
  final String name;
  final String version;

  /// settings 默认值（load_setting 兜底，装载时一次性提取）
  final Map<String, dynamic> settingsDefaults;

  /// book.loadInfo(id) → {title, cover, author, intro, chapters: {chapterId: 章名}, ...}
  final Future<Map<String, dynamic>> Function(String bookId) loadBookInfo;

  /// book.loadText(bookId, chapterId) → 章节正文（纯文本，段落以 \n\n 分隔，
  /// 插图段为 <!--image-->URL<!--image--> 标记）
  final Future<String> Function(String bookId, String chapterId) loadBookText;

  /// search.load(keyword, [], 1) → novels 条目（matchSearch 用）
  final Future<List<NovelItem>> Function(String keyword) searchLoad;
}
