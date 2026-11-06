import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_nav_index.g.dart';

/// 主框架导航下标（Home / Genre / Favorites）
@riverpod
class CurrentNavIndex extends _$CurrentNavIndex {
  @override
  int build() => 0;

  void goTo(int index) {
    state = index;
  }
}
