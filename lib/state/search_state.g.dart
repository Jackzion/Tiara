// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
/// keepAlive：提交方（全局搜索/详情页）写入时消费页往往还没 build，
/// autoDispose 会把请求当垃圾回收，Genre 页 watch 到的是空 seq

@ProviderFor(SearchState)
final searchStateProvider = SearchStateProvider._();

/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
/// keepAlive：提交方（全局搜索/详情页）写入时消费页往往还没 build，
/// autoDispose 会把请求当垃圾回收，Genre 页 watch 到的是空 seq
final class SearchStateProvider
    extends $NotifierProvider<SearchState, SearchRequest> {
  /// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
  /// keepAlive：提交方（全局搜索/详情页）写入时消费页往往还没 build，
  /// autoDispose 会把请求当垃圾回收，Genre 页 watch 到的是空 seq
  SearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchStateHash();

  @$internal
  @override
  SearchState create() => SearchState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchRequest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchRequest>(value),
    );
  }
}

String _$searchStateHash() => r'65d0a1bba2e536b061ec772771a3b7c6630bc4f9';

/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
/// keepAlive：提交方（全局搜索/详情页）写入时消费页往往还没 build，
/// autoDispose 会把请求当垃圾回收，Genre 页 watch 到的是空 seq

abstract class _$SearchState extends $Notifier<SearchRequest> {
  SearchRequest build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchRequest, SearchRequest>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchRequest, SearchRequest>,
              SearchRequest,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
