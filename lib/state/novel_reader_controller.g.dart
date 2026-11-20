// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_reader_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）

@ProviderFor(NovelReaderController)
final novelReaderControllerProvider = NovelReaderControllerFamily._();

/// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）
final class NovelReaderControllerProvider
    extends $AsyncNotifierProvider<NovelReaderController, NovelReaderState> {
  /// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）
  NovelReaderControllerProvider._({
    required NovelReaderControllerFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'novelReaderControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$novelReaderControllerHash();

  @override
  String toString() {
    return r'novelReaderControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  NovelReaderController create() => NovelReaderController();

  @override
  bool operator ==(Object other) {
    return other is NovelReaderControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelReaderControllerHash() =>
    r'ebf0accb44ddb6fab35003fd1db035406fa66677';

/// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）

final class NovelReaderControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          NovelReaderController,
          AsyncValue<NovelReaderState>,
          NovelReaderState,
          FutureOr<NovelReaderState>,
          (String, String, String)
        > {
  NovelReaderControllerFamily._()
    : super(
        retry: null,
        name: r'novelReaderControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）

  NovelReaderControllerProvider call(
    String sourceKey,
    String bookId,
    String chapterId,
  ) => NovelReaderControllerProvider._(
    argument: (sourceKey, bookId, chapterId),
    from: this,
  );

  @override
  String toString() => r'novelReaderControllerProvider';
}

/// 小说阅读器控制器（family: sourceKey/bookId/chapterId，随页面销毁）

abstract class _$NovelReaderController
    extends $AsyncNotifier<NovelReaderState> {
  late final _$args = ref.$arg as (String, String, String);
  String get sourceKey => _$args.$1;
  String get bookId => _$args.$2;
  String get chapterId => _$args.$3;

  FutureOr<NovelReaderState> build(
    String sourceKey,
    String bookId,
    String chapterId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NovelReaderState>, NovelReaderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NovelReaderState>, NovelReaderState>,
              AsyncValue<NovelReaderState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}
