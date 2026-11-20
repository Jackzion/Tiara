import 'package:movies/data/database/models/cached_subject.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/data/database/models/library_models.dart';

/// 数据库抽象接口
/// UI/ViewModel 只依赖本接口，便于替换 Drift 或其他实现
abstract class IDatabase {
  Future deleteDatabase();

  Future saveFavorite(DBFavorite favorite);

  Future<bool> removeFavorite(int id);

  Future<List<DBFavorite>> getFavorites();

  Stream<List<DBFavorite>> streamFavorites();

  /// 记录续看/续读指针（按 uid 幂等 upsert）
  Future savePlay(LibraryPlayUpdate update);

  /// 最近播放/阅读，按 updatedAt 倒序
  Future<List<LibraryResume>> recentPlays({int limit = 20});

  /// 按 bangumiId 查续看（uid = anime:<id>）
  Future<LibraryResume?> findAnime(int bangumiId);

  /// 按图源 + 漫画 id 查续读（uid = comic:<sourceKey>:<comicId>）
  Future<LibraryResume?> findComic({
    required String sourceKey,
    required String comicId,
  });

  /// 按书源 + 小说 id 查续读（uid = `novel:<sourceKey>:<bookId>`）
  Future<LibraryResume?> findNovel({
    required String sourceKey,
    required String bookId,
  });

  // ── 详情快照缓存（纯缓存，可整表清理）───────────────

  Future<CachedSubject?> readSubjectCache(int bangumiId);

  Future<void> writeSubjectCache(
    int bangumiId,
    String payload,
    DateTime fetchedAt,
  );

  /// 删除 [from, to) 时间窗内、且不属于 library 的缓存行（每日滚动清理）
  Future<void> evictSubjectCacheWindow({
    required DateTime from,
    required DateTime to,
  });

  /// 超出容量时，按最旧优先淘汰非 library 条目，最多删 [batch] 条
  Future<void> trimSubjectCache({required int keep, int batch = 200});

  Future<int> countSubjectCache();
}
