// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 收藏列表流（数据库变更自动推送）

@ProviderFor(favoriteList)
final favoriteListProvider = FavoriteListProvider._();

/// 收藏列表流（数据库变更自动推送）

final class FavoriteListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DBFavorite>>,
          List<DBFavorite>,
          Stream<List<DBFavorite>>
        >
    with $FutureModifier<List<DBFavorite>>, $StreamProvider<List<DBFavorite>> {
  /// 收藏列表流（数据库变更自动推送）
  FavoriteListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteListHash();

  @$internal
  @override
  $StreamProviderElement<List<DBFavorite>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DBFavorite>> create(Ref ref) {
    return favoriteList(ref);
  }
}

String _$favoriteListHash() => r'a86da9dbc225d268a8e9e735104ab2fbf22d336e';

/// 收藏页控制器（autoDispose：随页面销毁）
/// 持有排序方式，负责收藏列表排序与删除

@ProviderFor(FavoriteController)
final favoriteControllerProvider = FavoriteControllerProvider._();

/// 收藏页控制器（autoDispose：随页面销毁）
/// 持有排序方式，负责收藏列表排序与删除
final class FavoriteControllerProvider
    extends $NotifierProvider<FavoriteController, Sorting> {
  /// 收藏页控制器（autoDispose：随页面销毁）
  /// 持有排序方式，负责收藏列表排序与删除
  FavoriteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteControllerHash();

  @$internal
  @override
  FavoriteController create() => FavoriteController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Sorting value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Sorting>(value),
    );
  }
}

String _$favoriteControllerHash() =>
    r'bedc6e0a04b332568bafbeaa9a60a28ecce8050d';

/// 收藏页控制器（autoDispose：随页面销毁）
/// 持有排序方式，负责收藏列表排序与删除

abstract class _$FavoriteController extends $Notifier<Sorting> {
  Sorting build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Sorting, Sorting>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Sorting, Sorting>,
              Sorting,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
