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
    AnimeDetails? animeDetail,
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
           animeDetail: animeDetail,
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
        animeDetail: args.animeDetail,
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
    this.animeDetail,
  });

  final String sourceKey;

  final String comicId;

  final String epId;

  final String title;

  final String epTitle;

  final Key? key;

  final AnimeDetails? animeDetail;

  @override
  String toString() {
    return 'ComicReaderRouteArgs{sourceKey: $sourceKey, comicId: $comicId, epId: $epId, title: $title, epTitle: $epTitle, key: $key, animeDetail: $animeDetail}';
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
        key == other.key &&
        animeDetail == other.animeDetail;
  }

  @override
  int get hashCode =>
      sourceKey.hashCode ^
      comicId.hashCode ^
      epId.hashCode ^
      title.hashCode ^
      epTitle.hashCode ^
      key.hashCode ^
      animeDetail.hashCode;
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
/// [NovelReader]
class NovelReaderRoute extends PageRouteInfo<NovelReaderRouteArgs> {
  NovelReaderRoute({
    required String sourceKey,
    required String bookId,
    required String chapterId,
    required String title,
    String chapterTitle = '',
    AnimeDetails? animeDetail,
    int? initialParagraph,
    int? initialOffset,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         NovelReaderRoute.name,
         args: NovelReaderRouteArgs(
           sourceKey: sourceKey,
           bookId: bookId,
           chapterId: chapterId,
           title: title,
           chapterTitle: chapterTitle,
           animeDetail: animeDetail,
           initialParagraph: initialParagraph,
           initialOffset: initialOffset,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'NovelReaderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NovelReaderRouteArgs>();
      return NovelReader(
        sourceKey: args.sourceKey,
        bookId: args.bookId,
        chapterId: args.chapterId,
        title: args.title,
        chapterTitle: args.chapterTitle,
        animeDetail: args.animeDetail,
        initialParagraph: args.initialParagraph,
        initialOffset: args.initialOffset,
        key: args.key,
      );
    },
  );
}

class NovelReaderRouteArgs {
  const NovelReaderRouteArgs({
    required this.sourceKey,
    required this.bookId,
    required this.chapterId,
    required this.title,
    this.chapterTitle = '',
    this.animeDetail,
    this.initialParagraph,
    this.initialOffset,
    this.key,
  });

  final String sourceKey;

  final String bookId;

  final String chapterId;

  final String title;

  final String chapterTitle;

  final AnimeDetails? animeDetail;

  final int? initialParagraph;

  final int? initialOffset;

  final Key? key;

  @override
  String toString() {
    return 'NovelReaderRouteArgs{sourceKey: $sourceKey, bookId: $bookId, chapterId: $chapterId, title: $title, chapterTitle: $chapterTitle, animeDetail: $animeDetail, initialParagraph: $initialParagraph, initialOffset: $initialOffset, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NovelReaderRouteArgs) return false;
    return sourceKey == other.sourceKey &&
        bookId == other.bookId &&
        chapterId == other.chapterId &&
        title == other.title &&
        chapterTitle == other.chapterTitle &&
        animeDetail == other.animeDetail &&
        initialParagraph == other.initialParagraph &&
        initialOffset == other.initialOffset &&
        key == other.key;
  }

  @override
  int get hashCode =>
      sourceKey.hashCode ^
      bookId.hashCode ^
      chapterId.hashCode ^
      title.hashCode ^
      chapterTitle.hashCode ^
      animeDetail.hashCode ^
      initialParagraph.hashCode ^
      initialOffset.hashCode ^
      key.hashCode;
}

/// generated route for
/// [VideoPage]
class VideoPageRoute extends PageRouteInfo<VideoPageRouteArgs> {
  VideoPageRoute({
    required String animeVideo,
    required PlayContext? playContext,
    required AnimeDetails? animeDetail,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         VideoPageRoute.name,
         args: VideoPageRouteArgs(
           animeVideo: animeVideo,
           playContext: playContext,
           animeDetail: animeDetail,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'VideoPageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VideoPageRouteArgs>();
      return VideoPage(
        args.animeVideo,
        args.playContext,
        args.animeDetail,
        key: args.key,
      );
    },
  );
}

class VideoPageRouteArgs {
  const VideoPageRouteArgs({
    required this.animeVideo,
    required this.playContext,
    required this.animeDetail,
    this.key,
  });

  final String animeVideo;

  final PlayContext? playContext;

  final AnimeDetails? animeDetail;

  final Key? key;

  @override
  String toString() {
    return 'VideoPageRouteArgs{animeVideo: $animeVideo, playContext: $playContext, animeDetail: $animeDetail, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VideoPageRouteArgs) return false;
    return animeVideo == other.animeVideo &&
        playContext == other.playContext &&
        animeDetail == other.animeDetail &&
        key == other.key;
  }

  @override
  int get hashCode =>
      animeVideo.hashCode ^
      playContext.hashCode ^
      animeDetail.hashCode ^
      key.hashCode;
}
