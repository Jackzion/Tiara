// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_routes.dart';

/// generated route for
/// [AnimeDetail]
class AnimeDetailRoute extends PageRouteInfo<AnimeDetailRouteArgs> {
  AnimeDetailRoute({
    required int animeId,
    String? heroTag,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         AnimeDetailRoute.name,
         args: AnimeDetailRouteArgs(
           animeId: animeId,
           heroTag: heroTag,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'AnimeDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AnimeDetailRouteArgs>();
      return AnimeDetail(args.animeId, heroTag: args.heroTag, key: args.key);
    },
  );
}

class AnimeDetailRouteArgs {
  const AnimeDetailRouteArgs({required this.animeId, this.heroTag, this.key});

  final int animeId;

  final String? heroTag;

  final Key? key;

  @override
  String toString() {
    return 'AnimeDetailRouteArgs{animeId: $animeId, heroTag: $heroTag, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnimeDetailRouteArgs) return false;
    return animeId == other.animeId &&
        heroTag == other.heroTag &&
        key == other.key;
  }

  @override
  int get hashCode => animeId.hashCode ^ heroTag.hashCode ^ key.hashCode;
}

/// generated route for
/// [ComicReader]
class ComicReaderRoute extends PageRouteInfo<ComicReaderRouteArgs> {
  ComicReaderRoute({
    required String sourceKey,
    required String comicId,
    required String epId,
    required String title,
    String epTitle = '',
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ComicReaderRoute.name,
         args: ComicReaderRouteArgs(
           sourceKey: sourceKey,
           comicId: comicId,
           epId: epId,
           title: title,
           epTitle: epTitle,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicReaderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReaderRouteArgs>();
      return ComicReader(
        sourceKey: args.sourceKey,
        comicId: args.comicId,
        epId: args.epId,
        title: args.title,
        epTitle: args.epTitle,
        key: args.key,
      );
    },
  );
}

class ComicReaderRouteArgs {
  const ComicReaderRouteArgs({
    required this.sourceKey,
    required this.comicId,
    required this.epId,
    required this.title,
    this.epTitle = '',
    this.key,
  });

  final String sourceKey;

  final String comicId;

  final String epId;

  final String title;

  final String epTitle;

  final Key? key;

  @override
  String toString() {
    return 'ComicReaderRouteArgs{sourceKey: $sourceKey, comicId: $comicId, epId: $epId, title: $title, epTitle: $epTitle, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComicReaderRouteArgs) return false;
    return sourceKey == other.sourceKey &&
        comicId == other.comicId &&
        epId == other.epId &&
        title == other.title &&
        epTitle == other.epTitle &&
        key == other.key;
  }

  @override
  int get hashCode =>
      sourceKey.hashCode ^
      comicId.hashCode ^
      epId.hashCode ^
      title.hashCode ^
      epTitle.hashCode ^
      key.hashCode;
}

/// generated route for
/// [FavoriteScreen]
class FavoriteRoute extends PageRouteInfo<void> {
  const FavoriteRoute({List<PageRouteInfo>? children})
    : super(FavoriteRoute.name, initialChildren: children);

  static const String name = 'FavoriteRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FavoriteScreen();
    },
  );
}

/// generated route for
/// [GenreScreen]
class GenreRoute extends PageRouteInfo<void> {
  const GenreRoute({List<PageRouteInfo>? children})
    : super(GenreRoute.name, initialChildren: children);

  static const String name = 'GenreRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const GenreScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [MainScreen]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
    : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainScreen();
    },
  );
}

/// generated route for
/// [VideoPage]
class VideoPageRoute extends PageRouteInfo<VideoPageRouteArgs> {
  VideoPageRoute({
    required String animeVideo,
    required PlayContext? playContext,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         VideoPageRoute.name,
         args: VideoPageRouteArgs(
           animeVideo: animeVideo,
           playContext: playContext,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'VideoPageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VideoPageRouteArgs>();
      return VideoPage(args.animeVideo, args.playContext, key: args.key);
    },
  );
}

class VideoPageRouteArgs {
  const VideoPageRouteArgs({
    required this.animeVideo,
    required this.playContext,
    this.key,
  });

  final String animeVideo;

  final PlayContext? playContext;

  final Key? key;

  @override
  String toString() {
    return 'VideoPageRouteArgs{animeVideo: $animeVideo, playContext: $playContext, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VideoPageRouteArgs) return false;
    return animeVideo == other.animeVideo &&
        playContext == other.playContext &&
        key == other.key;
  }

  @override
  int get hashCode => animeVideo.hashCode ^ playContext.hashCode ^ key.hashCode;
}
