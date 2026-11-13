import 'dart:async';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';
import 'package:movies/utils/utils.dart';

/// 轮播图自动播放延迟时间（毫秒）
const delayTime = 1000 * 5;

/// 图片切换动画过渡时间（毫秒）
const animationTime = 400;

/// 封面海报宽度（2:3，完整展示不裁切）
const heroPosterWidth = 214.0;

/// 封面海报高度
const heroPosterHeight = 320.0;

/// 缩略图卡片宽度
const thumbWidth = 200.0;

/// 缩略图图片高度
const thumbImageHeight = 112.0;

/// 缩略图标签高度
const thumbLabelHeight = 30.0;

/// 缩略图边框宽度
const thumbBorder = 2.0;

/// 缩略图卡片间距
const thumbGap = 16.0;

/// 缩略图行内边距
const thumbPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

/// 首页轮播档案：横幅作为底片，奶白纱罩在上面，墨字排成一张档案卡。
class HomeScreenImage extends ConsumerStatefulWidget {
  final OnAnimeTap onAnimeTap;
  final List<Anime> nowPlayingAnimes;

  const HomeScreenImage({
    required this.onAnimeTap,
    required this.nowPlayingAnimes,
    super.key,
  });

  @override
  ConsumerState<HomeScreenImage> createState() => _HomeScreenImageState();
}

class _HomeScreenImageState extends ConsumerState<HomeScreenImage> {
  int currentIndex = 0;
  Timer? autoPlayTimer;
  final ScrollController thumbController = ScrollController();

  @override
  void initState() {
    super.initState();
    startAutoPlay();
    loadExtras();
  }

