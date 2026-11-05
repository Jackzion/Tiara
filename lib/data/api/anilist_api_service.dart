import 'package:dio/dio.dart';
import 'package:movies/data/api/request_throttle.dart';
import 'package:movies/data/api/timing_interceptor.dart';

/// AniList GraphQL API 地址
const String anilistApiUrl = 'https://graphql.anilist.co';

/// AniList GraphQL API 服务
/// 仅用于补充 Bangumi 缺失的宽幅横幅图（bannerImage）和 PV（trailer）
class AniListApiService {
  /// Dio 实例
  late final Dio dio;

  /// 请求节流器（AniList 免鉴权约 30 次/分钟）
  final RequestThrottle throttle =
      RequestThrottle(interval: const Duration(seconds: 2));

  /// 构造函数，初始化 Dio
  AniListApiService() {
    dio = Dio(BaseOptions(
      baseUrl: anilistApiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    // 计时拦截器：所有请求自动打印耗时
    dio.interceptors.add(TimingInterceptor(tag: 'AniList'));
  }

  /// 查询字段：ID 映射、宽幅横幅、PV
  static const String searchQuery = r'''
query ($search: String) {
  Media(search: $search, type: ANIME) {
    id
    idMal
    bannerImage
    trailer {
      id
      site
      thumbnail
    }
  }
}
''';

  /// 按标题搜索动画（优先用日文原名），返回横幅与 PV 信息
  Future<Response> searchMedia(String search) async {
    await throttle.wait();
    return dio.post('', data: {
      'query': searchQuery,
      'variables': {'search': search},
    });
  }
}
