/// 写入「续看/续读」所需字段。
///
/// 只包含离线拿不到、又不想再回源的信息；评分/简介/banner 由 bangumi 现取。
class LibraryPlayUpdate {
  const LibraryPlayUpdate({
    required this.uid,
    required this.type,
    required this.title,
    this.bangumiId,
    this.posterUrl,
    this.sourceKey,
    this.remoteId,
    this.detailUrl,
    this.ruleJson,
    this.roadsJson,
    this.playParamsJson,
    this.lastRoadIndex = 0,
    this.lastEpisode,
    this.lastEpisodeUrl,
    this.lastUnitId,
    this.lastUnitTitle,
  });

  /// 记录键 = bangumiId 的纯数字串（动画/漫画/小说共用一条）
  final String uid;

  /// 条目类型：直接存 details.type（'TV'/'剧场版'/'漫画'/'小说'…）
  final String? type;

  final String title;
  final int? bangumiId;
  final String? posterUrl;

  final String? sourceKey;
  final String? remoteId;
  final String? detailUrl;
  final String? ruleJson;
  final String? roadsJson;
  final String? playParamsJson;

  final int lastRoadIndex;
  final int? lastEpisode;
  final String? lastEpisodeUrl;
  final String? lastUnitId;
  final String? lastUnitTitle;
}

/// 「继续观看」列表的一行：足够直接进入 video_page / comic_reader。
class LibraryResume {
  const LibraryResume({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.updatedAt,
    this.bangumiId,
    this.posterUrl,
    this.sourceKey,
    this.remoteId,
    this.detailUrl,
    this.ruleJson,
    this.roadsJson,
    this.playParamsJson,
    this.lastRoadIndex = 0,
    this.lastEpisode,
    this.lastEpisodeUrl,
    this.lastUnitId,
    this.lastUnitTitle,
  });

  final int id;
  final String uid;

  /// 条目类型：直接存 details.type（'TV'/'剧场版'/'漫画'/'小说'…）
  final String? type;
  final String title;
  final DateTime updatedAt;

  final int? bangumiId;
  final String? posterUrl;

  final String? sourceKey;
  final String? remoteId;
  final String? detailUrl;
  final String? ruleJson;
  final String? roadsJson;
  final String? playParamsJson;

  final int lastRoadIndex;
  final int? lastEpisode;
  final String? lastEpisodeUrl;
  final String? lastUnitId;
  final String? lastUnitTitle;

  bool get isComic => type == '漫画';
  bool get isNovel => type == '小说';

  /// 上次位置标签：漫画/小说显示单元名（话名/章名），动画显示集数
  String get progressLabel {
    if (isComic || isNovel) {
      return lastUnitTitle?.isNotEmpty == true ? lastUnitTitle! : '继续阅读';
    }
    return lastEpisode != null ? '第 $lastEpisode 集' : '继续观看';
  }
}