  @override
  void dispose() {
    autoPlayTimer?.cancel();
    thumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animes = widget.nowPlayingAnimes;
    if (animes.isEmpty) {
      return const SizedBox.shrink();
    }
    final currentAnime = animes[currentIndex];
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
      child: ArchiveRegistration(
        child: Stack(
          children: [
            // 底片：模糊横幅
            Positioned.fill(child: buildBackground(currentAnime)),
            // 奶白纱：让墨字落在纸上，而不是压黑背景
            Positioned.fill(child: buildWash(context)),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildHero(context, currentAnime),
                buildThumbnailRow(context, animes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 底图：横幅大图模糊铺底（无横幅时回退封面）
  Widget buildBackground(Anime anime) {
    final url = anime.bannerImage ?? anime.image;
    return ColoredBox(
      color: ArchivePalette.raised,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: animationTime),
        child: ImageFiltered(
          key: ValueKey(url),
          imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  /// 奶白纱罩：横向由纸到雾，保证左侧海报与右侧文字都可读。
  Widget buildWash(BuildContext context) {
    final tone = ArchiveTone.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final start = (dark ? tone.pageEnd : tone.milk).withValues(alpha: 0.94);
    final end = (dark ? tone.pageEnd : tone.milk).withValues(alpha: 0.80);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
    );
  }

  /// 前景主区：完整封面 + 档案信息
  Widget buildHero(BuildContext context, Anime anime) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPoster(anime),
          const SizedBox(width: 24),
          Expanded(child: buildInfoPanel(context, anime)),
        ],
      ),
    );
  }

  /// 完整封面海报（3px 圆角 + 发丝线，点击带 Hero）
  Widget buildPoster(Anime anime) {
    final tone = ArchiveTone.of(context);
    return GestureDetector(
      onTap: () => openDetail(anime),
      child: Hero(
        tag: '${anime.image}swiper',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: animationTime),
          child: Container(
            key: ValueKey(anime.image),
            width: heroPosterWidth,
            height: heroPosterHeight,
            decoration: BoxDecoration(
              color: tone.raised,
              borderRadius: BorderRadius.circular(
                ArchiveGeometry.coverRadius,
              ),
              border: Border.all(
                color: tone.hairline,
                width: ArchiveGeometry.hairlineWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: anime.image,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  /// 信息面：编号、标题、元信息、简介、动作
  Widget buildInfoPanel(BuildContext context, Anime anime) {
    final tone = ArchiveTone.of(context);
    final count = widget.nowPlayingAnimes.length;
    return SizedBox(
      height: heroPosterHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArchiveCode(
                '00 / NOW PLAYING',
                color: tone.muted,
              ),
              const Spacer(),
              ArchiveCode(
                '${(currentIndex + 1).toString().padLeft(2, '0')} / '
                '${count.toString().padLeft(2, '0')}',
                color: tone.muted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            anime.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ArchiveType.display.copyWith(color: tone.ink),
          ),
          const SizedBox(height: 8),
          buildMetaRow(context, anime),
          const SizedBox(height: 14),
          Expanded(
            child: AutoSizeText(
              anime.synopsis ?? '',
              style: ArchiveType.bodyRegular.copyWith(color: tone.muted),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ArchivePillButton(
                label: '查看详情',
                icon: Icons.arrow_outward_rounded,
                onPressed: () => openDetail(anime),
              ),
              const SizedBox(width: 12),
              buildFavoriteButton(anime),
            ],
          ),
        ],
      ),
    );
  }

  /// 评分与元信息：评分是墨底 mono 章，其余是等宽档案行
  Widget buildMetaRow(BuildContext context, Anime anime) {
    final tone = ArchiveTone.of(context);
    final meta = <String>[
      if (anime.aired != null) '${anime.aired!.year}',
      if (anime.type != null && anime.type!.isNotEmpty) anime.type!,
      if (anime.rank != null) '排行 #${anime.rank}',
    ];
    return Row(
      children: [
        if (anime.score != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: tone.ink,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 11, color: tone.surface),
                const SizedBox(width: 4),
                Text(
                  anime.score!.toStringAsFixed(1),
                  style: ArchiveType.code.copyWith(
                    color: tone.surface,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (meta.isNotEmpty)
          Expanded(
            child: Text(
              meta.join(' · '),
              style: ArchiveType.meta.copyWith(color: tone.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// 收藏：圆形纸按钮，选中变砖红
  Widget buildFavoriteButton(Anime anime) {
    final tone = ArchiveTone.of(context);
    final favoriteSelected = ref
        .read(favoriteRepositoryProvider)
        .isFavorite(anime.animeId);
    return SizedBox(
      width: ArchiveGeometry.iconControlSize,
      height: ArchiveGeometry.iconControlSize,
      child: Material(
        color: tone.milk,
        shape: CircleBorder(
          side: BorderSide(
            color: tone.hairline,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => toggleFavorite(anime),
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Icon(
            favoriteSelected ? Icons.favorite : Icons.favorite_border,
            size: 19,
            color: favoriteSelected ? ArchivePalette.error : tone.ink,
          ),
        ),
      ),
    );
  }

  /// 缩略图轮播：当前项用墨色边 + 纸签
  Widget buildThumbnailRow(BuildContext context, List<Anime> animes) {
    return SizedBox(
      height:
          thumbPadding.vertical +
          thumbImageHeight +
          thumbLabelHeight +
          thumbBorder * 2,
      child: ListView.builder(
        controller: thumbController,
        scrollDirection: Axis.horizontal,
        padding: thumbPadding,
        itemCount: animes.length,
        itemBuilder: (context, index) =>
            buildThumbnailCard(context, animes[index], index),
      ),
    );
  }

  Widget buildThumbnailCard(BuildContext context, Anime anime, int index) {
    final tone = ArchiveTone.of(context);
    final active = index == currentIndex;
    return GestureDetector(
      onTap: () => selectIndex(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: thumbWidth,
          margin: const EdgeInsets.only(right: thumbGap),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
            border: Border.all(
              color: active ? tone.ink : tone.hairline,
              width: active ? 1.4 : ArchiveGeometry.hairlineWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CachedNetworkImage(
                imageUrl: anime.image,
                fit: BoxFit.cover,
                height: thumbImageHeight,
                width: thumbWidth,
              ),
              Container(
                height: thumbLabelHeight,
                color: active ? tone.ink : tone.milk,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  anime.title ?? '',
                  style: ArchiveType.micro.copyWith(
                    color: active ? tone.surface : tone.muted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 跳转到动漫详情页
  void openDetail(Anime anime) {
    widget.onAnimeTap(anime.animeId, '${anime.image}swiper');
  }

  /// 切换到指定缩略图，重置自动轮播计时器
  void selectIndex(int index) {
    setState(() {
      currentIndex = index;
    });
    startAutoPlay();
    scrollToCurrent();
    loadExtras();
  }

  /// 加载当前动漫的补充数据（宽幅横幅/简介），完成后刷新界面
  void loadExtras() {
    final animes = widget.nowPlayingAnimes;
    if (animes.isEmpty) {
      return;
    }
    ref
        .read(animeRepositoryProvider)
        .ensureExtras(animes[currentIndex])
        .then((_) {
          if (mounted) {
            setState(() {});
          }
        });
  }

  /// 启动自动轮播定时器
  void startAutoPlay() {
    autoPlayTimer?.cancel();
    autoPlayTimer = Timer.periodic(
      const Duration(milliseconds: delayTime),
      (_) {
        if (!mounted) {
          return;
        }
        final count = widget.nowPlayingAnimes.length;
        if (count == 0) {
          return;
        }
        setState(() {
          currentIndex = (currentIndex + 1) % count;
        });
        scrollToCurrent();
        loadExtras();
      },
    );
  }

  /// 将当前缩略图滚动到列表中间位置
  void scrollToCurrent() {
    if (!thumbController.hasClients) {
      return;
    }
    final itemPitch = thumbWidth + thumbGap;
    final itemCenter =
        thumbPadding.left + currentIndex * itemPitch + thumbWidth / 2;
    final target = (itemCenter - thumbController.position.viewportDimension / 2)
        .clamp(0.0, thumbController.position.maxScrollExtent);
    thumbController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// 切换动漫收藏状态并刷新界面
  void toggleFavorite(Anime anime) {
    ref.read(favoriteRepositoryProvider).toggleFavorite(anime);
    setState(() {});
  }
}
