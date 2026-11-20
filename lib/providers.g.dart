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

/// 动漫数据仓库提供者（取数 + 解析，无缓存）

@ProviderFor(animeRepository)
final animeRepositoryProvider = AnimeRepositoryProvider._();

/// 动漫数据仓库提供者（取数 + 解析，无缓存）

final class AnimeRepositoryProvider
    extends
        $FunctionalProvider<AnimeRepository, AnimeRepository, AnimeRepository>
    with $Provider<AnimeRepository> {
  /// 动漫数据仓库提供者（取数 + 解析，无缓存）
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

String _$animeRepositoryHash() => r'5d121db54f6e800d4508db1a7f082a61684e1f56';

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

/// 书库仓库（收藏 + 续看指针；与 FavoriteRepository 共用同一张 library_entry）

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

/// 书库仓库（收藏 + 续看指针；与 FavoriteRepository 共用同一张 library_entry）

final class LibraryRepositoryProvider
    extends
        $FunctionalProvider<
          LibraryRepository,
          LibraryRepository,
          LibraryRepository
        >
    with $Provider<LibraryRepository> {
  /// 书库仓库（收藏 + 续看指针；与 FavoriteRepository 共用同一张 library_entry）
  LibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<LibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LibraryRepository create(Ref ref) {
    return libraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryRepository>(value),
    );
  }
}

String _$libraryRepositoryHash() => r'c145ff11cebe1fca9a3a924fc891d5850ef11304';

/// 详情快照缓存（SWR 的本地一侧）

@ProviderFor(animeCacheRepository)
final animeCacheRepositoryProvider = AnimeCacheRepositoryProvider._();

/// 详情快照缓存（SWR 的本地一侧）

final class AnimeCacheRepositoryProvider
    extends
        $FunctionalProvider<
          AnimeCacheRepository,
          AnimeCacheRepository,
          AnimeCacheRepository
        >
    with $Provider<AnimeCacheRepository> {
  /// 详情快照缓存（SWR 的本地一侧）
  AnimeCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'animeCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$animeCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnimeCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnimeCacheRepository create(Ref ref) {
    return animeCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimeCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimeCacheRepository>(value),
    );
  }
}

String _$animeCacheRepositoryHash() =>
    r'04445a3ed8306633150d6d09f0661809fbd07e52';

/// 「继续观看」列表：有进度指针的条目，按最近播放排序

@ProviderFor(recentPlays)
final recentPlaysProvider = RecentPlaysProvider._();

/// 「继续观看」列表：有进度指针的条目，按最近播放排序

final class RecentPlaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryResume>>,
          List<LibraryResume>,
          FutureOr<List<LibraryResume>>
        >
    with
        $FutureModifier<List<LibraryResume>>,
        $FutureProvider<List<LibraryResume>> {
  /// 「继续观看」列表：有进度指针的条目，按最近播放排序
  RecentPlaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentPlaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentPlaysHash();

  @$internal
  @override
  $FutureProviderElement<List<LibraryResume>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LibraryResume>> create(Ref ref) {
    return recentPlays(ref);
  }
}

String _$recentPlaysHash() => r'303f0686b35cabb833916a3899750d3270125a54';

/// 详情页用：按 bangumiId 查续看信息（没有则为 null）

@ProviderFor(animeResume)
final animeResumeProvider = AnimeResumeFamily._();

/// 详情页用：按 bangumiId 查续看信息（没有则为 null）

