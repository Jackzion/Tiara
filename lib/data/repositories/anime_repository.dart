import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/api/anilist_api_service.dart';
import 'package:movies/data/api/bangumi_api_service.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/genre.dart';
import 'package:movies/data/parsing/search_result_parser.dart';
import 'package:movies/data/repositories/anime_cache_repository.dart';
import 'package:movies/state/genre_controller.dart';

/// 动漫数据仓库
/// 只负责「取数 + 解析」；缓存统一在 AnimeCacheRepository（DB）
class AnimeRepository {
  AnimeRepository({
    required this.bangumiApiService,
    required this.aniListApiService,
    required this.cache,
  });

  /// Bangumi API 服务
  final BangumiApiService bangumiApiService;

  /// AniList API 服务
  final AniListApiService aniListApiService;

  /// 详情快照缓存（SWR 的本地一侧）
  final AnimeCacheRepository cache;

  /// 首页每栏数量
  static const int pageSize = 12;

  /// 动漫标签列表（分类页）
  List<Genre>? animeGenres;

  /// 初始化：标签
  Future<void> setup() async {
    await setupGenres();
  }

  /// 加载题材标签
  static const List<String> sourceTagNames = ['游戏改','原创','小说改','动画改','漫画改','影视改'];
  static const List<String> genreTagNames = [
    '科幻',
    '奇幻',
    '恋爱',
    '百合',
    '治愈',
    '悬疑',
    '推理',
    '机战',
    '校园',
    '音乐',
    '日常',
    '搞笑',
    '动作',
    '冒险',
    '魔法',
    '青春',
    '剧情',
    '恐怖',
    '历史',
    '运动',
    '美食',
    '萌',
    '后宫',
  ];
  static const List<String> regionTagNames = ['中国', '日本', '美国', '韩国', '台湾'];
  static const List<String> audienceTagNames = [
    '少年',
    '少女',
    '青年',
    'BL',
    '一般向',
    'GL',
    '名著',
    '儿童',
    '女性',
    'TL',
    '无cp',
  ];
  static const List<String> progressTagNames = ['已完结', '连载中', '停载'];
  Future<void> setupGenres() async {
    final tagNames = [
      ...genreTagNames,
      ...regionTagNames,
      ...audienceTagNames,
      ...progressTagNames,
      ...sourceTagNames,
    ];
    animeGenres = [
      for (var i = 0; i < tagNames.length; i++)
        Genre(malId: i + 1, name: tagNames[i]),
    ];
  }

  /// 获取热门动漫列表（全站热度）
  Future<List<Anime>?> getTrendingAnimes(int page) async {
    try {
      final response = await bangumiApiService.searchSubjects(
        sort: 'heat',
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );
      if (response.statusCode == 200) {
        return parseSearchResults(response.data);
      }
      logError('Failed to load trending anime: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error loading trending anime: $e');
      return null;
    }
  }

  /// 获取高评分动漫列表（评分 >= 8.0，按评分排序）
  Future<List<Anime>?> getPopular(int page) async {
    try {
      final response = await bangumiApiService.searchSubjects(
        ratingFilter: ['>= 8.0'],
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );
      if (response.statusCode == 200) {
        return parseSearchResults(response.data)
          ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
      }
      logError('Failed to load popular anime: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error loading popular anime: $e');
      return null;
    }
  }

  /// 获取排行榜动漫列表（排名 <= 300，按排名排序）
  Future<List<Anime>?> getTopRated(int page) async {
    try {
      final response = await bangumiApiService.searchSubjects(
        rankFilter: ['>= 1', '<= 300'],
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );
      if (response.statusCode == 200) {
        return parseSearchResults(response.data)
          ..sort((a, b) => (a.rank ?? 9999).compareTo(b.rank ?? 9999));
      }
      logError('Failed to load top rated anime: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error loading top rated anime: $e');
      return null;
    }
  }

  /// 获取本季放送动漫列表（放送日历，按在看人数排序）
  Future<List<Anime>?> getNowPlaying(int page) async {
    try {
      final response = await bangumiApiService.getCalendar();
      if (response.statusCode == 200) {
        final items = <Map<String, dynamic>>[];
        final days = response.data as List<dynamic>;
        for (final day in days) {
          final dayItems = (day as Map<String, dynamic>)['items'];
          if (dayItems is List<dynamic>) {
            items.addAll(dayItems.cast<Map<String, dynamic>>());
          }
        }
        items.sort((a, b) {
          final doingA = collectionDoing(a);
          final doingB = collectionDoing(b);
          return doingB.compareTo(doingA);
        });
        return items
            .map((e) => Anime.fromBangumi(e))
            .take(pageSize)
            .toList();
      }
      logError('Failed to load now playing anime: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error loading now playing anime: $e');
      return null;
    }
  }

  /// 搜索动漫
  Future<BangumiSearchResult?> searchAnimes(
    String query,
    int page,
    List<String>? tags, {
    SubjectTypeFilter typeFilter = SubjectTypeFilter.all,
  }) async {
    try {
      final response = await bangumiApiService.searchSubjects(
        keyword: query,
        limit: 10,
        tags: tags,
        offset: page * 10,
        typeFilter: typeFilter,
      );
      if (response.statusCode == 200) {
        return BangumiSearchResult(
          response.data['total'] as int,
          parseSearchResults(response.data),
        );
      }
      logError('Failed to search anime: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error searching anime: $e');
      return null;
    }
  }


  /// 确保动漫的补充数据已加载（横幅 / 简介）
  /// 走 AnimeCacheRepository：命中 subject_cache 时零网络
  Future<void> ensureExtras(Anime anime) => cache.ensureExtras(anime);

  /// 获取动漫详情
  Future<AnimeDetails?> getAnimeDetails(int animeId) async {
    try {
      final subject = await _getSubject(animeId);
      if (subject == null) {
        return null;
      }
      final details = AnimeDetails.fromBangumi(subject);
      return details;
    } catch (e) {
      logError('Error loading anime details: $e');
      return null;
    }
  }

  /// 获取条目详情（带缓存，供详情页与 PV 共用）
  Future<Map<String, dynamic>?> _getSubject(int animeId) async {
    try {
      final response = await bangumiApiService.getSubject(animeId);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final subject = response.data as Map<String, dynamic>;
        return subject;
      }
      logError('Failed to load anime subject: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error loading anime subject: $e');
      return null;
    }
  }

}

/// 搜索条目结果
class BangumiSearchResult {
  final int total;
  final List<Anime> animeList;

  BangumiSearchResult(this.total, this.animeList);
}
