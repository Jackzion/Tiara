import 'package:drift/drift.dart';
import 'package:movies/data/database/drift/anime_database.dart';
import 'package:movies/data/database/models/cached_subject.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/data/database/models/library_models.dart';

/// Drift 数据库实现
class DriftDatabase implements IDatabase {
  final AnimeDatabase animeDatabase;

  DriftDatabase() : animeDatabase = AnimeDatabase();

  DriftDatabase.test(this.animeDatabase);

  @override
  Future deleteDatabase() async {
    // TODO: 目前只关连接；真正删库需要拿到 driftDatabase 的文件路径（drift_flutter
    // 未暴露），等接入「清除数据」时再补。
    await animeDatabase.close();
  }

  @override
  Future<List<DBFavorite>> getFavorites() async {
    final rows = await (animeDatabase.select(
      animeDatabase.libraryEntry,
    )..where((t) => t.favorite.equals(true))..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
      ]))
        .get();
    return rows.map(_toFavorite).toList();
  }

  @override
  Stream<List<DBFavorite>> streamFavorites() {
    return (animeDatabase.select(animeDatabase.libraryEntry)
          ..where((t) => t.favorite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_toFavorite).toList());
  }

  @override
  Future<bool> removeFavorite(int id) async {
    final count = await (animeDatabase.delete(
      animeDatabase.libraryEntry,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// 收藏：按 uid 幂等 upsert（同一部番重复收藏不会产生第二行）
  @override
  Future saveFavorite(DBFavorite favorite) async {
    final now = DateTime.now();
    await animeDatabase.into(animeDatabase.libraryEntry).insert(
      LibraryEntryCompanion.insert(
        uid: _animeUid(favorite.animeId),
        bangumiId: Value(favorite.animeId),
        title: favorite.title,
        posterUrl: Value(favorite.posterPath),
        favorite: Value(favorite.favorite),
        createdAt: now,
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => LibraryEntryCompanion(
          bangumiId: Value(favorite.animeId),
          title: Value(favorite.title),
          posterUrl: Value(favorite.posterPath),
          favorite: Value(favorite.favorite),
          updatedAt: Value(now),
        ),
        target: [animeDatabase.libraryEntry.uid],
      ),
    );
  }

  /// 记录「续看/续读」：只更新播放定位与上下文，不动 favorite/createdAt
  @override
  Future savePlay(LibraryPlayUpdate update) async {
    final now = DateTime.now();
    await animeDatabase.into(animeDatabase.libraryEntry).insert(
      LibraryEntryCompanion.insert(
        uid: update.uid,
        type: Value(update.type),
        bangumiId: Value(update.bangumiId),
        title: update.title,
        posterUrl: Value(update.posterUrl ?? ''),
        favorite: const Value(false),
        createdAt: now,
        updatedAt: now,
        sourceKey: Value(update.sourceKey),
        remoteId: Value(update.remoteId),
        detailUrl: Value(update.detailUrl),
        ruleJson: Value(update.ruleJson),
        roadsJson: Value(update.roadsJson),
        playParamsJson: Value(update.playParamsJson),
        lastRoadIndex: Value(update.lastRoadIndex),
        lastEpisode: Value(update.lastEpisode),
        lastEpisodeUrl: Value(update.lastEpisodeUrl),
        lastUnitId: Value(update.lastUnitId),
        lastUnitTitle: Value(update.lastUnitTitle),
      ),
      onConflict: DoUpdate(
        (old) => LibraryEntryCompanion(
          // bangumiId 仅在提供时回填（历史记录可随下次保存治愈），
          // 不提供则保留原值 —— 漫画/小说的老记录就是靠这条回填的
          bangumiId: update.bangumiId != null
              ? Value(update.bangumiId!)
              : const Value.absent(),
          title: Value(update.title),
          posterUrl: update.posterUrl != null
              ? Value(update.posterUrl!)
              : const Value.absent(),
          sourceKey: Value(update.sourceKey),
          remoteId: Value(update.remoteId),
          detailUrl: Value(update.detailUrl),
          ruleJson: Value(update.ruleJson),
          roadsJson: Value(update.roadsJson),
          playParamsJson: Value(update.playParamsJson),
          lastRoadIndex: Value(update.lastRoadIndex),
          lastEpisode: Value(update.lastEpisode),
          lastEpisodeUrl: Value(update.lastEpisodeUrl),
          lastUnitId: Value(update.lastUnitId),
          lastUnitTitle: Value(update.lastUnitTitle),
          updatedAt: Value(now),
        ),
        target: [animeDatabase.libraryEntry.uid],
      ),
    );
  }

  /// 最近播放/阅读（有进度指针的条目），用于「继续观看」
  @override
  Future<List<LibraryResume>> recentPlays({int limit = 20}) async {
    final rows = await (animeDatabase.select(animeDatabase.libraryEntry)
          ..where(
            (t) => t.lastEpisode.isNotNull() | t.lastUnitId.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
    return rows.map(_toResume).toList();
  }

  @override
  Future<LibraryResume?> findAnime(int bangumiId) => _findByUid('$bangumiId');

  @override
  Future<LibraryResume?> findComic({
    required String sourceKey,
    required String comicId,
  }) =>
      _findBySource(sourceKey, comicId);

  @override
  Future<LibraryResume?> findNovel({
    required String sourceKey,
    required String bookId,
  }) =>
      _findBySource(sourceKey, bookId);

  /// 旧复合 uid 的兜底查找（uid 已收敛为 bangumiId 后按源列查）
  Future<LibraryResume?> _findBySource(String sourceKey, String remoteId) async {
    final row = await (animeDatabase.select(animeDatabase.libraryEntry)
          ..where((t) => t.sourceKey.equals(sourceKey) & t.remoteId.equals(remoteId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toResume(row);
  }

  Future<LibraryResume?> _findByUid(String uid) async {
    final row = await (animeDatabase.select(animeDatabase.libraryEntry)
          ..where((t) => t.uid.equals(uid))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toResume(row);
  }

  @override
  Future<CachedSubject?> readSubjectCache(int bangumiId) async {
    final row = await (animeDatabase.select(animeDatabase.subjectCache)
          ..where((t) => t.bangumiId.equals(bangumiId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return CachedSubject(
      bangumiId: row.bangumiId,
      payload: row.payloadJson,
      fetchedAt: row.fetchedAt,
    );
  }

  @override
  Future<void> writeSubjectCache(
    int bangumiId,
    String payload,
    DateTime fetchedAt,
  ) async {
    await animeDatabase
        .into(animeDatabase.subjectCache)
        .insertOnConflictUpdate(
          SubjectCacheCompanion.insert(
            bangumiId: Value(bangumiId),
            payloadJson: payload,
            fetchedAt: fetchedAt,
          ),
        );
  }

  @override
  Future<void> evictSubjectCacheWindow({
    required DateTime from,
    required DateTime to,
  }) async {
    // drift 的 dateTime 列按 unix 秒存储
    final fromSec = from.millisecondsSinceEpoch ~/ 1000;
    final toSec = to.millisecondsSinceEpoch ~/ 1000;
    await animeDatabase.customStatement(
      '''
      DELETE FROM subject_cache
      WHERE fetched_at >= ? AND fetched_at < ?
        AND bangumi_id NOT IN (
          SELECT bangumi_id FROM library_entry WHERE bangumi_id IS NOT NULL
        )
      ''',
      [fromSec, toSec],
    );
  }

  @override
  Future<void> trimSubjectCache({required int keep, int batch = 200}) async {
    final count = await countSubjectCache();
    if (count <= keep) return;
    final excess = (count - keep).clamp(1, batch);
    await animeDatabase.customStatement(
      '''
      DELETE FROM subject_cache WHERE bangumi_id IN (
        SELECT bangumi_id FROM subject_cache
        WHERE bangumi_id NOT IN (
          SELECT bangumi_id FROM library_entry WHERE bangumi_id IS NOT NULL
        )
        ORDER BY fetched_at ASC
        LIMIT ?
      )
      ''',
      [excess],
    );
  }

  @override
  Future<int> countSubjectCache() async {
    final row = await animeDatabase
        .customSelect('SELECT COUNT(*) AS c FROM subject_cache')
        .getSingle();
    return row.read<int>('c');
  }

  static String _animeUid(int bangumiId) => '$bangumiId';

  /// 旧 UI 模型映射：评分/简介/banner 不再持久化，回源获取
  DBFavorite _toFavorite(LibraryEntryData row) => DBFavorite(
    id: row.id,
    animeId: row.bangumiId ?? 0,
    posterPath: row.posterUrl,
    bannerPath: null,
    favorite: row.favorite,
    popularity: 0,
    releaseDate: row.updatedAt,
    title: row.title,
    overview: '',
  );

  LibraryResume _toResume(LibraryEntryData row) => LibraryResume(
    id: row.id,
    uid: row.uid,
    type: row.type,
    bangumiId: row.bangumiId,
    title: row.title,
    posterUrl: row.posterUrl,
    updatedAt: row.updatedAt,
    sourceKey: row.sourceKey,
    remoteId: row.remoteId,
    detailUrl: row.detailUrl,
    ruleJson: row.ruleJson,
    roadsJson: row.roadsJson,
    playParamsJson: row.playParamsJson,
    lastRoadIndex: row.lastRoadIndex,
    lastEpisode: row.lastEpisode,
    lastEpisodeUrl: row.lastEpisodeUrl,
    lastUnitId: row.lastUnitId,
    lastUnitTitle: row.lastUnitTitle,
  );
}
