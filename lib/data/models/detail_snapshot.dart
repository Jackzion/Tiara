import 'dart:convert';

import 'package:movies/data/database/models/cached_subject.dart';
import 'package:movies/data/models/anime_character.dart';
import 'package:movies/data/models/anime_details.dart';
import 'package:movies/data/models/anime_extras.dart';
import 'package:movies/data/models/anime_trailer.dart';

/// 详情页快照：**主体存原始 API JSON**，读取时再用现有 fromJson 解析。
///
/// 为什么不给每个模型写 toJson：bangumi / AniList 的字段会变，存原始响应
/// 既不会漏字段，也不需要维护第二套序列化代码；解析失败时整份快照按未命中处理。
class DetailSnapshot {
  const DetailSnapshot({
    required this.bangumiId,
    required this.fetchedAt,
    this.subject,
    this.extras = const AnimeExtras(),
    this.characters,
  });

  /// payload 结构版本；不匹配就当作没有缓存，重新拉。
  static const version = 1;

  final int bangumiId;

  /// bangumi `/v0/subjects/{id}` 的原始响应
  final Map<String, dynamic>? subject;

  /// AniList 补充数据（横幅 / PV）
  final AnimeExtras extras;

  /// bangumi `/v0/subjects/{id}/characters` 的原始列表。
  /// null = 还没拉过（列表卡片补全时只取横幅/简介，避免多打一次请求）
  final List<dynamic>? characters;

  final DateTime fetchedAt;

  AnimeDetails? get details {
    final raw = subject;
    if (raw == null) return null;
    try {
      return AnimeDetails.fromBangumi(raw);
    } catch (_) {
      return null;
    }
  }

  bool get hasCharacters => characters != null;

  List<AnimeCharacter> get parsedCharacters {
    final result = <AnimeCharacter>[];
    for (final item in characters ?? const []) {
      if (item is! Map) continue;
      try {
        result.add(AnimeCharacter.fromBangumi(Map<String, dynamic>.from(item)));
      } catch (_) {
        // 单条坏数据不影响整页
      }
    }
    return result;
  }

  /// PV 由 extras 推导，不单独存（与原先 getAnimeTrailers 的语义一致）
  List<AnimeTrailer> get trailers {
    final videoId = extras.youtubeId;
    if (videoId == null || videoId.isEmpty) return const [];
    return [
      AnimeTrailer(
        title: 'PV',
        youtubeId: videoId,
        site: extras.trailerSite,
        imageUrl: extras.trailerThumbnail,
      ),
    ];
  }

  String toPayload() => jsonEncode({
    'v': version,
    'subject': subject,
    'extras': extras.toJson(),
    // null 表示"未拉取"，与"拉取到空列表"区分开
    if (characters != null) 'characters': characters,
  });

  static DetailSnapshot? fromCached(CachedSubject row) {
    try {
      final decoded = jsonDecode(row.payload);
      if (decoded is! Map) return null;
      final payload = Map<String, dynamic>.from(decoded);
      if (payload['v'] != version) return null;
      final extrasRaw = payload['extras'];
      return DetailSnapshot(
        bangumiId: row.bangumiId,
        subject: (payload['subject'] as Map?)?.cast<String, dynamic>(),
        extras: extrasRaw is Map
            ? AnimeExtras.fromJson(Map<String, dynamic>.from(extrasRaw))
            : const AnimeExtras(),
        characters: payload['characters'] is List
            ? payload['characters'] as List
            : null,
        fetchedAt: row.fetchedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
