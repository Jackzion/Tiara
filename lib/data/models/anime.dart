import 'package:movies/data/parsing/anime_json.dart';

/// 动漫数据模型
/// 数据来源：Bangumi 条目（搜索/日历），横幅与 PV 由 AniList 按需补充
class Anime {
  /// Bangumi 条目 ID
  final int bangumiId;

  /// 标题（优先中文名，回退日文原名）
  final String? title;

  /// 日文原名（用于 AniList 匹配）
  final String? titleJapanese;

  /// 封面图地址
  final String image;

  /// 简介（放送日历数据为空时按需从条目详情补全）
  String? synopsis;

  /// 首播日期
  final DateTime? aired;

  /// 评分（0-10）
  final double? score;

  /// 排行（越小越高）
  final int? rank;

  /// 集数
  final int? episodes;

  /// 放送形式（TV/剧场版/OVA 等）
  final String? type;

  /// 宽幅横幅图（AniList 按需加载，可能为空）
  String? bannerImage;

  /// 条目类型（Bangumi subject type：1=书籍 2=动画 3=游戏 4=音乐 6=三次元）
  final int? subjectType;

  /// 卷数（书籍才有；动画为空）
  final int? vols;

  Anime({
    required this.bangumiId,
    this.title,
    this.titleJapanese,
    this.image = '',
    this.synopsis,
    this.aired,
    this.score,
    this.rank,
    this.episodes,
    this.type,
    this.bannerImage,
    this.subjectType,
    this.vols,
  });

  /// 从 Bangumi 条目（搜索结果/日历项）构造
  factory Anime.fromBangumi(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final rating = json['rating'] as Map<String, dynamic>?;
    final nameCn = json['name_cn'] as String?;
    final name = json['name'] as String?;
    return Anime(
      bangumiId: json['id'] as int? ?? 0,
      title: (nameCn != null && nameCn.isNotEmpty) ? nameCn : name,
      titleJapanese: name,
      image: images?['large'] as String? ?? images?['medium'] as String? ?? '',
      synopsis: json['summary'] as String?,
      aired: parseDate(json['date'] as String? ?? json['air_date'] as String?),
      score: parseDouble(rating?['score']),
      rank: parseInt(json['rank'] ?? rating?['rank']),
      episodes: parseInt(json['eps'] ?? json['total_episodes']),
      type: json['platform'] as String?,
      subjectType: parseInt(json['type']),
      vols: parseInt(json['vols']),
    );
  }

  /// 动漫 ID（即 Bangumi 条目 ID）
  int get animeId => bangumiId;

  /// 封面图地址
  String get imageUrl => image;
}
