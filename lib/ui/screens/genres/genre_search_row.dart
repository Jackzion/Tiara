import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/ui/theme/theme.dart';

typedef OnSearch = void Function(String searchString);

class GenreSearchRow extends ConsumerStatefulWidget {
  final String searchText;
  final OnSearch onSearch;
  const GenreSearchRow(this.searchText, this.onSearch, {super.key});
  @override
  ConsumerState<GenreSearchRow> createState() => _GenreSearchRowState();
}

class _GenreSearchRowState extends ConsumerState<GenreSearchRow> {
  late TextEditingController animeTextController =
      TextEditingController(text: widget.searchText);
  late FocusNode textFocusNode = FocusNode();

  @override
  void dispose() {
    animeTextController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 与外部 searchTextNotifier 保持同步（Dialog / 菜单写入时更新输入框）
    animeTextController.text = widget.searchText;
    return TextField(
      style: const TextStyle(color: ArchivePalette.ink),
      focusNode: textFocusNode,
      keyboardType: TextInputType.text,
      enableSuggestions: false,
      autofocus: false,
      onSubmitted: widget.onSearch,
      controller: animeTextController,
      autocorrect: false,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        focusColor: searchBarBackground,
        focusedBorder: null,
        enabledBorder: null,
        fillColor: searchBarBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintText: 'anime name, genre',
        hintStyle: body1Regular.copyWith(
          color: posterBorder,
          fontSize: 13,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            animeTextController.clear();
          },
          icon: const Icon(Icons.close, size: 18, color: ArchivePalette.ink),
        ),
        prefixIcon: IconButton(
          icon: const Icon(Icons.search, size: 20, color: ArchivePalette.ink),
          onPressed: () {
            widget.onSearch(animeTextController.text);
          },
        ),
      ),
    );
  }
}
