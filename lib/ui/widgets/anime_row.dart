import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

TextStyle _rowText(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
}) {
  return roboto.copyWith(fontSize: size, fontWeight: weight, color: color);
}

/// 作品规模文案：书籍用卷数（无 vols 回退 eps），动画用话数
String? scaleTextOf(Anime anime) {
  if (anime.subjectType == 1) {
    final n = anime.vols ?? anime.episodes;
    return n == null ? null : '$n卷';
  }
  return anime.episodes == null ? null : '${anime.episodes}话';
}

/// 首播日期文案 yyyy-MM-dd
String? dateTextOf(Anime anime) {
  final d = anime.aired;
  if (d == null) {
    return null;
  }
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// 评分星条：按 score/10 填充
class ScoreStars extends StatelessWidget {
  final double score;
  final double size;

  const ScoreStars({required this.score, this.size = 12, super.key});

  @override
  Widget build(BuildContext context) {
    final pct = (score / 10).clamp(0.0, 1.0);
    Widget starRow(Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(Icons.star_rounded, size: size, color: color),
      ],
    );
    return SizedBox(
      width: size * 5,
      height: size,
      child: Stack(
        children: [
          starRow(iconPlaceholder),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: starRow(accentAmberLight),
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏胶囊按钮
class FavoritePill extends ConsumerStatefulWidget {
  final Anime anime;

  const FavoritePill({required this.anime, super.key});

  @override
  ConsumerState<FavoritePill> createState() => _FavoritePillState();
}

class _FavoritePillState extends ConsumerState<FavoritePill> {
  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    final favorited = ref
        .read(favoriteRepositoryProvider)
        .isFavorite(anime.animeId);
    return Material(
      color: buttonGrey,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        hoverColor: textMuted.withValues(alpha: 0.14),
        onTap: () async {
          await ref.read(favoriteRepositoryProvider).toggleFavorite(anime);
          if (mounted) {
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: posterBorder.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (favorited) ...[
                const Icon(Icons.favorite, size: 11, color: dangerRed),
                addHorizontalSpace(5),
                Text('已收藏', style: _rowText(11, textSoft)),
                addHorizontalSpace(5),
                Text('|', style: _rowText(11, textMuted)),
                addHorizontalSpace(5),
                Text('✕', style: _rowText(11, textMuted)),
              ] else
                Text('收藏', style: _rowText(11, textSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 详细行（默认视图）：封面 + 标题/别名 + Rank 徽标 + 元信息 + 收藏 + 评分
class AnimeRow extends ConsumerStatefulWidget {
  final Anime anime;
  final OnAnimeTap onAnimeTap;

  const AnimeRow({required this.anime, required this.onAnimeTap, super.key});

  @override
  ConsumerState<AnimeRow> createState() => _AnimeRowState();
}

class _AnimeRowState extends ConsumerState<AnimeRow> {
  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    final heroTag = '${anime.image}AnimeRow';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onAnimeTap(anime.animeId, heroTag),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cover(heroTag),
            addHorizontalSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow(),
                  addVerticalSpace(3),
                  _metaRow(),
                  addVerticalSpace(7),
                  _scoreRow(),
                  addVerticalSpace(9),
                  const Divider(height: 1, thickness: 1, color: dividerLine),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(String heroTag) {
    final anime = widget.anime;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 86,
        height: 116,
        child: Hero(
          tag: heroTag,
          child: anime.image.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: anime.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: buttonGrey),
                  errorWidget: (context, url, error) => Container(
                    color: buttonGrey,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 22,
                      color: iconPlaceholder,
                    ),
                  ),
                )
              : Container(
                  color: buttonGrey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 22,
                    color: iconPlaceholder,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _titleRow() {
    final anime = widget.anime;
    final alt = anime.titleJapanese;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: anime.title ?? '',
                  style: _rowText(
                    15,
                    Colors.white,
                    weight: FontWeight.w600,
                  ).copyWith(height: 19 / 15),
                ),
                if (alt != null && alt.isNotEmpty)
                  TextSpan(text: '  $alt', style: _rowText(11, textMuted)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (anime.rank != null) ...[
          addHorizontalSpace(12),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accentAmberDeep,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Rank ${anime.rank}',
              style: _rowText(
                10.5,
                onAccent,
                weight: FontWeight.w600,
              ).copyWith(letterSpacing: 0.2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metaRow() {
    final anime = widget.anime;
    final scale = scaleTextOf(anime);
    final date = dateTextOf(anime);
    final type = anime.type;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (scale != null) ...[
                  TextSpan(text: scale, style: _rowText(12, textSoft)),
                  TextSpan(text: ' / ', style: _rowText(12, textMuted)),
                ],
                if (date != null) ...[
                  TextSpan(text: date, style: _rowText(12, textSoft)),
                  if (type != null && type.isNotEmpty)
                    TextSpan(text: ' / ', style: _rowText(12, textMuted)),
                ],
                if (type != null && type.isNotEmpty)
                  TextSpan(text: type, style: _rowText(12, textMuted)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        addHorizontalSpace(12),
        FavoritePill(anime: anime),
      ],
    );
  }

  Widget _scoreRow() {
    final anime = widget.anime;
    final score = anime.score;
    if (score == null) {
      return const SizedBox(height: 12);
    }
    return Row(
      children: [
        ScoreStars(score: score),
        addHorizontalSpace(6),
        Text(
          score.toStringAsFixed(1),
          style: _rowText(11, accentAmberLight, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// 紧凑行（列表视图）：标题 + 元信息 + 评分
class AnimeCompactRow extends StatelessWidget {
  final Anime anime;
  final OnAnimeTap onAnimeTap;

  const AnimeCompactRow({
    required this.anime,
    required this.onAnimeTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scale = scaleTextOf(anime);
    final date = dateTextOf(anime);
    final meta = [scale, date, anime.type]
        .where((s) => s != null && s.isNotEmpty)
        .join(' / ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAnimeTap(anime.animeId, null),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    anime.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowText(13, Colors.white, weight: FontWeight.w600),
                  ),
                ),
                addHorizontalSpace(12),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _rowText(11, textMuted),
                ),
                addHorizontalSpace(12),
                if (anime.score != null)
                  Text(
                    anime.score!.toStringAsFixed(1),
                    style: _rowText(
                      11,
                      accentAmberLight,
                      weight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            addVerticalSpace(9),
            const Divider(height: 1, thickness: 1, color: dividerLine),
          ],
        ),
      ),
    );
  }
}

/// 网格卡片（网格视图）：封面 + 标题 + 评分
class AnimeGridTile extends StatelessWidget {
  final Anime anime;
  final OnAnimeTap onAnimeTap;

  const AnimeGridTile({
    required this.anime,
    required this.onAnimeTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = '${anime.image}AnimeGrid';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAnimeTap(anime.animeId, heroTag),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: AspectRatio(
              aspectRatio: 86 / 116,
              child: Hero(
                tag: heroTag,
                child: anime.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: anime.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: buttonGrey),
                        errorWidget: (context, url, error) =>
                            Container(color: buttonGrey),
                      )
                    : Container(color: buttonGrey),
              ),
            ),
          ),
          addVerticalSpace(6),
          Text(
            anime.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _rowText(12, Colors.white, weight: FontWeight.w600),
          ),
          addVerticalSpace(4),
          Row(
            children: [
              if (anime.score != null) ...[
                ScoreStars(score: anime.score!, size: 10),
                addHorizontalSpace(4),
                Text(
                  anime.score!.toStringAsFixed(1),
                  style: _rowText(
                    11,
                    accentAmberLight,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              if (anime.rank != null)
                Text('Rank ${anime.rank}', style: _rowText(10, textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
