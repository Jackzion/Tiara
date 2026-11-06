import 'package:flutter_test/flutter_test.dart';
import 'package:movies/data/api/anilist_api_service.dart';

/// 临时冒烟测试：验证 TimingInterceptor 能打印请求耗时
/// 跑完即可删除：flutter test test/timing_interceptor_smoke_test.dart
void main() {
  test('AniList searchMedia 触发计时拦截器', () async {
    final service = AniListApiService();
    final response = await service.searchMedia('葬送のフリーレン');
    // ignore: avoid_print
    print('status=${response.statusCode}');
    expect(response.statusCode, 200);
  }, timeout: const Timeout(Duration(seconds: 40)));
}
