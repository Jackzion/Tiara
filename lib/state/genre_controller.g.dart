// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genre_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 分类页控制器（keepAlive：搜索会话跨 Tab 切换复用）
/// 持有 chip 选中态、外部 tag 与搜索结果，负责类型持久化与搜索编排

@ProviderFor(GenreController)
final genreControllerProvider = GenreControllerProvider._();

/// 分类页控制器（keepAlive：搜索会话跨 Tab 切换复用）
/// 持有 chip 选中态、外部 tag 与搜索结果，负责类型持久化与搜索编排
final class GenreControllerProvider
    extends $AsyncNotifierProvider<GenreController, GenrePageState> {
  /// 分类页控制器（keepAlive：搜索会话跨 Tab 切换复用）
  /// 持有 chip 选中态、外部 tag 与搜索结果，负责类型持久化与搜索编排
  GenreControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'genreControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$genreControllerHash();

  @$internal
  @override
  GenreController create() => GenreController();
}

String _$genreControllerHash() => r'1a83b5003e1d40781f107783da8ff827bea28e6b';

/// 分类页控制器（keepAlive：搜索会话跨 Tab 切换复用）
/// 持有 chip 选中态、外部 tag 与搜索结果，负责类型持久化与搜索编排

abstract class _$GenreController extends $AsyncNotifier<GenrePageState> {
  FutureOr<GenrePageState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GenrePageState>, GenrePageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GenrePageState>, GenrePageState>,
              AsyncValue<GenrePageState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
