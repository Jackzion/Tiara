// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 路由提供者

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// 路由提供者

final class AppRouterProvider
    extends $FunctionalProvider<AppRouter, AppRouter, AppRouter>
    with $Provider<AppRouter> {
  /// 路由提供者
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<AppRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppRouter>(value),
    );
  }
}

String _$appRouterHash() => r'fc1228daa214cc1ad475cfdeafc6db36a6a237b5';

/// Bangumi API 服务提供者
/// 提供 BangumiApiService 实例（主数据源）

@ProviderFor(bangumiApiService)
final bangumiApiServiceProvider = BangumiApiServiceProvider._();

/// Bangumi API 服务提供者
/// 提供 BangumiApiService 实例（主数据源）

final class BangumiApiServiceProvider
    extends
        $FunctionalProvider<
          BangumiApiService,
          BangumiApiService,
          BangumiApiService
        >
    with $Provider<BangumiApiService> {
  /// Bangumi API 服务提供者
  /// 提供 BangumiApiService 实例（主数据源）
  BangumiApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bangumiApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bangumiApiServiceHash();

  @$internal
  @override
  $ProviderElement<BangumiApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BangumiApiService create(Ref ref) {
    return bangumiApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BangumiApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BangumiApiService>(value),
    );
  }
}

String _$bangumiApiServiceHash() => r'93c3a4e3b3235725f4f72c078252c733ea30a285';

/// AniList API 服务提供者
/// 提供 AniListApiService 实例（补充横幅与 PV）

@ProviderFor(anilistApiService)
final anilistApiServiceProvider = AnilistApiServiceProvider._();

/// AniList API 服务提供者
/// 提供 AniListApiService 实例（补充横幅与 PV）

final class AnilistApiServiceProvider
    extends
        $FunctionalProvider<
          AniListApiService,
          AniListApiService,
          AniListApiService
        >
    with $Provider<AniListApiService> {
  /// AniList API 服务提供者
  /// 提供 AniListApiService 实例（补充横幅与 PV）
  AnilistApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'anilistApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$anilistApiServiceHash();

  @$internal
  @override
  $ProviderElement<AniListApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AniListApiService create(Ref ref) {
    return anilistApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AniListApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AniListApiService>(value),
    );
  }
}

String _$anilistApiServiceHash() => r'c4c09ab7135789434efdd244b39779b776979883';

/// SharedPreferences 提供者
/// 异步加载本地存储实例

@ProviderFor(sharedPrefs)
final sharedPrefsProvider = SharedPrefsProvider._();

/// SharedPreferences 提供者
/// 异步加载本地存储实例

final class SharedPrefsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  /// SharedPreferences 提供者
  /// 异步加载本地存储实例
  SharedPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPrefsHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPrefs(ref);
  }
}

String _$sharedPrefsHash() => r'eba279b4efb2d4ef41070faedd17991e4ffd9384';

/// Prefs 提供者
/// 封装 SharedPreferences，提供类型安全的存储方法

@ProviderFor(prefs)
final prefsProvider = PrefsProvider._();

/// Prefs 提供者
/// 封装 SharedPreferences，提供类型安全的存储方法

final class PrefsProvider
    extends $FunctionalProvider<AsyncValue<Prefs>, Prefs, FutureOr<Prefs>>
    with $FutureModifier<Prefs>, $FutureProvider<Prefs> {
  /// Prefs 提供者
  /// 封装 SharedPreferences，提供类型安全的存储方法
  PrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prefsHash();

  @$internal
  @override
  $FutureProviderElement<Prefs> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Prefs> create(Ref ref) {
    return prefs(ref);
  }
}

String _$prefsHash() => r'286d5a6891847e65488b246f20ce8495331773ef';

/// Drift 数据库提供者

@ProviderFor(driftDatabase)
final driftDatabaseProvider = DriftDatabaseProvider._();

/// Drift 数据库提供者

final class DriftDatabaseProvider
    extends $FunctionalProvider<IDatabase, IDatabase, IDatabase>
    with $Provider<IDatabase> {
  /// Drift 数据库提供者
  DriftDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driftDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driftDatabaseHash();

  @$internal
  @override
  $ProviderElement<IDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IDatabase create(Ref ref) {
    return driftDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDatabase>(value),
    );
  }
}

String _$driftDatabaseHash() => r'583c4a340ecf3aa018553a85ac492361a734c346';

/// 动漫数据仓库提供者（取数 + 缓存，无页面状态）

@ProviderFor(animeRepository)
final animeRepositoryProvider = AnimeRepositoryProvider._();

/// 动漫数据仓库提供者（取数 + 缓存，无页面状态）

final class AnimeRepositoryProvider
    extends
        $FunctionalProvider<AnimeRepository, AnimeRepository, AnimeRepository>
    with $Provider<AnimeRepository> {
  /// 动漫数据仓库提供者（取数 + 缓存，无页面状态）
  AnimeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'animeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$animeRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnimeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnimeRepository create(Ref ref) {
    return animeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimeRepository>(value),
    );
  }
}

String _$animeRepositoryHash() => r'1e786ee705ff3d46f5d0b3abda3accf7ce75aa6d';

/// 收藏仓库提供者（收藏 CRUD + 内存缓存）

@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider = FavoriteRepositoryProvider._();

