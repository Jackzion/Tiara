import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies/data/models/anime_trailer.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/utils/utils.dart';

/// 预告片：横向胶片条，每格 150×84，3px 圆角 + 发丝线。
class Trailer extends StatelessWidget {
  final List<AnimeTrailer> videos;
  final OnAnimeTrailerTap onVideoTap;

  const Trailer({required this.videos, required this.onVideoTap, super.key});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }
    final tone = ArchiveTone.of(context);

    Widget frame(Widget child) => Container(
      height: 84,
      width: 150,
      decoration: BoxDecoration(
        color: tone.raised,
        borderRadius: BorderRadius.circular(ArchiveGeometry.coverRadius),
        border: Border.all(
          color: tone.hairline,
          width: ArchiveGeometry.hairlineWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    return SizedBox(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (BuildContext context, int index) {
          final video = videos[index];
          return GestureDetector(
            onTap: () => onVideoTap(video),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        frame(
                          CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                ColoredBox(color: tone.raised),
                            errorWidget: (context, url, error) => Icon(
                              Icons.movie_creation_outlined,
                              color: tone.muted,
                              size: 26,
                            ),
                          ),
                        ),
                        // 墨色播放章
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: tone.ink.withValues(alpha: 0.82),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 15,
                              color: tone.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 150,
                      child: AutoSizeText(
                        video.title ?? 'Trailer ${index + 1}',
                        maxLines: 1,
                        style: ArchiveType.micro.copyWith(color: tone.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
