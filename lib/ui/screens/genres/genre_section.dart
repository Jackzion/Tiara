import 'package:flutter/material.dart';
import 'package:movies/data/models/genre_state.dart';
import 'package:movies/data/repositories/anime_repository.dart';
import 'package:movies/state/genre_controller.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';

typedef OnTypeSelected = void Function(SubjectTypeFilter filter);
typedef OnGenresSelected = void Function(List<GenreState>);
typedef OnRemoveExternalTag = void Function(String tag);

/// 右侧筛选面板：分类（条目类型）+ 题材（标签）
class GenreSection extends StatelessWidget {
  final List<GenreState> genreStates;

  /// 外部注入的临时 tag（详情页点标签），展示为可移除 pill
  final List<String> externalTags;
  final SubjectTypeFilter typeFilter;
  final OnTypeSelected onTypeSelected;
  final OnGenresSelected onGenresSelected;
  final OnRemoveExternalTag onRemoveExternalTag;

  const GenreSection({
    required this.genreStates,
    required this.externalTags,
    required this.typeFilter,
    required this.onTypeSelected,
    required this.onGenresSelected,
    required this.onRemoveExternalTag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel('分类', [
            for (final filter in SubjectTypeFilter.values)
              _tag(
                label: _typeLabel(filter),
                active: filter == typeFilter,
                onTap: () => onTypeSelected(filter),
              ),
          ]),
          _panel('题材', [
            _tag(
              label: '全部',
              active: !AnimeRepository.genreTagNames.any((tag) => genreStates.any((state) => state.genre.name == tag && state.isSelected)),
              onTap: () => _clearSelected(AnimeRepository.genreTagNames),
            ),
            for (final tag in extraSearchTags)
              _tag(
                label: tag,
                active: true,
                onTap: () => onRemoveExternalTag(tag),
              ),
            for (final genreName in AnimeRepository.genreTagNames)
              _tag(
                label: genreName,
                active: genreStates.any(
                  (state) => state.genre.name == genreName && state.isSelected,
                ),
                onTap: () => _toggle(genreName),
              ),
          ]),
          _panel('地区', [
            _tag(
              label: '全部',
              active: !AnimeRepository.regionTagNames.any((tag) => genreStates.any((state) => state.genre.name == tag && state.isSelected)),
              onTap: () => _clearSelected(AnimeRepository.regionTagNames),
            ),
            for (final genreName in AnimeRepository.regionTagNames)
              _tag(
                label: genreName,
                active: genreStates.any(
                  (state) => state.genre.name == genreName && state.isSelected,
                ),
                onTap: () => _toggle(genreName),
              ),
          ]),
          _panel('受众', [
            _tag(
              label: '全部',
              active: !AnimeRepository.audienceTagNames.any((tag) => genreStates.any((state) => state.genre.name == tag && state.isSelected)),
              onTap: () => _clearSelected(AnimeRepository.audienceTagNames),
            ),
            for (final genreName in AnimeRepository.audienceTagNames)
              _tag(
                label: genreName,
                active: genreStates.any(
                  (state) => state.genre.name == genreName && state.isSelected,
                ),
                onTap: () => _toggle(genreName),
              ),
          ]),
          _panel('来源', [
            _tag(
              label: '全部',
              active: !AnimeRepository.sourceTagNames.any((tag) => genreStates.any((state) => state.genre.name == tag && state.isSelected)),
              onTap: () => _clearSelected(AnimeRepository.sourceTagNames),
            ),
            for (final genreName in AnimeRepository.sourceTagNames)
              _tag(
                label: genreName,
                active: genreStates.any(
                  (state) => state.genre.name == genreName && state.isSelected,
                ),
                onTap: () => _toggle(genreName),
              ),
          ]),
          _panel('进度', [
            _tag(
              label: '全部',
              active: !AnimeRepository.progressTagNames.any((tag) => genreStates.any((state) => state.genre.name == tag && state.isSelected)),
              onTap: () => _clearSelected(AnimeRepository.progressTagNames),
            ),
            for (final genreName in AnimeRepository.progressTagNames)
              _tag(
                label: genreName,
                active: genreStates.any(
                  (state) => state.genre.name == genreName && state.isSelected,
                ),
                onTap: () => _toggle(genreName),
              ),
          ]),
        ],
      ),
    );
  }

  /// 搜索 tags 中尚未出现在 genreStates 的部分，作为临时 pill 展示
  List<String> get extraSearchTags {
    return [
      for (final tag in externalTags)
        if (tag.trim().isNotEmpty &&
            !genreStates.any((state) => state.genre.name == tag))
          tag,
    ];
  }

  void _toggle(String tagName) {
    onGenresSelected([
      for (var i = 0; i < genreStates.length; i++)
        genreStates[i].genre.name == tagName
            ? genreStates[i].copyWith(isSelected: !genreStates[i].isSelected)
            : genreStates[i],
    ]);
  }

  void _clearSelected(List<String> filterTags) {
    onGenresSelected([
      for (final state in genreStates)
        filterTags.contains(state.genre.name)
            ? state.copyWith(isSelected: false)
            : state,
    ]);
  }

  String _typeLabel(SubjectTypeFilter filter) {
    switch (filter) {
      case SubjectTypeFilter.all:
        return '全部';
      case SubjectTypeFilter.book:
        return '书籍';
      case SubjectTypeFilter.anime:
        return '动画';
    }
  }

  Widget _panel(String title, List<Widget> tags) {
    return PaperPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: ArchiveType.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ArchivePalette.ink,
                  ),
                ),
              ),
              ArchiveCode('${tags.length}'),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: ArchiveGeometry.dividerWidth,
            color: ArchivePalette.hairline,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 1, runSpacing: 2, children: tags),
        ],
      ),
    );
  }

  Widget _tag({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? ArchivePalette.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
        hoverColor: ArchivePalette.raisedHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: ArchiveType.meta.copyWith(
              fontSize: 12.5,
              height: 22 / 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? ArchivePalette.milk : ArchivePalette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
