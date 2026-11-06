// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 首页控制器
/// build 即一次性加载四横栏；keepAlive + Riverpod 记忆化保证 rebuild 不重拉

@ProviderFor(HomeController)
final homeControllerProvider = HomeControllerProvider._();

/// 首页控制器
/// build 即一次性加载四横栏；keepAlive + Riverpod 记忆化保证 rebuild 不重拉
final class HomeControllerProvider
    extends $AsyncNotifierProvider<HomeController, HomeState> {
  /// 首页控制器
  /// build 即一次性加载四横栏；keepAlive + Riverpod 记忆化保证 rebuild 不重拉
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
  HomeController create() => HomeController();
}

String _$homeControllerHash() => r'991a7b145235d97267f652d7551619080fb26690';

/// 首页控制器
/// build 即一次性加载四横栏；keepAlive + Riverpod 记忆化保证 rebuild 不重拉

abstract class _$HomeController extends $AsyncNotifier<HomeState> {
  FutureOr<HomeState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HomeState>, HomeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeState>, HomeState>,
              AsyncValue<HomeState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
