// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
/// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
/// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉

@ProviderFor(AnimeDetailController)
final animeDetailControllerProvider = AnimeDetailControllerFamily._();

/// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
/// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
/// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉
final class AnimeDetailControllerProvider
    extends $AsyncNotifierProvider<AnimeDetailController, AnimeDetailState> {
  /// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
  /// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
  /// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉
  AnimeDetailControllerProvider._({
    required AnimeDetailControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'animeDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$animeDetailControllerHash();

  @override
  String toString() {
    return r'animeDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AnimeDetailController create() => AnimeDetailController();

  @override
  bool operator ==(Object other) {
    return other is AnimeDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$animeDetailControllerHash() =>
    r'8b082e3c8f371bacb7ef6a3a667033f52b3b1cc4';

/// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
/// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
/// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉

final class AnimeDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AnimeDetailController,
          AsyncValue<AnimeDetailState>,
          AnimeDetailState,
          FutureOr<AnimeDetailState>,
          int
        > {
  AnimeDetailControllerFamily._()
    : super(
        retry: null,
        name: r'animeDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
  /// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
  /// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉

  AnimeDetailControllerProvider call(int animeId) =>
      AnimeDetailControllerProvider._(argument: animeId, from: this);

  @override
  String toString() => r'animeDetailControllerProvider';
}

/// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
/// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
/// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉

abstract class _$AnimeDetailController
    extends $AsyncNotifier<AnimeDetailState> {
  late final _$args = ref.$arg as int;
  int get animeId => _$args;

  FutureOr<AnimeDetailState> build(int animeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AnimeDetailState>, AnimeDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AnimeDetailState>, AnimeDetailState>,
              AsyncValue<AnimeDetailState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
