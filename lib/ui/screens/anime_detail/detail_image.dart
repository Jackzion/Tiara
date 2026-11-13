import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/ui/theme/archive_tokens.dart';

/// 动漫详情页左侧完整海报：3px 圆角 + 0.7 发丝线，纸底占位。
class DetailImage extends StatefulWidget {
  final AnimeDetails details;
  final double width;
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
    duration: ArchiveMotion.enter,
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: ArchiveMotion.ease,
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
    final tone = ArchiveTone.of(context);
    final imageUrl = widget.details.image;
    final heroTag =
        widget.heroTag ?? 'detail-poster-${widget.details.bangumiId}';

    return AspectRatio(
      aspectRatio: 280 / 490,
      child: Container(
        decoration: BoxDecoration(
          color: tone.raised,
          borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
          border: Border.all(
            color: tone.hairline,
            width: ArchiveGeometry.hairlineWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
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
              placeholder: (context, url) => ColoredBox(color: tone.raised),
              errorWidget: (context, url, error) => ColoredBox(
                color: tone.raised,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: tone.muted,
                    size: 22,
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
