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
}
