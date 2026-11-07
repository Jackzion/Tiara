import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_state.g.dart';

/// 跨页搜索请求（全局搜索 / SearchDialog / 详情页点标签 → Genre 页消费）
class SearchRequest {
  const SearchRequest({this.keyword, this.extraTag, this.seq = 0, this.types = const [2]});

  /// 非空：按关键字搜索（保留现有 chip / 外部 tag）
  final String? keyword;

  /// 非空：追加外部 tag 搜索（保留现有关键字）
  final String? extraTag;

  /// 单调递增序号：同参数再搜也算新请求，消费方据此去重
  final int seq;

  /// 搜索类型（默认动画）
  final List<int> types;
}

/// 跨页搜索请求通道：谁搜谁写，Genre 页是唯一消费方
@riverpod
class SearchState extends _$SearchState {
  @override
  SearchRequest build() => const SearchRequest();

  /// 关键字搜索（全局搜索 / SearchDialog）
  void searchByKeyword(String keyword, {List<int> types = const [2]}) {
    state = SearchRequest(keyword: keyword, seq: state.seq + 1, types: types);
  }

  /// 追加外部标签搜索（详情页点标签）
  void addTag(String tag) {
    state = SearchRequest(extraTag: tag, seq: state.seq + 1);
  }
}