final class AnimeResumeProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibraryResume?>,
          LibraryResume?,
          FutureOr<LibraryResume?>
        >
    with $FutureModifier<LibraryResume?>, $FutureProvider<LibraryResume?> {
  /// 详情页用：按 bangumiId 查续看信息（没有则为 null）
  AnimeResumeProvider._({
    required AnimeResumeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'animeResumeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$animeResumeHash();

  @override
  String toString() {
    return r'animeResumeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LibraryResume?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibraryResume?> create(Ref ref) {
    final argument = this.argument as int;
    return animeResume(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeResumeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$animeResumeHash() => r'4f970f82ea22b6130fbe0be5b8363f44a9b40f90';

/// 详情页用：按 bangumiId 查续看信息（没有则为 null）

final class AnimeResumeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LibraryResume?>, int> {
  AnimeResumeFamily._()
    : super(
        retry: null,
        name: r'animeResumeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 详情页用：按 bangumiId 查续看信息（没有则为 null）

  AnimeResumeProvider call(int bangumiId) =>
      AnimeResumeProvider._(argument: bangumiId, from: this);

  @override
  String toString() => r'animeResumeProvider';
}

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

String _$dataReadyHash() => r'48cf341a8068ca5b95dae34ce7d2b64fff37e57f';

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

@ProviderFor(hostNetwork)
final hostNetworkProvider = HostNetworkProvider._();

final class HostNetworkProvider
    extends $FunctionalProvider<HostNetwork, HostNetwork, HostNetwork>
    with $Provider<HostNetwork> {
  HostNetworkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostNetworkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostNetworkHash();

  @$internal
  @override
  $ProviderElement<HostNetwork> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HostNetwork create(Ref ref) {
    return hostNetwork(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HostNetwork value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HostNetwork>(value),
    );
  }
}

String _$hostNetworkHash() => r'd1c00335f68b30fbc18c0f29080625f12a0df79b';

@ProviderFor(hostConvert)
final hostConvertProvider = HostConvertProvider._();

final class HostConvertProvider
    extends $FunctionalProvider<HostConvert, HostConvert, HostConvert>
    with $Provider<HostConvert> {
  HostConvertProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostConvertProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostConvertHash();

  @$internal
  @override
  $ProviderElement<HostConvert> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HostConvert create(Ref ref) {
    return hostConvert(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HostConvert value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HostConvert>(value),
    );
  }
}

String _$hostConvertHash() => r'cf1ca56b0f04347b90a4f9caddfd3ba535541be3';

@ProviderFor(hostHtml)
final hostHtmlProvider = HostHtmlProvider._();

final class HostHtmlProvider
    extends $FunctionalProvider<HostHtml, HostHtml, HostHtml>
    with $Provider<HostHtml> {
  HostHtmlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostHtmlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostHtmlHash();

  @$internal
  @override
  $ProviderElement<HostHtml> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HostHtml create(Ref ref) {
    return hostHtml(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HostHtml value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HostHtml>(value),
    );
  }
}

String _$hostHtmlHash() => r'1e0f8ef7de590cb73a5823b8f9d96fef11bbea6a';

@ProviderFor(jsEngineService)
final jsEngineServiceProvider = JsEngineServiceProvider._();

final class JsEngineServiceProvider
    extends
        $FunctionalProvider<JsEngineService, JsEngineService, JsEngineService>
    with $Provider<JsEngineService> {
  JsEngineServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jsEngineServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jsEngineServiceHash();

  @$internal
  @override
  $ProviderElement<JsEngineService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JsEngineService create(Ref ref) {
    return jsEngineService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JsEngineService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JsEngineService>(value),
    );
  }
}

String _$jsEngineServiceHash() => r'21478000ca4eea6f350d8f333507b065891e5e45';

@ProviderFor(comicRepository)
final comicRepositoryProvider = ComicRepositoryProvider._();

final class ComicRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ComicRepository>,
          ComicRepository,
          FutureOr<ComicRepository>
        >
    with $FutureModifier<ComicRepository>, $FutureProvider<ComicRepository> {
  ComicRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comicRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comicRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<ComicRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ComicRepository> create(Ref ref) {
    return comicRepository(ref);
  }
}

String _$comicRepositoryHash() => r'3cf73e22f6f01bfbf3795b2b5c2962ce7c1f3ead';

@ProviderFor(comicImageLoader)
final comicImageLoaderProvider = ComicImageLoaderProvider._();

final class ComicImageLoaderProvider
    extends
        $FunctionalProvider<
          ComicImageLoader,
          ComicImageLoader,
          ComicImageLoader
        >
    with $Provider<ComicImageLoader> {
  ComicImageLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comicImageLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comicImageLoaderHash();

  @$internal
  @override
  $ProviderElement<ComicImageLoader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ComicImageLoader create(Ref ref) {
    return comicImageLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComicImageLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComicImageLoader>(value),
    );
  }
}

String _$comicImageLoaderHash() => r'871871eeeda4bb204449a5660011b00d85273006';

/// 小说仓库：P1 阶段只挂内置 Demo 书源，P3 接入 QuickJS 规则源后
/// 再走 RuleCatalogService 装载（与 comicRepository 对称）。

@ProviderFor(novelRepository)
final novelRepositoryProvider = NovelRepositoryProvider._();

/// 小说仓库：P1 阶段只挂内置 Demo 书源，P3 接入 QuickJS 规则源后
/// 再走 RuleCatalogService 装载（与 comicRepository 对称）。

final class NovelRepositoryProvider
    extends
        $FunctionalProvider<NovelRepository, NovelRepository, NovelRepository>
    with $Provider<NovelRepository> {
  /// 小说仓库：P1 阶段只挂内置 Demo 书源，P3 接入 QuickJS 规则源后
  /// 再走 RuleCatalogService 装载（与 comicRepository 对称）。
  NovelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'novelRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$novelRepositoryHash();

  @$internal
  @override
  $ProviderElement<NovelRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NovelRepository create(Ref ref) {
    return novelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NovelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NovelRepository>(value),
    );
  }
}

String _$novelRepositoryHash() => r'9f1e3ba3d76be88e30b84f0bc0757b2ece2da2f3';
