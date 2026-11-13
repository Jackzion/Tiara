import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/utils/utils.dart';

/// 动漫类型枚举，用于区分不同分类的动漫
/// 用于生成唯一的 Hero 动画标签
enum AnimeType { trending, popular, topRated, nowPlaying }

/// 悬停变形动画时长
const morphDuration = Duration(milliseconds: 250);

/// 海报卡文案区高度（上间距 + 标题 + 间距 + 副标题）
const posterCaptionHeight = 48.0;

/// 横幅卡文案区高度（内边距 8×2 + 标题文案块）
const bannerCaptionHeight = posterCaptionHeight + 16;

/// 竖版海报卡在给定宽度下的高度（2:3 封面 + 文案）
double posterHeightFor(double width) => width * 3 / 2 + posterCaptionHeight;

/// 横幅卡在给定宽度下的高度（16:9 横幅 + 文案）
double bannerHeightFor(double width) => width * 9 / 16 + bannerCaptionHeight;

/// 动漫卡片：竖版海报（默认）+ 横幅（展开）。
///
/// 纸与档案：封面 3px 圆角 + 0.7 发丝线，评分是墨底 mono 编号，
/// 没有阴影、没有发光；文案区 14/w600 标题 + 11 元信息。
class AnimeWidget extends ConsumerStatefulWidget {
  final Anime anime;
  final OnAnimeTap onAnimeTap;
  final AnimeType animeType;
  final bool expanded;

  const AnimeWidget({
    required this.anime,
    required this.onAnimeTap,
    required this.animeType,
    this.expanded = false,
    super.key,
  });

  @override
  ConsumerState<AnimeWidget> createState() => _AnimeWidgetState();
}

class _AnimeWidgetState extends ConsumerState<AnimeWidget> {
  late String uniqueHeroTag;

  @override
  void initState() {
    super.initState();
    uniqueHeroTag = widget.anime.imageUrl + widget.animeType.name;
    ref.read(animeRepositoryProvider).ensureExtras(widget.anime).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    return GestureDetector(
      onTap: () => widget.onAnimeTap(anime.animeId, uniqueHeroTag),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: widget.expanded ? 0 : 1,
            duration: morphDuration,
            child: buildPosterCard(context, anime),
          ),
          IgnorePointer(
            ignoring: !widget.expanded,
            child: AnimatedOpacity(
              opacity: widget.expanded ? 1 : 0,
              duration: morphDuration,
              child: buildBannerCard(context, anime),
            ),
          ),
        ],
      ),
    );
  }

  /// 封面：3px 圆角 + 0.7px 发丝线，裁切在边框内。
  Widget buildCover(String imageUrl, {BorderRadius? radius}) {
    final tone = ArchiveTone.of(context);
    final r = radius ?? BorderRadius.circular(ArchiveGeometry.coverRadius);
    return Container(
      decoration: BoxDecoration(
        color: tone.raised,
        borderRadius: r,
        border: Border.all(
          color: tone.hairline,
          width: ArchiveGeometry.hairlineWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => buildFallback(context),
      ),
    );
  }

  /// 竖版海报卡（默认态）
  Widget buildPosterCard(BuildContext context, Anime anime) {
    final tone = ArchiveTone.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(tag: uniqueHeroTag, child: buildCover(anime.image)),
              if (anime.score != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: buildScoreBadge(context),
                ),
            ],
          ),
        ),
        SizedBox(
          height: posterCaptionHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                anime.title ?? '',
                style: ArchiveType.title.copyWith(color: tone.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                posterSubtitleOf(anime),
                style: ArchiveType.micro.copyWith(
                  color: tone.muted,
                  height: 1.45,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 横幅卡（展开态）：纸面板包住 16:9 横幅
  Widget buildBannerCard(BuildContext context, Anime anime) {
    final tone = ArchiveTone.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius),
        border: Border.all(
          color: tone.hairline,
          width: ArchiveGeometry.hairlineWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildCover(
                  anime.bannerImage ?? anime.image,
                  radius: BorderRadius.zero,
                ),
                if (anime.score != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildScoreBadge(context),
                  ),
                if (tagsOf(anime).isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: buildTags(context, anime),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: buildActions(context, anime),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: SizedBox(
              height: posterCaptionHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title ?? '',
                    style: ArchiveType.title.copyWith(
                      fontSize: 15,
                      color: tone.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bannerSubtitleOf(anime),
                    style: ArchiveType.micro.copyWith(
                      color: tone.muted,
                      height: 1.45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String posterSubtitleOf(Anime anime) {
    final synopsis = anime.synopsis ?? '';
    if (synopsis.isNotEmpty) {
      return synopsis;
    }
    return metaOf(anime);
  }

  String bannerSubtitleOf(Anime anime) {
    final titleJa = anime.titleJapanese ?? '';
    if (titleJa.isNotEmpty) {
      return titleJa;
    }
    return metaOf(anime);
  }

  String metaOf(Anime anime) {
    final meta = <String>[
      if (anime.aired != null) '${anime.aired!.year}',
      if (anime.type != null && anime.type!.isNotEmpty) anime.type!,
    ];
    return meta.join(' · ');
  }

  List<String> tagsOf(Anime anime) {
    return [
      if (anime.type != null && anime.type!.isNotEmpty) anime.type!,
      if (anime.episodes != null) '全${anime.episodes}话',
      if (anime.aired != null) '${anime.aired!.year}',
    ];
  }

  /// 标签：纸底 mono 小签，不用半透明黑影。
  Widget buildTags(BuildContext context, Anime anime) {
    final tone = ArchiveTone.of(context);
    final tags = tagsOf(anime);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tags.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: tone.milk.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: tone.hairline,
                width: ArchiveGeometry.hairlineWidth,
              ),
            ),
            child: Text(
              tags[i],
              style: ArchiveType.code.copyWith(
                color: tone.ink,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 评分：墨底 mono，像盖章的档案号。
  Widget buildScoreBadge(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tone.ink.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        widget.anime.score!.toStringAsFixed(1),
        style: ArchiveType.code.copyWith(
          color: tone.milk,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// 操作按钮：收藏（纸圆）+ 播放（墨圆）
  Widget buildActions(BuildContext context, Anime anime) {
    final tone = ArchiveTone.of(context);
    final favoriteSelected = ref
        .read(favoriteRepositoryProvider)
        .isFavorite(anime.animeId);
    Widget circle({
      required IconData icon,
      required VoidCallback onTap,
      required bool filled,
      Color? iconColor,
    }) => SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: filled ? tone.ink : tone.milk,
        shape: CircleBorder(
          side: BorderSide(
            color: filled ? Colors.transparent : tone.hairline,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? (filled ? tone.surface : tone.ink),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle(
          icon: favoriteSelected ? Icons.favorite : Icons.favorite_border,
          filled: false,
          iconColor: favoriteSelected ? ArchivePalette.error : tone.ink,
          onTap: () {
            ref.read(favoriteRepositoryProvider).toggleFavorite(anime);
            setState(() {});
          },
        ),
        const SizedBox(width: 8),
        circle(
          icon: Icons.play_arrow_rounded,
          filled: true,
          onTap: () => widget.onAnimeTap(anime.animeId, uniqueHeroTag),
        ),
      ],
    );
  }

  /// 图片失败：纸底 + 标题，不用渐变。
  Widget buildFallback(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Container(
      color: tone.raised,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        widget.anime.title ?? '',
        style: ArchiveType.meta.copyWith(color: tone.muted),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
