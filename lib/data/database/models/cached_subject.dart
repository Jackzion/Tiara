/// `subject_cache` 一行：纯缓存，可随时删除。
class CachedSubject {
  const CachedSubject({
    required this.bangumiId,
    required this.payload,
    required this.fetchedAt,
  });

  final int bangumiId;
  final String payload;
  final DateTime fetchedAt;
}
