import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/ui/theme/theme.dart';

/// 动漫详情页左侧完整海报
/// 展示完整封面 detail.image（主视觉），不做标题叠字；元信息放在海报下方
/// 背景渐进色横幅由 DetailBanner 负责（图源 bannerImage）
class DetailImage extends StatefulWidget {
  /// 动漫详情数据
  final AnimeDetails details;

  /// 海报宽度
  final double width;

  /// 来源页 Hero 标签；为空时不参与 Hero 动画
  final String? heroTag;

  const DetailImage({
    required this.details,
    this.width = 240,
    this.heroTag,
    super.key,
  });

  @override
  State<DetailImage> createState() => _DetailImageState();
}

class _DetailImageState extends State<DetailImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.details.image;
    // 无来源标签时用详情页本地标签：不参与跨页 Hero，只保证本页 Hero 标签唯一
    final heroTag =
        widget.heroTag ?? 'detail-poster-${widget.details.bangumiId}';

    // 参考页海报约 280×490，约 4:7；完整封面
    return AspectRatio(
      aspectRatio: 280 / 490,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: ColoredBox(
          color: buttonGrey,
          child: Hero(
            tag: heroTag,
            child: FadeTransition(
              opacity: _animation,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const ColoredBox(
                  color: buttonGrey,
                ),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: buttonGrey,
                  child: Center(
                    child: Icon(Icons.broken_image, color: iconPlaceholder),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}