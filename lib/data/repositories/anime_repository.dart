import 'dart:convert';

import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/api/anilist_api_service.dart';
import 'package:movies/data/api/bangumi_api_service.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_character.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/anime_extras.dart';
import 'package:movies/data/models/anime_trailer.dart';
import 'package:movies/data/models/genre.dart';
import 'package:movies/data/parsing/search_result_parser.dart';
import 'package:movies/utils/prefs.dart';

/// 动漫数据仓库
/// 只负责「取数 + 缓存命中/回填」，返回模型；不持任何页面状态
class AnimeRepository {
  AnimeRepository({
    required this.bangumiApiService,
    required this.aniListApiService,
    required this.prefs,
    required this.database,
  });

  /// Bangumi API 服务
  final BangumiApiService bangumiApiService;

  /// AniList API 服务
  final AniListApiService aniListApiService;

  /// 本地存储（用于缓存 AniList 补充数据）
  final Future<Prefs> prefs;

  /// 数据库（标签表）
  final IDatabase database;

  /// 首页每栏数量
  static const int pageSize = 12;

  /// 动漫标签列表（分类页）
  List<Genre>? animeGenres;

  /// AniList 补充数据缓存（bangumiId → extras）
  final Map<int, AnimeExtras> extrasCache = {};

  /// 条目详情缓存（bangumiId → 原始响应）
  final Map<int, Map<String, dynamic>> _subjectCache = {};

  /// 详情对象缓存（bangumiId → AnimeDetails）
  final Map<int, AnimeDetails> _detailsCache = {};

  /// 预告 / PV 缓存
  final Map<int, List<AnimeTrailer>> _trailerCache = {};

  /// 角色 / 声优缓存
  final Map<int, List<AnimeCharacter>> _characterCache = {};

  /// 已加载动漫索引（bangumiId → 同一实例），供 findAnimeById 反查
  final Map<int, Anime> _animeIndex = {};

  /// 补充数据缓存是否已从本地加载
  bool _extrasLoaded = false;

