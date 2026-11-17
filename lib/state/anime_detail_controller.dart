import 'dart:async';

import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_character.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/anime_trailer.dart';
import 'package:movies/data/models/detail_snapshot.dart';
import 'package:movies/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_detail_controller.g.dart';

/// 动漫详情页数据
class AnimeDetailState {
  const AnimeDetailState({
    this.animeDetails,
    this.bannerImage,
    this.trailerVideos = const [],
    this.characters = const [],
    this.isFavorite = false,
    this.fetchedAt,
    this.refreshFailed = false,
    this.refreshing = false,
  });

  final AnimeDetails? animeDetails;
  final String? bannerImage;
  final List<AnimeTrailer> trailerVideos;
  final List<AnimeCharacter> characters;
  final bool isFavorite;

  /// 快照生成时间（用于「显示的是哪天的存档」提示）
  final DateTime? fetchedAt;

  /// 后台刷新失败但旧数据可用
  final bool refreshFailed;

  /// 正在刷新（手动重试时给按钮转圈）
  final bool refreshing;

  AnimeDetailState copyWith({
    AnimeDetails? animeDetails,
    String? bannerImage,
    List<AnimeTrailer>? trailerVideos,
    List<AnimeCharacter>? characters,
    bool? isFavorite,
    DateTime? fetchedAt,
    bool? refreshFailed,
    bool? refreshing,
  }) {
    return AnimeDetailState(
      animeDetails: animeDetails ?? this.animeDetails,
      bannerImage: bannerImage ?? this.bannerImage,
      trailerVideos: trailerVideos ?? this.trailerVideos,
      characters: characters ?? this.characters,
      isFavorite: isFavorite ?? this.isFavorite,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      refreshFailed: refreshFailed ?? this.refreshFailed,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

/// 详情页控制器：**本地优先（SWR）**。
///
/// - 有缓存：立刻返回 `AsyncData`，TTL 过期才在后台刷新
/// - 无缓存：等一次网络，写入缓存后返回
/// - 刷新失败：保留旧值，只把 `refreshFailed` 置 true，由 UI 显示一条轻提示
@riverpod
class AnimeDetailController extends _$AnimeDetailController {
  bool _refreshing = false;

  @override
  Future<AnimeDetailState> build(int animeId) async {
    final cache = ref.read(animeCacheRepositoryProvider);

    final hit = await cache.read(animeId);
    final cachedDetails = hit?.details;
    if (hit != null && cachedDetails != null) {
      // 过期、或缺角色列表（卡片只做了轻量补全）→ 后台补一次
      if (cache.isStale(hit.fetchedAt) || !hit.hasCharacters) {
        unawaited(_refresh());
      }
      return _stateOf(hit, cachedDetails);
    }

    final fresh = await cache.load(animeId);
    final details = fresh.details;
    if (details == null) {
      throw Exception('加载动漫详情失败（animeId: $animeId），请检查网络后重试');
    }
    return _stateOf(fresh, details);
  }

  AnimeDetailState _stateOf(DetailSnapshot snapshot, AnimeDetails details) {
    return AnimeDetailState(
      animeDetails: details,
      bannerImage: snapshot.extras.bannerImage,
      trailerVideos: snapshot.trailers,
      characters: snapshot.parsedCharacters,
      isFavorite: ref.read(favoriteRepositoryProvider).isFavorite(animeId),
      fetchedAt: snapshot.fetchedAt,
      refreshing: _refreshing,
    );
  }

  /// 手动重试 / 下拉刷新
  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(refreshing: true, refreshFailed: false));
    }
    try {
      final snapshot = await ref
          .read(animeCacheRepositoryProvider)
          .refresh(animeId);
      final details = snapshot.details;
      if (details == null) throw Exception('详情为空');
      if (!ref.mounted) return;
      state = AsyncData(_stateOf(snapshot, details));
    } catch (_) {
      if (!ref.mounted) return;
      final old = state.value;
      if (old != null) {
        // 关键：旧数据继续用，只标记失败
        state = AsyncData(
          old.copyWith(refreshing: false, refreshFailed: true),
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite() async {
    final favoriteRepository = ref.read(favoriteRepositoryProvider);
    await favoriteRepository.toggleFavorite(Anime(bangumiId: animeId));
    if (!ref.mounted) return;
    state = AsyncData(
      state.value!.copyWith(isFavorite: favoriteRepository.isFavorite(animeId)),
    );
  }
}
