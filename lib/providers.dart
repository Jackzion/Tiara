import 'dart:io';

import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/api/anilist_api_service.dart';
import 'package:movies/data/api/bangumi_api_service.dart';
import 'package:movies/data/database/drift/drift_database.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/models/comic_source.dart';
import 'package:movies/data/repositories/anime_repository.dart';
import 'package:movies/data/repositories/comic_repository.dart';
import 'package:movies/data/repositories/favorite_repository.dart';
import 'package:movies/data/repositories/rules_repository.dart';
import 'package:movies/network/rule_engine.dart';
import 'package:movies/router/app_routes.dart';
import 'package:movies/services/comic_source/comic_rule_catalog.dart';
import 'package:movies/services/commic/commic_image_loader.dart';
import 'package:movies/services/js/comic_source_parser.dart';
import 'package:movies/services/js/host_convert.dart';
import 'package:movies/services/js/host_network.dart';
import 'package:movies/services/js/js_engine_service.dart';
import 'package:movies/services/video_source/webview_video_source_service.dart';
import 'package:movies/utils/prefs.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'providers.g.dart';

/// 路由提供者
@Riverpod(keepAlive: true)
AppRouter appRouter(Ref ref) => AppRouter();

/// Bangumi API 服务提供者
/// 提供 BangumiApiService 实例（主数据源）
@Riverpod(keepAlive: true)
BangumiApiService bangumiApiService(Ref ref) => BangumiApiService();

/// AniList API 服务提供者
/// 提供 AniListApiService 实例（补充横幅与 PV）
@Riverpod(keepAlive: true)
AniListApiService anilistApiService(Ref ref) => AniListApiService();

/// SharedPreferences 提供者
/// 异步加载本地存储实例
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPrefs(Ref ref) => SharedPreferences.getInstance();

/// Prefs 提供者
/// 封装 SharedPreferences，提供类型安全的存储方法
@Riverpod(keepAlive: true)
Future<Prefs> prefs(Ref ref) async {
  final sharedPrefs = await ref.read(sharedPrefsProvider.future);
  return Prefs(sharedPrefs);
}

/// Drift 数据库提供者
@Riverpod(keepAlive: true)
IDatabase driftDatabase(Ref ref) => DriftDatabase();

/// 动漫数据仓库提供者（取数 + 缓存，无页面状态）
@Riverpod(keepAlive: true)
AnimeRepository animeRepository(Ref ref) => AnimeRepository(
      bangumiApiService: ref.read(bangumiApiServiceProvider),
      aniListApiService: ref.read(anilistApiServiceProvider),
      database: ref.read(driftDatabaseProvider),
      prefs: ref.read(prefsProvider.future),
    );

/// 收藏仓库提供者（收藏 CRUD + 内存缓存）
@Riverpod(keepAlive: true)
FavoriteRepository favoriteRepository(Ref ref) => FavoriteRepository(
      database: ref.read(driftDatabaseProvider),
      animeRepository: ref.read(animeRepositoryProvider),
    );

/// 数据层就绪门：各仓库 setup（标签/收藏/补充缓存预热）完成后 UI 才渲染
/// 替代原 AnimeViewModel.setup() 的启动编排
@Riverpod(keepAlive: true)
Future<void> dataReady(Ref ref) async {
  await ref.read(animeRepositoryProvider).setup();
  await ref.read(favoriteRepositoryProvider).setup();
}

/// 无头 WebView 取流服务（应用级单例）
/// keepAlive: 整个 App 生命周期内复用同一个 HeadlessWebview
@Riverpod(keepAlive: true)
WebviewVideoSourceService webviewVideoSourceService(Ref ref){
  final service = WebviewVideoSourceService();
  // provider 被销毁时（极少见，keepAlive 一般活到 App 退出）顺带销毁 WebView
  ref.onDispose(() {
    // fire-and-forget：dispose 是异步的，不阻塞销毁流程
    service.dispose();
  });
  return service;
}

/// 规则仓库：应用内单例
/// 提供 RulesRepository 实例（负责规则数据的读写）
@Riverpod(keepAlive: true)
Future<RulesRepository> rulesRepository(Ref ref) async {
  final prefs = await ref.read(prefsProvider.future);
  return RulesRepository(prefs);
}

/// 规则引擎（无状态；Dio 复用）
@Riverpod(keepAlive: true)
RuleEngine ruleEngine(Ref ref) => RuleEngine();

@Riverpod(keepAlive: true)
HostNetwork hostNetwork(Ref ref) => HostNetwork();

@Riverpod(keepAlive: true)
HostConvert hostConvert(Ref ref) => HostConvert();

@Riverpod(keepAlive: true)
JsEngineService jsEngineService(Ref ref) => JsEngineService(
  hostNetwork: ref.read(hostNetworkProvider),
  hostConvert: ref.read(hostConvertProvider),
);


@Riverpod(keepAlive: true)
Future<ComicRepository> comicRepository(Ref ref) async {
  final engine = ref.read(jsEngineServiceProvider);
  await engine.ensureInit();
  final dir = await RuleCatalogService().ruleDir();
  final sources = <String, ComicSource>{};
  /// 遍历已经下载的所有规则 .js 文件
  await for (final entity in dir.list()) {
    if (entity is! File || !entity.path.endsWith('.js')) {
      continue;
    }
    try {
      // init ComicSource by js file
      final source = await ComicSourceParser(engine).createAndParse(
        await entity.readAsString(),
        entity.uri.pathSegments.last,
      );
      sources[source.key] = source;
    } catch (e) {
      // 单条失败不阻塞其它源
      logError('装载规则失败 ${entity.path}: $e');
    }
  }
  return ComicRepository(sources);
}

@Riverpod(keepAlive: true)
ComicImageLoader comicImageLoader(Ref ref) => ComicImageLoader();
