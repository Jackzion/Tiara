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

  /// anime:<bangumiId> / comic:<sourceKey>:<comicId>
  final String uid;

  /// 0 = 动画，1 = 漫画/小说
  final int type;

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
  final int type;
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

  bool get isComic => type == 1;

  /// 「第 3 集」「第 12 话」
  String get progressLabel => isComic
      ? (lastUnitTitle?.isNotEmpty == true ? lastUnitTitle! : '继续阅读')
      : (lastEpisode != null ? '第 $lastEpisode 集' : '继续观看');
}
