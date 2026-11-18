import 'package:lumberdash/lumberdash.dart';
import 'package:movies/data/database/models/database_interface.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/library/library_codec.dart';
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
    String? posterUrl,
  }) async {
    if (play.rule == null || play.roads.isEmpty) return;
    final safeRoad = roadIndex.clamp(0, play.roads.length - 1);
    final road = play.roads[safeRoad];
    if (road.data.isEmpty) return;
    final safeEpisode = episodeIndex.clamp(0, road.data.length - 1);
    await database.savePlay(
      LibraryPlayUpdate(
        uid: 'anime:${play.animeId}',
        type: 0,
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
  Future<void> saveComicRead({
    required String sourceKey,
    required String comicId,
    required String title,
    required String epId,
    required String epTitle,
    String? posterUrl
  }) async {
    if (sourceKey.isEmpty || comicId.isEmpty || epId.isEmpty) return;
    await database.savePlay(
      LibraryPlayUpdate(
        uid: 'comic:$sourceKey:$comicId',
        type: 1,
        title: title,
        sourceKey: sourceKey,
        remoteId: comicId,
        lastUnitId: epId,
        lastUnitTitle: epTitle,
        posterUrl: posterUrl
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
}
