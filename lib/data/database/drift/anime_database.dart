import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'anime_database.g.dart';

/// 书库条目
class LibraryEntry extends Table {
  /// 自增行 id：兼容 UI 侧按 int id 删除的旧接口
  IntColumn get id => integer().autoIncrement()();

  /// 稳定身份，见类注释
  TextColumn get uid => text().unique()();

  /// 0 = 动画，1 = 漫画/小说（与 bangumi subjectType 的 isBook 对齐）
  IntColumn get type => integer()();

  IntColumn get bangumiId => integer().nullable()();

  TextColumn get title => text()();

  /// 海报远程 URL（不是本地缓存路径）
  TextColumn get posterUrl => text().withDefault(const Constant(''))();

  BoolColumn get favorite => boolean().withDefault(const Constant(true))();

  // ── 续看（动画）─────────────────────────────
  IntColumn get lastRoadIndex => integer().withDefault(const Constant(0))();

  /// 1-based 集号
  IntColumn get lastEpisode => integer().nullable()();

  /// 上一集的 HTML 页 URL（不是 m3u8）
  TextColumn get lastEpisodeUrl => text().nullable()();

  // ── 续读（漫画）─────────────────────────────
  TextColumn get sourceKey => text().nullable()();

  TextColumn get remoteId => text().nullable()();

  TextColumn get lastUnitId => text().nullable()();

  TextColumn get lastUnitTitle => text().nullable()();

  // ── 直接进入所需的上下文（只在选源/换集时写）──
  TextColumn get detailUrl => text().nullable()();

  TextColumn get ruleJson => text().nullable()();

  TextColumn get roadsJson => text().nullable()();

  TextColumn get playParamsJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(
  tables: [LibraryEntry],
)
class AnimeDatabase extends _$AnimeDatabase {
  /// driftDatabase 负责平台切换：
  /// - 原生：文档目录下的 Animes.sqlite
  /// - Web：WASM + web/sqlite3.wasm、web/drift_worker.js
  AnimeDatabase()
      : super(
          driftDatabase(
            name: 'Animes',
            web: DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            ),
          ),
        );

  AnimeDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1 只有 drift_favorite / drift_genre：新建 library_entry 并迁移收藏。
        await m.createTable(libraryEntry);
        try {
          await customStatement('''
            INSERT OR IGNORE INTO library_entry
              (uid, type, bangumi_id, title, poster_url, favorite,
               created_at, updated_at)
            SELECT 'anime:' || anime_id, 0, anime_id, title, poster_path,
                   favorite,
                   CAST(release_date AS INTEGER),
                   CAST(release_date AS INTEGER)
            FROM drift_favorite
          ''');
        } catch (_) {
          // 旧表不存在（异常升级路径）：当作空库，不阻塞启动
        }
        await customStatement('DROP TABLE IF EXISTS drift_favorite');
      }
      if (from < 3) {
        // 标签表没有消费方，直接丢弃（分类数据本来就来自远端，不落库）
        await customStatement('DROP TABLE IF EXISTS drift_genre');
      }
    },
  );
}
