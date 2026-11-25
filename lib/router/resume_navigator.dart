import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:movies/data/database/models/library_models.dart';
import 'package:movies/data/library/library_codec.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/play_context.dart';
import 'package:movies/router/app_routes.dart';

/// 续看跳转的统一入口：
/// - 漫画 → ComicReaderRoute
/// - 动画 → VideoPageRoute（用存入的 rule + roads 重建 PlayContext）
/// - 上下文不完整（旧数据 / 规则已删）→ 退回 AnimeDetailRoute
extension LibraryResumeNavigation on BuildContext {
  void openLibraryResume(LibraryResume resume) {
    if (resume.isComic) {
      openComicReader(resume);
      return;
    }
    if (!_tryOpenVideo(resume)) {
      _fallbackToDetail(resume);
    }
  }

  /// 返回的 Future 在阅读器退出时完成（详情页据此刷新续看信息）
  Future<void> openComicReader(
    LibraryResume resume, {
    String? epId,
    AnimeDetails? animeDetail,
  }) async {
    final sourceKey = resume.sourceKey;
    final comicId = resume.remoteId;
    final targetEp = epId ?? resume.lastUnitId;
    if (sourceKey == null || comicId == null || targetEp == null) return;
    await router.push(
      ComicReaderRoute(
        sourceKey: sourceKey,
        comicId: comicId,
        epId: targetEp,
        title: resume.title,
        epTitle: resume.lastUnitTitle ?? '',
        // 带上条目详情，阅读器才能把进度写回 uid=bangumiId 的主记录
        animeDetail: animeDetail,
      ),
    );
  }

  /// 返回 true 表示已跳转，false 表示上下文不完整需要 fallback
  bool _tryOpenVideo(LibraryResume resume) {
    final rule = decodeRule(resume.ruleJson);
    final roads = decodeRoads(resume.roadsJson);
    if (rule == null || roads.isEmpty) return false;
    router.push(
      VideoPageRoute(
        animeVideo: '',
        playContext: PlayContext(
          animeId: resume.bangumiId ?? 0,
          title: resume.title,
          detailUrl: resume.detailUrl ?? '',
          roads: roads,
          rule: rule,
          preferredEpisode: resume.lastEpisode,
          preferredRoadIndex: resume.lastRoadIndex,
        ),
        animeDetail: null,
      ),
    );
    return true;
  }

  void _fallbackToDetail(LibraryResume resume) {
    final bangumiId = resume.bangumiId;
    if (bangumiId != null) {
      router.push(AnimeDetailRoute(animeId: bangumiId));
    }
  }
}