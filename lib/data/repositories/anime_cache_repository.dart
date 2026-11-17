import 'dart:async';

import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/api/anilist_api_service.dart';
import 'package:movies/data/api/bangumi_api_service.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_extras.dart';
import 'package:movies/data/models/detail_snapshot.dart';
import 'package:movies/utils/prefs.dart';

/// 详情快照缓存仓库（SWR 的「本地」一侧）。
///
/// - 读：直接查 `subject_cache`，命中即返回，**不等网络**
/// - 写：刷新成功后整份覆盖
/// - 去重：同一 bangumiId 的并发请求复用同一个 Future（`_inflight`，不是缓存）
/// - 清理：每天一次滚动窗口（7 天）+ 容量上限；永不动 library 里的条目
class AnimeCacheRepository {
  AnimeCacheRepository({
    required this.database,
    required this.bangumiApiService,
    required this.aniListApiService,
    required this.prefs,
  });

  final IDatabase database;
  final BangumiApiService bangumiApiService;
  final AniListApiService aniListApiService;
  final Future<Prefs> prefs;

  /// 超过这个时间才后台刷新（数据仍然照常返回，不会被清）
  static const ttl = Duration(days: 7);

  /// 容量软上限：超过就按最旧优先淘汰非 library 条目
  static const softLimit = 600;

  static const _cleanupKey = 'subjectCacheCleanedOn';

  final Map<int, Future<DetailSnapshot>> _inflight = {};

  bool isStale(DateTime fetchedAt, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(fetchedAt) > ttl;

  /// 纯本地读：命中且 payload 可解析才返回
  Future<DetailSnapshot?> read(int bangumiId) async {
    final row = await database.readSubjectCache(bangumiId);
    if (row == null) return null;
    return DetailSnapshot.fromCached(row);
  }

  /// 本地优先；未命中才等网络。并发调用复用同一请求。
  Future<DetailSnapshot> load(int bangumiId) =>
      _inflight[bangumiId] ??= _load(bangumiId).whenComplete(
        () => _inflight.remove(bangumiId),
      );

  /// 强制刷新（手动重试 / TTL 过期后的后台刷新）
  Future<DetailSnapshot> refresh(int bangumiId) =>
      _inflight[bangumiId] ??= _fetchAndStore(bangumiId).whenComplete(
        () => _inflight.remove(bangumiId),
      );

  Future<DetailSnapshot> _load(int bangumiId) async {
    final cached = await read(bangumiId);
    if (cached != null) return cached;
    return _fetchAndStore(bangumiId);
  }

  Future<DetailSnapshot> _fetchAndStore(
    int bangumiId, {
    bool withCharacters = true,
  }) async {
    final snapshot = await _fetch(bangumiId, withCharacters: withCharacters);
    try {
      await database.writeSubjectCache(
        bangumiId,
        snapshot.toPayload(),
        snapshot.fetchedAt,
      );
    } catch (e) {
      // 缓存写失败不影响本次返回
      logError('write subject cache failed: $e');
    }
    return snapshot;
  }

  Future<DetailSnapshot> _fetch(
    int bangumiId, {
    bool withCharacters = true,
  }) async {
    final subjectResponse = await bangumiApiService.getSubject(bangumiId);
    final rawSubject = subjectResponse.data;
    if (rawSubject is! Map<String, dynamic>) {
      throw Exception('加载动漫详情失败（animeId: $bangumiId）');
    }

    // 列表卡片只需要横幅/简介：跳过角色请求，避免首页一次开 12 个请求
    List<dynamic>? rawCharacters;
    if (withCharacters) {
      final charactersResponse = await bangumiApiService.getSubjectCharacters(
        bangumiId,
      );
      rawCharacters = charactersResponse.data is List
          ? charactersResponse.data as List
          : const [];
    }

    final nameJa = rawSubject['name'] as String?;
    final nameCnRaw = rawSubject['name_cn'] as String?;
    final extras = await _searchExtras([
      nameJa,
      (nameCnRaw == null || nameCnRaw.isEmpty) ? null : nameCnRaw,
    ]);

    return DetailSnapshot(
      bangumiId: bangumiId,
      subject: rawSubject,
      extras: extras,
      characters: rawCharacters,
      fetchedAt: DateTime.now(),
    );
  }

  /// Bangumi 与 AniList 无共享 ID：按日文原名（回退中文名）搜索匹配
  Future<AnimeExtras> _searchExtras(List<String?> keywords) async {
    for (final keyword in keywords) {
      if (keyword == null || keyword.isEmpty) continue;
      try {
        final response = await aniListApiService.searchMedia(keyword);
        final data = response.data;
        if (data is! Map<String, dynamic>) continue;
        final media = (data['data'] as Map<String, dynamic>?)?['Media'];
        if (media is! Map<String, dynamic>) continue;
        final trailer = media['trailer'] as Map<String, dynamic>?;
        final videoId = trailer?['id'] as String?;
        return AnimeExtras(
          bannerImage: media['bannerImage'] as String?,
          youtubeId: (videoId == null || videoId.isEmpty) ? null : videoId,
          trailerSite: trailer?['site'] as String?,
          trailerThumbnail: trailer?['thumbnail'] as String?,
        );
      } catch (e) {
        logError('AniList search failed ($keyword): $e');
      }
    }
    return const AnimeExtras();
  }

  /// 列表卡片用：横幅 / 简介补全（命中缓存时零网络）
  ///
  /// 未命中时只取「条目 + AniList 补充」，**不拉角色列表**；这样详情页会因为
  /// `hasCharacters == false` 补一次后台刷新，而首页不会为 12 张卡打 36 个请求。
  Future<void> ensureExtras(Anime anime) async {
    var snapshot = await read(anime.bangumiId);
    snapshot ??= await _fetchAndStore(
      anime.bangumiId,
      withCharacters: false,
    );

    final banner = snapshot.extras.bannerImage;
    if (banner != null && banner.isNotEmpty) {
      anime.bannerImage = banner;
    }
    final synopsis = snapshot.details?.synopsis;
    if (synopsis != null &&
        synopsis.isNotEmpty &&
        (anime.synopsis == null || anime.synopsis!.isEmpty)) {
      anime.synopsis = synopsis;
    }
  }

  /// 每天最多跑一次：
  /// 1) 删掉「刚满 7 天」那一天的窗口（滚动窗口，不是一周全清）
  /// 2) 超过容量上限再按最旧优先补删
  Future<void> cleanupIfNeeded() async {
    final p = await prefs;
    final now = DateTime.now();
    final last = DateTime.tryParse(p.getString(_cleanupKey) ?? '');
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return;
    }
    try {
      await database.evictSubjectCacheWindow(
        from: now.subtract(const Duration(days: 8)),
        to: now.subtract(const Duration(days: 7)),
      );
      await database.trimSubjectCache(keep: softLimit);
    } catch (e) {
      logError('subject cache cleanup failed: $e');
    }
    await p.setString(_cleanupKey, now.toIso8601String());
  }
}
