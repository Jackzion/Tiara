import 'package:flutter/material.dart';
import 'package:movies/data/models/genre.dart';
import 'package:movies/data/models/genre_state.dart';
import 'package:movies/ui/theme/theme.dart';

typedef OnGenresSelected = void Function(List<GenreState>);
typedef OnGenresExpanded = void Function(bool);
typedef OnRemoveExternalTag = void Function(String tag);

class GenreSection extends StatelessWidget {
  final bool isExpanded;
  final List<GenreState> genreStates;

  /// 外部注入的临时 tag（详情页点标签），展示为前置 chip
  final List<String> externalTags;
  final OnGenresExpanded onGenresExpanded;
  final OnGenresSelected onGenresSelected;
  final OnRemoveExternalTag onRemoveExternalTag;

  const GenreSection({
    required this.genreStates,
    required this.externalTags,
    required this.isExpanded,
    required this.onGenresExpanded,
    required this.onGenresSelected,
    required this.onRemoveExternalTag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var genreChips = getGenreChips(context);
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onGenresExpanded(!isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Genres',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: dangerRed,
                          ),
                          child: Center(
                            child: Text(
                              totalSelected().toString(),
                              style: verySmallText,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: genreChips,
                          ),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 搜索 tags 中尚未出现在 genreStates 的部分，作为临时 chip 展示
  /// 与已有同名 chip 去重（search() 里也会对请求 tag 去重）
  List<String> get extraSearchTags {
    return [
      for (final tag in externalTags)
        if (tag.trim().isNotEmpty &&
            !genreStates.any((s) => s.genre.name == tag))
          tag,
    ];
  }

  // 生成标签 genre chips
  List<Widget> getGenreChips(BuildContext context) {
    // 搜索 tags 仅作为临时选中项展示在最前，不写入 genreStates
    final extras = extraSearchTags;
    final displayStates = [
      for (final tag in extras)
        GenreState(
          genre: Genre(malId: 0, name: tag),
          isSelected: true,
        ),
      ...genreStates,
    ];

    return List<Widget>.generate(displayStates.length, (index) {
      final genreState = displayStates[index];
      return FilterChip(
        backgroundColor: buttonGrey,
        selectedColor: accentAmber,
        labelStyle: TextStyle(
          color: genreState.isSelected ? onAccent : Colors.white,
        ),
        label: Text(
          genreState.genre.name,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        selected: genreState.isSelected,
        onSelected: (selected) {
          // 前 extras.length 个为搜索 tag chip：点击从列表移除该 tag，由父组件重搜
          if (index < extras.length) {
            onRemoveExternalTag(extras[index]);
            return;
          }
          // displayStates 前置了 tag chips，genreStates 下标需要回退用来获取 genreStates 真实index用来更新 isSelected
          final genreIndex = index - extras.length;
          genreStates[genreIndex] = genreState.copyWith(
            isSelected: selected,
          );
          // 回传全量列表，父组件只同步选中态，不覆盖为「仅已选」
          onGenresSelected(List<GenreState>.from(genreStates));
        },
      );
    });
  }

  List<GenreState> getSelectedGenres() {
    return genreStates.where((e) => e.isSelected).toList();
  }

  int totalSelected() {
    // 搜索 tag chips 也计入已选数量
    return getSelectedGenres().length + extraSearchTags.length;
  }
}
