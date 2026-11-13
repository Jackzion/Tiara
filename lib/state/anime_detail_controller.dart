import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_character.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/anime_trailer.dart';
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
  });

  final AnimeDetails? animeDetails;
  final String? bannerImage;
  final List<AnimeTrailer> trailerVideos;
  final List<AnimeCharacter> characters;
  final bool isFavorite;

  AnimeDetailState copyWith({
    AnimeDetails? animeDetails,
    String? bannerImage,
    List<AnimeTrailer>? trailerVideos,
    List<AnimeCharacter>? characters,
    bool? isFavorite,
  }) {
    return AnimeDetailState(
      animeDetails: animeDetails ?? this.animeDetails,
      bannerImage: bannerImage ?? this.bannerImage,
      trailerVideos: trailerVideos ?? this.trailerVideos,
      characters: characters ?? this.characters,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// 动漫详情页控制器（family: animeId，autoDispose 随页面销毁）
/// 只要还有任何一处 `ref.watch` / `ref.listen` 在监听这个 Provider → 不会销毁。
/// build 一次性加载详情/预告/角色/横幅，Riverpod 记忆化保证 rebuild 不重拉
@riverpod
class AnimeDetailController extends _$AnimeDetailController {
  @override
  Future<AnimeDetailState> build(int animeId) async {
    final animeRepository = ref.read(animeRepositoryProvider);
    final favoriteRepository = ref.read(favoriteRepositoryProvider);

    final animeDetails = await animeRepository.getAnimeDetails(animeId);

    // 详情加载失败（repository 吞掉网络异常返回 null）→ 必须抛出，
    if (animeDetails == null) {
      throw Exception('加载动漫详情失败（animeId: $animeId），请检查网络后重试');
    }

    // 按 animeId 补充 bannerImage（AniList），与视频/角色并行加载
    String? nameJa;
    String? nameCn;
    final anime = animeRepository.findAnimeById(animeId);
    if (anime != null) {
      nameJa = anime.titleJapanese;
      nameCn = anime.title;
    } else {
      nameJa = animeDetails.titleJapanese;
      nameCn = animeDetails.title;
    }

    final isBook = animeDetails.isBook;

    // 并行加载；书籍跳过 PV（AniList 是动画向，必空）。
    final trailersFuture = isBook
        ? Future.value(const <AnimeTrailer>[])
        : animeRepository.getAnimeTrailers(animeId);
    final charactersFuture = animeRepository.getAnimeCharacters(animeId);
    final extrasFuture = animeRepository.getExtras(animeId, nameJa, nameCn);

    return AnimeDetailState(
      animeDetails: animeDetails,
      trailerVideos: await trailersFuture,
      characters: await charactersFuture,
      // 从 extras 中获取 bannerImage（可能为空）
      bannerImage: (await extrasFuture).bannerImage,
      isFavorite: favoriteRepository.isFavorite(animeId),
    );
  }

  /// 切换收藏状态
  Future<void> toggleFavorite() async {
    final favoriteRepository = ref.read(favoriteRepositoryProvider);
    await favoriteRepository.toggleFavorite(Anime(bangumiId: animeId));
    if (!ref.mounted) {
      return;
    }
    // change state , ui who listens this provider will rebuild
    state = AsyncData(
      state.value!.copyWith(isFavorite: favoriteRepository.isFavorite(animeId)),
    );
  }
}