/// 收藏仓库提供者（收藏 CRUD + 内存缓存）

final class FavoriteRepositoryProvider
    extends
        $FunctionalProvider<
          FavoriteRepository,
          FavoriteRepository,
          FavoriteRepository
        >
    with $Provider<FavoriteRepository> {
  /// 收藏仓库提供者（收藏 CRUD + 内存缓存）
  FavoriteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoriteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoriteRepository create(Ref ref) {
    return favoriteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteRepository>(value),
    );
  }
}

String _$favoriteRepositoryHash() =>
    r'21480af462f0c53518320d4a633ed889b629eac1';

/// 数据层就绪门：各仓库 setup（标签/收藏/补充缓存预热）完成后 UI 才渲染
/// 替代原 AnimeViewModel.setup() 的启动编排

@ProviderFor(dataReady)
final dataReadyProvider = DataReadyProvider._();

/// 数据层就绪门：各仓库 setup（标签/收藏/补充缓存预热）完成后 UI 才渲染
/// 替代原 AnimeViewModel.setup() 的启动编排

final class DataReadyProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// 数据层就绪门：各仓库 setup（标签/收藏/补充缓存预热）完成后 UI 才渲染
  /// 替代原 AnimeViewModel.setup() 的启动编排
  DataReadyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataReadyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataReadyHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return dataReady(ref);
  }
}

String _$dataReadyHash() => r'0729bd70c76e048010ab0801a2f51d785ae241ba';

/// 首页控制器（四个横栏列表 + 一次性加载）
/// keepAlive：列表在会话内复用，切换 Tab 不重新拉接口

@ProviderFor(homeController)
final homeControllerProvider = HomeControllerProvider._();

/// 首页控制器（四个横栏列表 + 一次性加载）
/// keepAlive：列表在会话内复用，切换 Tab 不重新拉接口

final class HomeControllerProvider
    extends $FunctionalProvider<HomeController, HomeController, HomeController>
    with $Provider<HomeController> {
  /// 首页控制器（四个横栏列表 + 一次性加载）
  /// keepAlive：列表在会话内复用，切换 Tab 不重新拉接口
  HomeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeControllerHash();

  @$internal
  @override
  $ProviderElement<HomeController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeController create(Ref ref) {
    return homeController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeController>(value),
    );
  }
}

String _$homeControllerHash() => r'8e123ceb732037bbeb08323df60ebad4e0b5e112';

/// 无头 WebView 取流服务（应用级单例）
/// keepAlive: 整个 App 生命周期内复用同一个 HeadlessWebview

@ProviderFor(webviewVideoSourceService)
final webviewVideoSourceServiceProvider = WebviewVideoSourceServiceProvider._();

/// 无头 WebView 取流服务（应用级单例）
/// keepAlive: 整个 App 生命周期内复用同一个 HeadlessWebview

final class WebviewVideoSourceServiceProvider
    extends
        $FunctionalProvider<
          WebviewVideoSourceService,
          WebviewVideoSourceService,
          WebviewVideoSourceService
        >
    with $Provider<WebviewVideoSourceService> {
  /// 无头 WebView 取流服务（应用级单例）
  /// keepAlive: 整个 App 生命周期内复用同一个 HeadlessWebview
  WebviewVideoSourceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webviewVideoSourceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webviewVideoSourceServiceHash();

  @$internal
  @override
  $ProviderElement<WebviewVideoSourceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WebviewVideoSourceService create(Ref ref) {
    return webviewVideoSourceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebviewVideoSourceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebviewVideoSourceService>(value),
    );
  }
}

String _$webviewVideoSourceServiceHash() =>
    r'e7a9e809c40b1617102527a8a5323fee16e46ca9';

/// 规则仓库：应用内单例
/// 提供 RulesRepository 实例（负责规则数据的读写）

@ProviderFor(rulesRepository)
final rulesRepositoryProvider = RulesRepositoryProvider._();

/// 规则仓库：应用内单例
/// 提供 RulesRepository 实例（负责规则数据的读写）

final class RulesRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<RulesRepository>,
          RulesRepository,
          FutureOr<RulesRepository>
        >
    with $FutureModifier<RulesRepository>, $FutureProvider<RulesRepository> {
  /// 规则仓库：应用内单例
  /// 提供 RulesRepository 实例（负责规则数据的读写）
  RulesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rulesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rulesRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<RulesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RulesRepository> create(Ref ref) {
    return rulesRepository(ref);
  }
}

String _$rulesRepositoryHash() => r'5c884e97800d3bbbdc5d1cb3128e2f2146b810a1';

/// 规则引擎（无状态；Dio 复用）

@ProviderFor(ruleEngine)
final ruleEngineProvider = RuleEngineProvider._();

/// 规则引擎（无状态；Dio 复用）

final class RuleEngineProvider
    extends $FunctionalProvider<RuleEngine, RuleEngine, RuleEngine>
    with $Provider<RuleEngine> {
  /// 规则引擎（无状态；Dio 复用）
  RuleEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleEngineHash();

  @$internal
  @override
  $ProviderElement<RuleEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RuleEngine create(Ref ref) {
    return ruleEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RuleEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RuleEngine>(value),
    );
  }
}

String _$ruleEngineHash() => r'64f75db1d7422b056139686298575f105cfa0985';
