// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_source_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 选图源面板状态（family: keyword，随面板销毁）

@ProviderFor(ComicSourceController)
final comicSourceControllerProvider = ComicSourceControllerFamily._();

/// 选图源面板状态（family: keyword，随面板销毁）
final class ComicSourceControllerProvider
    extends $AsyncNotifierProvider<ComicSourceController, ComicSheetState> {
  /// 选图源面板状态（family: keyword，随面板销毁）
  ComicSourceControllerProvider._({
    required ComicSourceControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'comicSourceControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$comicSourceControllerHash();

  @override
  String toString() {
    return r'comicSourceControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ComicSourceController create() => ComicSourceController();

  @override
  bool operator ==(Object other) {
    return other is ComicSourceControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$comicSourceControllerHash() =>
    r'31942af428af0980524b39df7e77a8c712950d98';

/// 选图源面板状态（family: keyword，随面板销毁）

final class ComicSourceControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ComicSourceController,
          AsyncValue<ComicSheetState>,
          ComicSheetState,
          FutureOr<ComicSheetState>,
          String
        > {
  ComicSourceControllerFamily._()
    : super(
        retry: null,
        name: r'comicSourceControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 选图源面板状态（family: keyword，随面板销毁）

  ComicSourceControllerProvider call(String keyword) =>
      ComicSourceControllerProvider._(argument: keyword, from: this);

  @override
  String toString() => r'comicSourceControllerProvider';
}

/// 选图源面板状态（family: keyword，随面板销毁）

abstract class _$ComicSourceController extends $AsyncNotifier<ComicSheetState> {
  late final _$args = ref.$arg as String;
  String get keyword => _$args;

  FutureOr<ComicSheetState> build(String keyword);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ComicSheetState>, ComicSheetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ComicSheetState>, ComicSheetState>,
              AsyncValue<ComicSheetState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
