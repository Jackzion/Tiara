import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/ui/theme/archive_tokens.dart';

/// 详情页顶部图版：横幅铺底，向下淡入纸色，标题交给正文区的档案条目。
class DetailBanner extends StatefulWidget {
  final AnimeDetails details;
  final String? bannerImage;
  final double height;

  const DetailBanner({
    required this.details,
    this.bannerImage,
    this.height = 300,
    super.key,
  });

  @override
  State<DetailBanner> createState() => _DetailBannerState();
}

class _DetailBannerState extends State<DetailBanner>
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
    final details = widget.details;
    final tone = ArchiveTone.of(context);
    final imageUrl =
        (widget.bannerImage != null && widget.bannerImage!.isNotEmpty)
        ? widget.bannerImage!
        : details.image;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: tone.raised,
            child: FadeTransition(
              opacity: _animation,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                alignment: Alignment.topCenter,
                fit: BoxFit.cover,
                placeholder: (context, url) => ColoredBox(color: tone.raised),
                errorWidget: (context, url, error) =>
                    ColoredBox(color: tone.raised),
              ),
            ),
          ),
          // 向下淡入纸色，衔接正文；顶部留一层极淡纸纱压住过亮的图
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tone.pageEnd.withValues(alpha: 0.10),
                    tone.pageEnd.withValues(alpha: 0.02),
                    tone.pageEnd.withValues(alpha: 0.72),
                    tone.pageEnd,
                  ],
                  stops: const [0.0, 0.34, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
