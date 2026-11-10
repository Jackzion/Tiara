// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_reader_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）

@ProviderFor(ComicReaderController)
final comicReaderControllerProvider = ComicReaderControllerFamily._();

/// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）
final class ComicReaderControllerProvider
    extends $AsyncNotifierProvider<ComicReaderController, ComicReaderState> {
  /// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）
  ComicReaderControllerProvider._({
    required ComicReaderControllerFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'comicReaderControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$comicReaderControllerHash();

  @override
  String toString() {
    return r'comicReaderControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ComicReaderController create() => ComicReaderController();

  @override
  bool operator ==(Object other) {
    return other is ComicReaderControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$comicReaderControllerHash() =>
    r'e93ac072e09fc4f858e6c142ad3b75fc2c0ff089';

/// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）

final class ComicReaderControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ComicReaderController,
          AsyncValue<ComicReaderState>,
          ComicReaderState,
          FutureOr<ComicReaderState>,
          (String, String, String)
        > {
  ComicReaderControllerFamily._()
    : super(
        retry: null,
        name: r'comicReaderControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）

  ComicReaderControllerProvider call(
    String sourceKey,
    String comicId,
    String epId,
  ) => ComicReaderControllerProvider._(
    argument: (sourceKey, comicId, epId),
    from: this,
  );

  @override
  String toString() => r'comicReaderControllerProvider';
}

/// 漫画阅读器控制器（family: sourceKey/comicId/epId，随页面销毁）

abstract class _$ComicReaderController
    extends $AsyncNotifier<ComicReaderState> {
  late final _$args = ref.$arg as (String, String, String);
  String get sourceKey => _$args.$1;
  String get comicId => _$args.$2;
  String get epId => _$args.$3;

  FutureOr<ComicReaderState> build(
    String sourceKey,
    String comicId,
    String epId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ComicReaderState>, ComicReaderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ComicReaderState>, ComicReaderState>,
              AsyncValue<ComicReaderState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}
