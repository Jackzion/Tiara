import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:movies/data/models/anime.dart';
import 'package:movies/utils/utils.dart';

/// 动漫行展示组件
/// 支持 Hero 动画过渡效果，点击后跳转到动漫详情页
class AnimeRow extends StatelessWidget {
  /// 动漫数据对象
  final Anime anime;
  /// 点击回调函数
  final OnAnimeTap onAnimeTap;

  const AnimeRow({
    required this.anime,
    required this.onAnimeTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 唯一的 Hero 动画标签，由动漫地址和 'AnimeRow' 组合生成
    String uniqueHeroTag = anime.image + 'AnimeRow';

    if (anime.image.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // Hero 标签随路由参数传给详情页，配对 Hero 动画
          onAnimeTap(anime.animeId, uniqueHeroTag);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 140,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                addHorizontalSpace(16),
                SizedBox(
                  height: 142,
                  width: 100,
                  child: Hero(
                    tag: uniqueHeroTag,
                    child: CachedNetworkImage(
                      imageUrl: anime.image,
                      alignment: Alignment.topCenter,
                      fit: BoxFit.cover,
                      height: 142,
                      width: 100,
                    ),
                  ),
                ),
                addHorizontalSpace(16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      anime.title ?? '',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    addVerticalSpace(4),
                    Text(
                      anime.aired?.year.toString() ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    addVerticalSpace(4),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
