import 'package:dio/dio.dart';
import 'package:movies/data/api/request_throttle.dart';
import 'package:movies/data/api/timing_interceptor.dart';

/// Bangumi API 基础地址
const String bangumiApiUrl = 'https://api.bgm.tv';

/// Bangumi API 服务
/// 提供每周放送日历、条目搜索、条目详情和角色（含声优）数据
class BangumiApiService {
  /// Dio 实例
  late final Dio dio;

  /// 请求节流器（Bangumi 有速率限制）
  final RequestThrottle throttle = RequestThrottle();

  /// 构造函数，初始化 Dio
  BangumiApiService() {
    dio = Dio(BaseOptions(
      baseUrl: bangumiApiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'movies-app/1.0',
      },
    ));

    // 计时拦截器：所有请求自动打印耗时
    dio.interceptors.add(TimingInterceptor(tag: 'Bangumi'));
  }

  /// 获取每周放送日历（按星期分组的动画条目）
  Future<Response> getCalendar() async {
    await throttle.wait();
    return dio.get('/calendar');
  }

  /// 搜索条目（type=2 固定为动画）
  /// 分页参数 limit/offset 走 URL query（放 body 会被忽略）
  /// [rankFilter] / [ratingFilter] 为 Bangumi 过滤表达式，如 ['>= 1', '<= 300']
  /// [sort] 支持 match / heat / rank
  Future<Response> searchSubjects({
    String keyword = '',
    List<String>? tags,
    List<String>? rankFilter,
    List<String>? ratingFilter,
    String? sort,
    int limit = 10,
    int offset = 0,
  }) async {
    await throttle.wait();
    final filter = <String, dynamic>{
      'type': [2],
    };
    if (tags != null && tags.isNotEmpty) {
      // Bangumi 过滤字段为单数 tag；复数 tags 会被忽略
      filter['tag'] = tags;
    }
    if (rankFilter != null && rankFilter.isNotEmpty) {
      filter['rank'] = rankFilter;
    }
    if (ratingFilter != null && ratingFilter.isNotEmpty) {
      filter['rating'] = ratingFilter;
    }
    final body = <String, dynamic>{
      'keyword': keyword,
      'filter': filter,
    };
    if (sort != null) {
      body['sort'] = sort;
    }
    // debug log
    print('searchSubjects: $body');
    return dio.post(
      '/v0/search/subjects',
      queryParameters: {'limit': limit, 'offset': offset},
      data: body,
    );
  }

  /// 获取条目详情
  Future<Response> getSubject(int id) async {
    await throttle.wait();
    return dio.get('/v0/subjects/$id');
  }

  /// 获取条目角色列表（含 CV 声优）
  Future<Response> getSubjectCharacters(int id) async {
    await throttle.wait();
    return dio.get('/v0/subjects/$id/characters');
  }
}
