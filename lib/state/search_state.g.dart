// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方

@ProviderFor(SearchState)
final searchStateProvider = SearchStateProvider._();

/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
final class SearchStateProvider
    extends $NotifierProvider<SearchState, SearchRequest> {
  /// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
  SearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchStateProvider',
        isAutoDispose: true,
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

String _$searchStateHash() => r'1ae5524dd3026e2e27655e8051a91237316ee6e2';

/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方

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
