import 'dart:convert';

import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/library/library_codec.dart';
import 'package:movies/data/models/novel_source.dart';
import 'package:movies/data/models/play_context.dart';

/// 书库（收藏 + 续看）仓库。
///
/// UI 只跟它打交道：写入「上次看到哪」、读「继续观看」列表、按 bangumiId 查续看。
class LibraryRepository {
  LibraryRepository({required this.database});

  final IDatabase database;

  /// 进入播放页/切集时调用：把当前线路、集号、规则与线路表一起落库。
  ///
  /// 只记「能直接重开播」的最小集合；评分/简介/banner 仍由 bangumi 现取。
  Future<void> saveAnimePlay({
    required PlayContext play,
    required int roadIndex,
    required int episodeIndex,
    String? type,
    String? posterUrl,
  }) async {
    if (play.rule == null || play.roads.isEmpty) return;
    final safeRoad = roadIndex.clamp(0, play.roads.length - 1);
    final road = play.roads[safeRoad];
    if (road.data.isEmpty) return;
    final safeEpisode = episodeIndex.clamp(0, road.data.length - 1);
    await database.savePlay(
      LibraryPlayUpdate(
        uid: '${play.animeId}',
        type: type,
        title: play.title,
        bangumiId: play.animeId,
        detailUrl: play.detailUrl,
        ruleJson: encodeRule(play.rule),
        roadsJson: encodeRoads(play.roads),
        lastRoadIndex: safeRoad,
        lastEpisode: safeEpisode + 1,
        lastEpisodeUrl: road.data[safeEpisode],
        posterUrl: posterUrl
      ),
    );
    logMessage("LibraryRepository.saveAnimePlay: $play $roadIndex $episodeIndex $posterUrl");
  }

  /// 进入漫画阅读器时调用：记住上次读到的那一话。
  /// [type] 直接存 details.type（'漫画' 等）；uid = bangumiId 纯数字串。
  Future<void> saveComicRead({
    required String sourceKey,
    required String comicId,
    required String title,
    required String epId,
    required String epTitle,
    int? bangumiId,
    String? type,
    String? posterUrl
  }) async {
    if (sourceKey.isEmpty || comicId.isEmpty || epId.isEmpty) return;
    var key = bangumiId;
    var kind = type;
    var poster = posterUrl;
    if (key == null) {
      final existing = await database.findComic(
        sourceKey: sourceKey,
        comicId: comicId,
      );
      if (existing != null) {
        key = existing.bangumiId;
        kind ??= existing.type;
        poster ??= existing.posterUrl;
      }
    }

    await database.savePlay(
      LibraryPlayUpdate(
        uid: key == null ? 'comic:$sourceKey:$comicId' : '$key',
        type: kind,
        title: title,
        bangumiId: key,
        sourceKey: sourceKey,
        remoteId: comicId,
        lastUnitId: epId,
        lastUnitTitle: epTitle,
        posterUrl: poster
      ),
    );
    if (key != null) {
      await database.deleteByUid('comic:$sourceKey:$comicId');
    }
  }

  /// 进入小说阅读器时调用：记住上次读到的章 + 章内位置（进度 JSON 塞 playParamsJson）。
  ///
  /// [progress] 为 null 则只记章；kind 字段与动画播放参数区分。
  Future<void> saveNovelRead({
    required String sourceKey,
    required String bookId,
    required String title,
    required String chapterId,
    required String chapterTitle,
    int? bangumiId,
    String? type,
    String? posterUrl,
    NovelProgress? progress,
  }) async {
    if (sourceKey.isEmpty || bookId.isEmpty || chapterId.isEmpty) return;
    await database.savePlay(
      LibraryPlayUpdate(
        uid: bangumiId == null ? 'novel:$sourceKey:$bookId' : '$bangumiId',
        type: type,
        title: title,
        bangumiId: bangumiId,
        sourceKey: sourceKey,
        remoteId: bookId,
        lastUnitId: chapterId,
        lastUnitTitle: chapterTitle,
        posterUrl: posterUrl,
        playParamsJson:
            progress == null ? null : jsonEncode(progress.toJson()),
      ),
    );
  }

  Future<List<LibraryResume>> recentPlays({int limit = 12}) =>
      database.recentPlays(limit: limit);

  Future<LibraryResume?> findAnime(int bangumiId) =>
      database.findAnime(bangumiId);

  Future<LibraryResume?> findComic({
    required String sourceKey,
    required String comicId,
  }) => database.findComic(sourceKey: sourceKey, comicId: comicId);

  Future<LibraryResume?> findNovel({
    required String sourceKey,
    required String bookId,
  }) => database.findNovel(sourceKey: sourceKey, bookId: bookId);
}
