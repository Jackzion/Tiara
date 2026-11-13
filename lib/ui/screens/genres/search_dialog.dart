import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/state/main_nav_index.dart';
import 'package:movies/state/search_state.dart';
import 'package:movies/ui/menus.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

/// 搜索弹窗：一个输入框 + 取消 / 搜索两个按钮
/// 确认后写入 [SearchStateProvider]，由 GenreScreen 消费并拉取结果
class SearchDialog extends ConsumerStatefulWidget {
  const SearchDialog({super.key});

  @override
  ConsumerState<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<SearchDialog> {
  TextEditingController searchTextController = TextEditingController();

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: searchBarBackground,
      title: Text(
        AppMenuAction.search.label,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: searchTextController,
          autofocus: true,
          style: const TextStyle(color: ArchivePalette.ink),
          keyboardType: TextInputType.text,
          enableSuggestions: false,
          autocorrect: false,
          onSubmitted: (_) => submitSearch(),
          decoration: InputDecoration(
            filled: true,
            fillColor: screenBackground,
            hintText: 'anime name, genre',
            hintStyle: body1Regular.copyWith(color: posterBorder),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: body2Regular),
        ),
        addHorizontalSpace(8),
        TextButton(
          onPressed: submitSearch,
          child: Text(AppMenuAction.search.label, style: body2Bold),
        ),
      ],
    );
  }

  /// 发送搜索：写入 SearchState 并切到 Genre 页
  /// MainScreen 下标：0 Home / 1 Genre / 2 Favorites
  void submitSearch() {
    final query = searchTextController.text.trim();
    ref.read(currentNavIndexProvider.notifier).goTo(1);
    ref.read(searchStateProvider.notifier).searchByKeyword(query);
    Navigator.of(context).pop();
  }
}
