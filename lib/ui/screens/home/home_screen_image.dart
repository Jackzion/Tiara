import 'dart:async';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/models/anime.dart';
import 'package:movies/providers.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/ui/theme/theme.dart';

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
const thumbLabelHeight = 33.0;

/// 缩略图边框宽度
const thumbBorder = 3.0;

/// 缩略图卡片间距
const thumbGap = 16.0;

/// 缩略图行内边距
const thumbPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

/// 首页轮播横幅组件
/// 横幅作为模糊背景，前景为完整封面海报与信息面板，缩略图轮播浮于背景之上
/// 点击封面/播放按钮跳转详情页，收藏按钮更新收藏状态
class HomeScreenImage extends ConsumerStatefulWidget {
  /// 点击回调函数
  final OnAnimeTap onAnimeTap;

  const HomeScreenImage({
    required this.onAnimeTap,
    super.key,
  });

  @override
  ConsumerState<HomeScreenImage> createState() => _HomeScreenImageState();
}

class _HomeScreenImageState extends ConsumerState<HomeScreenImage> {
  /// 当前展示的动漫索引
  int currentIndex = 0;

  /// 自动轮播定时器
  Timer? autoPlayTimer;

  /// 缩略图列表滚动控制器
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
    final animes = ref.read(homeControllerProvider).nowPlayingAnimes;
    if (animes.isEmpty) {
      return const SizedBox.shrink();
    }
    final currentAnime = animes[currentIndex];

    return Container(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 背景：横幅（模糊），无横幅时用封面
          Positioned.fill(child: buildBackground(currentAnime)),
          // 渐变压暗层，保证前景可读
          Positioned.fill(child: buildScrim()),
          // 前景内容
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
    );
  }

  /// 背景层：横幅大图模糊铺底（无横幅时回退封面）
  Widget buildBackground(Anime anime) {
    final url = anime.bannerImage ?? anime.image;
    return Container(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: animationTime),
        child: ImageFiltered(
          key: ValueKey(url),
          imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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

  /// 渐变压暗层
  Widget buildScrim() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Color(0xE6000000)],
        ),
      ),
    );
  }

  /// 前景主区：完整封面海报 + 信息面板
  Widget buildHero(BuildContext context, Anime anime) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPoster(anime),
          addHorizontalSpace(24),
          Expanded(child: buildInfoPanel(context, anime)),
        ],
      ),
    );
  }

  /// 完整封面海报（点击跳转详情页，带 Hero 动画）
  Widget buildPoster(Anime anime) {
    return GestureDetector(
      onTap: () => openDetail(anime),
      child: Hero(
        tag: '${anime.image}swiper',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: animationTime),
          child: ClipRRect(
            key: ValueKey(anime.image),
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: anime.image,
              fit: BoxFit.cover,
              width: heroPosterWidth,
              height: heroPosterHeight,
            ),
          ),
        ),
      ),
    );
  }

  /// 信息背景板：标题、评分、简介、操作按钮
  Widget buildInfoPanel(BuildContext context, Anime anime) {
    return Container(
      height: heroPosterHeight,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            anime.title ?? '',
            style: Theme.of(context).textTheme.headlineLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          addVerticalSpace(8),
          // 评分与元信息
          buildMetaRow(context, anime),
          addVerticalSpace(12),
          // 简介
          Expanded(
            child: AutoSizeText(
              anime.synopsis ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 操作按钮
          Row(
            children: [
              buildPlayButton(anime),
              addHorizontalSpace(16),
              buildFavoriteButton(anime),
            ],
          ),
        ],
      ),
    );
  }

  /// 评分与元信息行
  Widget buildMetaRow(BuildContext context, Anime anime) {
    final meta = <String>[
      if (anime.aired != null) '${anime.aired!.year}',
      if (anime.type != null && anime.type!.isNotEmpty) anime.type!,
      if (anime.rank != null) '排行 #${anime.rank}',
    ];
    return Row(
      children: [
        if (anime.score != null) ...[
          const Icon(Icons.star_rounded, color: accentAmberLight, size: 20),
          addHorizontalSpace(4),
          Text(
            anime.score!.toStringAsFixed(1),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: accentAmberLight),
          ),
        ],
        if (meta.isNotEmpty) ...[
          addHorizontalSpace(12),
          Flexible(
            child: Text(
              meta.join(' · '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// 播放按钮（点击跳转详情页）
  Widget buildPlayButton(Anime anime) {
    return GestureDetector(
      onTap: () => openDetail(anime),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: buttonGrey,
          size: 30,
        ),
      ),
    );
  }

  /// 收藏按钮（点击切换收藏状态并更新收藏列表）
  Widget buildFavoriteButton(Anime anime) {
    final favoriteSelected = ref.read(favoriteRepositoryProvider).isFavorite(anime.animeId);
    return GestureDetector(
      onTap: () => toggleFavorite(anime),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          favoriteSelected ? Icons.favorite : Icons.favorite_border,
          color:
              favoriteSelected ? dangerRed : buttonGrey,
          size: 24,
        ),
      ),
    );
  }

  /// 缩略图轮播区域（浮于背景之上）
  Widget buildThumbnailRow(BuildContext context, List<Anime> animes) {
    return SizedBox(
      height: thumbPadding.vertical +
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

  /// 单个缩略图卡片
  /// 点击切换横幅展示，选中状态显示白色边框和光晕
  Widget buildThumbnailCard(BuildContext context, Anime anime, int index) {
    final active = index == currentIndex;
    return GestureDetector(
      onTap: () => selectIndex(index),
      child: Container(
        width: thumbWidth,
        margin: const EdgeInsets.only(right: thumbGap),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xCCFFFFFF) : Colors.transparent,
            width: thumbBorder,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x4DFFFFFF),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
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
              color: const Color(0xB3000000),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                anime.title ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 跳转到动漫详情页
  void openDetail(Anime anime) {
    ref.read(heroTagProvider.notifier).state = '${anime.image}swiper';
    widget.onAnimeTap(anime.animeId);
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
    final animes = ref.read(homeControllerProvider).nowPlayingAnimes;
    if (animes.isEmpty) {
      return;
    }
    ref.read(animeRepositoryProvider).ensureExtras(animes[currentIndex]).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// 启动自动轮播定时器
  void startAutoPlay() {
    autoPlayTimer?.cancel();
    autoPlayTimer =
        Timer.periodic(const Duration(milliseconds: delayTime), (_) {
      if (!mounted) {
        return;
      }
      final count = ref.read(homeControllerProvider).nowPlayingAnimes.length;
      if (count == 0) {
        return;
      }
      setState(() {
        currentIndex = (currentIndex + 1) % count;
      });
      scrollToCurrent();
      loadExtras();
    });
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
