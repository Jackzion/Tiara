import 'package:movies/data/models/anime.dart';
import 'package:movies/data/models/anime_character.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/anime_extras.dart';
import 'package:movies/data/models/anime_trailer.dart';
import 'package:movies/data/repositories/anime_repository.dart';
import 'package:movies/data/repositories/favorite_repository.dart';

/// 动漫详情页控制器
/// 持有详情/预告/角色/横幅的加载结果，提供收藏操作
class AnimeDetailController {
  AnimeDetailController({
    required this.animeRepository,
    required this.favoriteRepository,
    required this.animeId,
  });

  final AnimeRepository animeRepository;
  final FavoriteRepository favoriteRepository;
  final int animeId;

  AnimeDetails? animeDetails;
  String? bannerImage;
  List<AnimeTrailer> trailerVideos = [];
  List<AnimeCharacter> characters = [];

  Future<void>? _loadFuture;

  /// 加载详情数据（记忆化：窗口缩放 / rebuild 不得重新拉接口）
  Future<void> load() {
    return _loadFuture ??= _loadData();
  }

  Future<void> _loadData() async {
    animeDetails = await animeRepository.getAnimeDetails(animeId);

    // 按 animeId 补充 bannerImage（AniList），与视频/角色并行加载
    String? nameJa;
    String? nameCn;
    final anime = animeRepository.findAnimeById(animeId);
    if (anime != null) {
      nameJa = anime.titleJapanese;
      nameCn = anime.title;
    } else {
      nameJa = animeDetails?.titleJapanese;
      nameCn = animeDetails?.title;
    }

    final results = await Future.wait([
      animeRepository.getAnimeTrailers(animeId),
      animeRepository.getAnimeCharacters(animeId),
      animeRepository.getExtras(animeId, nameJa, nameCn),
    ]);
    trailerVideos = results[0] as List<AnimeTrailer>;
    characters = results[1] as List<AnimeCharacter>;
    // 从 extras 中获取 bannerImage（可能为空）
    bannerImage = (results[2] as AnimeExtras).bannerImage;
  }

  /// 是否已收藏
  bool isFavorite() => favoriteRepository.isFavorite(animeId);

  /// 切换收藏状态
  Future<void> toggleFavorite() {
    return favoriteRepository.toggleFavorite(Anime(bangumiId: animeId));
  }
}