  /// 初始化：标签 + 补充数据缓存
  Future<void> setup() async {
    await setupGenres();
    _loadExtrasCache(await prefs);
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
        return _registerAll(parseSearchResults(response.data));
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
        return _registerAll(
          parseSearchResults(response.data)
            ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0)),
        );
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
        return _registerAll(
          parseSearchResults(response.data)
            ..sort((a, b) => (a.rank ?? 9999).compareTo(b.rank ?? 9999)),
        );
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
        return _registerAll(
          items.map((e) => Anime.fromBangumi(e)).take(pageSize).toList(),
        );
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
    List<int> types = const [2],
  }) async {
    try {
      final response = await bangumiApiService.searchSubjects(
        keyword: query,
        limit: 10,
        tags: tags,
        offset: page * 10,
        types: types,
      );
      if (response.statusCode == 200) {
        return BangumiSearchResult(
          response.data['total'] as int,
          _registerAll(parseSearchResults(response.data)),
        );
      }
      logError('Failed to search anime: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error searching anime: $e');
      return null;
    }
  }

  /// 根据动漫 ID 查找已加载过的动漫（同一实例，含 ensureExtras 的回填）
  Anime? findAnimeById(int animeId) => _animeIndex[animeId];

  /// 索引所有动漫，供 findAnimeById 反查
  List<Anime> _registerAll(List<Anime> animes) {
    for (final anime in animes) {
      _animeIndex[anime.bangumiId] = anime;
    }
    return animes;
  }

  /// 确保动漫的补充数据已加载
  /// 横幅/PV 按需请求 AniList 并持久化缓存（失败时横幅为空，UI 回退封面图）
  /// 简介在放送日历数据为空时从条目详情补充
  Future<void> ensureExtras(Anime anime) async {
    if (anime.bannerImage == null) {
      final extras = await getExtras(
        anime.bangumiId,
        anime.titleJapanese,
        anime.title,
      );
      anime.bannerImage = extras.bannerImage;
    }
    if (anime.synopsis == null || anime.synopsis!.isEmpty) {
      final details = await getAnimeDetails(anime.bangumiId);
      final synopsis = details?.synopsis;
      if (synopsis != null && synopsis.isNotEmpty) {
        anime.synopsis = synopsis;
      }
    }
  }

  /// 获取动漫详情
  Future<AnimeDetails?> getAnimeDetails(int animeId) async {
    final cached = _detailsCache[animeId];
    if (cached != null) {
      return cached;
    }
    try {
      final subject = await _getSubject(animeId);
      if (subject == null) {
        return null;
      }
      final details = AnimeDetails.fromBangumi(subject);
      _detailsCache[animeId] = details;
      return details;
    } catch (e) {
      logError('Error loading anime details: $e');
      return null;
    }
  }

  /// 获取动漫预告片 / PV 列表（来自 AniList，可能为空）
  Future<List<AnimeTrailer>> getAnimeTrailers(int animeId) async {
    final cached = _trailerCache[animeId];
    if (cached != null) {
      return cached;
    }
    String? nameJa;
    String? nameCn;
    final anime = findAnimeById(animeId);
    if (anime != null) {
      nameJa = anime.titleJapanese;
      nameCn = anime.title;
    } else {
      final details = await getAnimeDetails(animeId);
      nameJa = details?.titleJapanese;
      nameCn = details?.title;
    }
    final extras = await getExtras(animeId, nameJa, nameCn);
    final videoId = extras.youtubeId;
    if (videoId == null || videoId.isEmpty) {
      _trailerCache[animeId] = const [];
      return const [];
    }
    final trailers = [
      AnimeTrailer(
        title: 'PV',
        youtubeId: videoId,
        site: extras.trailerSite,
        imageUrl: extras.trailerThumbnail,
      ),
    ];
    _trailerCache[animeId] = trailers;
    return trailers;
  }

  /// 获取动漫角色和声优列表
  Future<List<AnimeCharacter>> getAnimeCharacters(int animeId) async {
    final cached = _characterCache[animeId];
    if (cached != null) {
      return cached;
    }
    try {
      final response = await bangumiApiService.getSubjectCharacters(animeId);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! List<dynamic>) {
          _characterCache[animeId] = const [];
          return const [];
        }
        final characters = data
            .whereType<Map<String, dynamic>>()
            .map(AnimeCharacter.fromBangumi)
            .toList();
        _characterCache[animeId] = characters;
        return characters;
      }
      logError('Failed to load anime characters: ${response.statusCode}');
      return [];
    } catch (e) {
      logError('Error loading anime characters: $e');
      return [];
    }
  }

  /// 获取条目详情（带缓存，供详情页与 PV 共用）
  Future<Map<String, dynamic>?> _getSubject(int animeId) async {
    final cached = _subjectCache[animeId];
    if (cached != null) {
      return cached;
    }
    try {
      final response = await bangumiApiService.getSubject(animeId);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final subject = response.data as Map<String, dynamic>;
        _subjectCache[animeId] = subject;
        return subject;
      }
      logError('Failed to load anime subject: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Error loading anime subject: $e');
      return null;
    }
  }

  /// 获取 AniList 补充数据（横幅/PV），带内存与本地缓存
  /// Bangumi 与 AniList 无共享 ID，按日文原名（回退中文名）搜索匹配
  Future<AnimeExtras> getExtras(
    int bangumiId,
    String? nameJa,
    String? nameCn,
  ) async {
    final p = await prefs;
    _loadExtrasCache(p);
    final cached = extrasCache[bangumiId];
    if (cached != null) {
      return cached;
    }
    var extras = const AnimeExtras();
    for (final keyword in [nameJa, nameCn]) {
      if (keyword == null || keyword.isEmpty) {
        continue;
      }
      final result = await _searchAniList(keyword);
      if (result != null) {
        extras = result;
        break;
      }
    }
    extrasCache[bangumiId] = extras;
    _saveExtrasCache(p);
    return extras;
  }

  /// 搜索 AniList 获取横幅与 PV
  Future<AnimeExtras?> _searchAniList(String keyword) async {
    try {
      final response = await aniListApiService.searchMedia(keyword);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final media = (data['data'] as Map<String, dynamic>?)?['Media'];
      if (media is! Map<String, dynamic>) {
        return null;
      }
      final trailer = media['trailer'] as Map<String, dynamic>?;
      final site = trailer?['site'] as String?;
      final videoId = trailer?['id'] as String?;
      return AnimeExtras(
        bannerImage: media['bannerImage'] as String?,
        youtubeId: (videoId == null || videoId.isEmpty) ? null : videoId,
        trailerSite: site,
        trailerThumbnail: trailer?['thumbnail'] as String?,
      );
    } catch (e) {
      logError('Error searching AniList: $e');
      return null;
    }
  }

  /// 从本地存储加载补充数据缓存
  void _loadExtrasCache(Prefs prefs) {
    if (_extrasLoaded) {
      return;
    }
    _extrasLoaded = true;
    final raw = prefs.getString(_extrasKey);
    if (raw == null) {
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((key, value) {
        final id = int.tryParse(key);
        if (id == null || value is! Map<String, dynamic>) {
          return;
        }
        extrasCache[id] = AnimeExtras.fromJson(value);
      });
    } catch (e) {
      logError('Error loading extras cache: $e');
    }
  }

  /// 保存补充数据缓存到本地存储
  void _saveExtrasCache(Prefs prefs) {
    final raw = jsonEncode({
      for (final entry in extrasCache.entries)
        entry.key.toString(): entry.value.toJson(),
    });
    prefs.setString(_extrasKey, raw);
  }
}

/// 补充数据缓存的本地存储键
const String _extrasKey = 'AniListExtrasCache';

/// 搜索条目结果
class BangumiSearchResult {
  final int total;
  final List<Anime> animeList;

  BangumiSearchResult(this.total, this.animeList);
}
