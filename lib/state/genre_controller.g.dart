// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genre_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 分类页控制器（autoDispose：随页面销毁）
/// 持有类型 chip 选中态与当前搜索结果，负责类型选择持久化与搜索

@ProviderFor(GenreController)
final genreControllerProvider = GenreControllerProvider._();

/// 分类页控制器（autoDispose：随页面销毁）
/// 持有类型 chip 选中态与当前搜索结果，负责类型选择持久化与搜索
final class GenreControllerProvider
    extends $AsyncNotifierProvider<GenreController, GenrePageState> {
  /// 分类页控制器（autoDispose：随页面销毁）
  /// 持有类型 chip 选中态与当前搜索结果，负责类型选择持久化与搜索
  GenreControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'genreControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$genreControllerHash();

  @$internal
  @override
  GenreController create() => GenreController();
}

String _$genreControllerHash() => r'd7f7b8c76b54fd3833eb05452d7e4bedf9d46d4f';

/// 分类页控制器（autoDispose：随页面销毁）
/// 持有类型 chip 选中态与当前搜索结果，负责类型选择持久化与搜索

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
