import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/ui/theme/theme.dart';

/// 动漫类型枚举，用于区分不同分类的动漫
/// 用于生成唯一的 Hero 动画标签
enum AnimeType {
  trending,
  popular,
  topRated,
  nowPlaying,
}

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

/// 动漫卡片展示组件
/// 默认为竖版海报卡（2:3 封面 + 评分 + 标题/副标题）
/// [expanded] 为 true 时展示横幅卡（16:9 bannerImage + 标签 + 操作按钮），尺寸由父级给定
class AnimeWidget extends ConsumerStatefulWidget {
  /// 动漫数据对象
  final Anime anime;

  /// 点击回调函数
  final OnAnimeTap onAnimeTap;

  /// 动漫类型，用于生成唯一的 Hero 动画标签
  final AnimeType animeType;

  /// 是否为展开态（横幅卡）。展开尺寸由父级布局决定
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
  /// 唯一的 Hero 动画标签，由动漫地址和类型组合生成
  late String uniqueHeroTag;

  @override
  void initState() {
    super.initState();
    // 根据动漫地址和类型生成唯一的 Hero 标签
    uniqueHeroTag = widget.anime.imageUrl + widget.animeType.name;
    // 按需加载宽幅横幅（AniList，带缓存），供展开态使用
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
      onTap: () {
        // 设置当前的 Hero 标签，用于详情页动画
        ref.read(heroTagProvider.notifier).state = uniqueHeroTag;
        widget.onAnimeTap(anime.animeId);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 海报卡：默认态，展开时淡出
          AnimatedOpacity(
            opacity: widget.expanded ? 0 : 1,
            duration: morphDuration,
            child: buildPosterCard(context, anime),
          ),
          // 横幅卡：展开时淡入，尺寸随父级 2 列宽等比放大
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

  /// 竖版海报卡（默认态）：2:3 封面 + 评分角标 + 标题/副标题
  /// 图片区用 Expanded 吃掉剩余高度，避免尺寸过渡时 Column 溢出
  Widget buildPosterCard(BuildContext context, Anime anime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: uniqueHeroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: anime.image,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        buildFallback(context),
                  ),
                ),
              ),
              if (anime.score != null)
                Positioned(
                  right: 8,
                  bottom: 8,
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              addVerticalSpace(2),
              Text(
                posterSubtitleOf(anime),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: posterBorder),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 横幅卡（展开态）：16:9 横幅 + 评分/标签/操作按钮 + 标题/副标题
  /// 图片区用 Expanded 吃掉剩余高度，避免操作按钮随文案区一起把 Column 挤爆
  Widget buildBannerCard(BuildContext context, Anime anime) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: anime.bannerImage ?? anime.image,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        buildFallback(context),
                  ),
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
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: posterCaptionHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  addVerticalSpace(2),
                  Text(
                    bannerSubtitleOf(anime),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: posterBorder),
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

  /// 海报卡副标题：优先简介，其次年份与放送形式
  String posterSubtitleOf(Anime anime) {
    final synopsis = anime.synopsis ?? '';
    if (synopsis.isNotEmpty) {
      return synopsis;
    }
    return metaOf(anime);
  }

  /// 横幅卡副标题：优先日文原名，其次年份与放送形式
  String bannerSubtitleOf(Anime anime) {
    final titleJa = anime.titleJapanese ?? '';
    if (titleJa.isNotEmpty) {
      return titleJa;
    }
    return metaOf(anime);
  }

  /// 年份与放送形式
  String metaOf(Anime anime) {
    final meta = <String>[
      if (anime.aired != null) '${anime.aired!.year}',
      if (anime.type != null && anime.type!.isNotEmpty) anime.type!,
    ];
    return meta.join(' · ');
  }

  /// 图片上的标签（放送形式/话数/年份）
  List<String> tagsOf(Anime anime) {
    return [
      if (anime.type != null && anime.type!.isNotEmpty) anime.type!,
      if (anime.episodes != null) '全${anime.episodes}话',
      if (anime.aired != null) '${anime.aired!.year}',
    ];
  }

  /// 标签行（半透明胶囊）
  Widget buildTags(BuildContext context, Anime anime) {
    final tags = tagsOf(anime);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tags.length; i++) ...[
          if (i > 0) addHorizontalSpace(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x66000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tags[i],
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ],
    );
  }

  /// 评分角标
  Widget buildScoreBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.anime.score!.toStringAsFixed(1),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: accentAmberLight),
      ),
    );
  }

  /// 操作按钮：收藏 + 播放
  Widget buildActions(BuildContext context, Anime anime) {
    final favoriteSelected = ref.read(favoriteRepositoryProvider).isFavorite(anime.animeId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏按钮
        GestureDetector(
          onTap: () {
            ref.read(favoriteRepositoryProvider).toggleFavorite(anime);
            setState(() {});
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0x66000000),
              shape: BoxShape.circle,
            ),
            child: Icon(
              favoriteSelected ? Icons.favorite : Icons.favorite_border,
              color: favoriteSelected ? dangerRed : Colors.white,
              size: 20,
            ),
          ),
        ),
        addHorizontalSpace(8),
        // 播放按钮（跳转详情页）
        GestureDetector(
          onTap: () {
            ref.read(heroTagProvider.notifier).state = uniqueHeroTag;
            widget.onAnimeTap(anime.animeId);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: accentAmber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: onAccent,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /// 图片加载失败时的回退占位
  Widget buildFallback(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [buttonGrey, surfaceBar],
        ),
      ),
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        widget.anime.title ?? '',
        style: Theme.of(context).textTheme.titleSmall,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
