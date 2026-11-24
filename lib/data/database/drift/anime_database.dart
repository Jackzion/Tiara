import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'anime_database.g.dart';

/// 书库条目
class LibraryEntry extends Table {
  /// 自增行 id：兼容 UI 侧按 int id 删除的旧接口
  IntColumn get id => integer().autoIncrement()();

  /// 记录键 = bangumiId 的纯数字串（同一 bangumi 条目只保留最近一次
  /// 观看/阅读位置，动画/漫画/小说共用一条记录）
  TextColumn get uid => text().unique()();

  /// 条目类型：直接存 details.type（'TV'/'剧场版'/'漫画'/'小说'…）
  TextColumn get type => text().nullable()();

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

/// 详情快照缓存（**纯缓存**，可整条删除）。
///
/// 与 library_entry 分开的原因：
/// - 用户数据（收藏/续看）永不被清理；
/// - 这里只放"浏览过的条目"，按 7 天滚动窗口 + 容量上限淘汰。
class SubjectCache extends Table {
  IntColumn get bangumiId => integer()();

  /// {"v":1,"subject":{...},"extras":{...},"characters":[...]}
  TextColumn get payloadJson => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {bangumiId};
}

@DriftDatabase(
  tables: [LibraryEntry, SubjectCache],
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
  int get schemaVersion => 5;

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
            SELECT CAST(anime_id AS TEXT), 'TV', anime_id, title, poster_path,
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
      if (from < 4) {
        // 详情快照缓存：独立表，与用户数据分离，便于整表清理
        await m.createTable(subjectCache);
      }
      if (from < 5) {
        // type 列 int→text（直接存 details.type），uid 收敛为 bangumiId 纯数字串。
        // 旧类型映射：0→TV，1→漫画，2→小说（旧注释语义）。
        await customStatement(
          'ALTER TABLE library_entry RENAME TO library_entry_old',
        );
        await m.createTable(libraryEntry);
        await customStatement('''
          INSERT INTO library_entry
            (id, uid, type, bangumi_id, title, poster_url, favorite,
             last_road_index, last_episode, last_episode_url,
             source_key, remote_id, last_unit_id, last_unit_title,
             detail_url, rule_json, roads_json, play_params_json,
             created_at, updated_at)
          SELECT id,
                 CASE WHEN bangumi_id IS NULL THEN uid
                      ELSE CAST(bangumi_id AS TEXT) END,
                 CASE type WHEN 0 THEN 'TV' WHEN 1 THEN '漫画'
                      WHEN 2 THEN '小说' ELSE '' END,
                 bangumi_id, title, poster_url, favorite,
                 last_road_index, last_episode, last_episode_url,
                 source_key, remote_id, last_unit_id, last_unit_title,
                 detail_url, rule_json, roads_json, play_params_json,
                 created_at, updated_at
          FROM library_entry_old
        ''');
        await customStatement('DROP TABLE library_entry_old');
      }
    },
  );
}
