import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies/data/database/models/database_models.dart';
import 'package:movies/utils/utils.dart';
import 'package:movies/ui/theme/theme.dart';

/// 收藏动漫行展示组件
class FavoriteRow extends StatelessWidget {
  final DBFavorite favorite;
  final OnAnimeTap onAnimeTap;
  final OnFavoriteResultsTap onFavoritesTap;

  const FavoriteRow({
    super.key,
    required this.favorite,
    required this.onAnimeTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = favorite.posterPath;

    return GestureDetector(
      onTap: () => onAnimeTap(favorite.animeId, null),
      child: SizedBox(
        height: 148,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            addHorizontalSpace(16),
            SizedBox(
              height: 140,
              width: 100,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      alignment: Alignment.topCenter,
                      fit: BoxFit.cover,
                      height: 140,
                      width: 100,
                    )
                  : const ColoredBox(color: buttonGrey),
            ),
            addHorizontalSpace(16),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => onFavoritesTap(favorite),
                      icon: favorite.favorite
                          ? const Icon(
                              Icons.favorite_outlined,
                              color: dangerRed,
                            )
                          : const Icon(
                              Icons.favorite_border,
                              color: ArchivePalette.ink,
                            ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            favorite.title,
                            maxLines: 1,
                            minFontSize: 10,
                            style: Theme.of(context).textTheme.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                          addVerticalSpace(4),
                          Text(
                            '${favorite.releaseDate.year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          addVerticalSpace(4),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
