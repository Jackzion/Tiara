import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:movies/data/database/models/rules_model.dart';
import 'package:movies/data/models/source_rule.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

/// 默认 UA：规则里 userAgent 为空时用
const String _defaultUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/120.0.0.0 Safari/537.36';

/// 规则引擎：SourceRule + URL/关键词 → 搜索结果 / 线路分集
///
/// 无状态：每次请求新建/复用内部 Dio，不缓存 HTML。
/// 并发：多个 RuleEngine 方法可同时调用（各是独立 HTTP 请求）；
/// 调用方若要取消，传 dio.CancelToken。
class RuleEngine {
  /// 独立 Dio：不走 BangumiApiService 的 baseUrl/节流
  final Dio _dio;

  RuleEngine({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              // 跟随重定向一般没问题
              followRedirects: true,
              maxRedirects: 5,
            ),
          );

  // ---------------------------------------------------------------------------
  // 对外 API
  // ---------------------------------------------------------------------------
  /// 用规则搜索番剧，返回详情页列表。
  ///
  /// - [keyword] 关键词（番剧中/日名）
  /// - 抛 [NoResultException] 页面能打开但 XPath 无命中
  /// - 抛 [RuleEngineException] 网络失败 / 非 HTML / 结构解析崩溃
  Future<List<SearchItem>> search(
    SourceRule rule,
    String keyword, {
    CancelToken? cancelToken,
  }) async {
    final raw = await _fetchSearchHtml(rule, keyword, cancelToken: cancelToken);
    return parseSearchHtml(rule, raw);
  }

  /// 打开详情页，解析线路 + 分集页 URL。
  ///
  /// - [detailUrl] 必须是绝对 URL（一般来自 SearchItem.src）
  /// - 抛 [ChapterEmptyException] 能打开页面但没有任何分集
  Future<List<Road>> queryChapters(
    SourceRule rule,
    String detailUrl, {
    CancelToken? cancelToken,
  }) async {
    final url = normalizeUrl(rule.baseUrl, detailUrl);
    // 加载详情页
    final raw = await _fetchHtml(url, rule: rule, cancelToken: cancelToken);
    final roads = parseChaptersHtml(rule, raw);
    if (roads.isEmpty) {
      throw const ChapterEmptyException();
    }
    return roads;
  }

  // ---------------------------------------------------------------------------
  // HTTP
  // ---------------------------------------------------------------------------

  /// 根据 [rule] 和 [keyword] 发送 HTTP 搜索请求，返回 HTML 字符串。
  Future<String> _fetchSearchHtml(
    SourceRule rule,
    String keyword, {
    CancelToken? cancelToken,
  }) async {
    // url 编码 query 关键词
    final encoded = Uri.encodeQueryComponent(keyword.trim());
    // rule.searchUrl + keyword 拼接 searchUrl
    final searchUrl = rule.searchURL.replaceAll('@keyword', encoded);

    if (!rule.usePost) {
      return _fetchHtml(searchUrl, rule: rule, cancelToken: cancelToken);
    }

    // POST：把 query 参数拆出来当 form body（对齐 Kazumi XPath 策略）
    final uri = Uri.parse(searchUrl);
    try {
      final response = await _dio.post<dynamic>(
        // 去掉 query 参数
        uri.replace(query: null).toString(),
        data: uri.queryParameters,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: _headers(rule),
        ),
        cancelToken: cancelToken,
      );
      return _responseToString(response);
    } on DioException catch (e) {
      throw RuleEngineException('搜索请求失败: $searchUrl', cause: e);
    }
  }

  /// 根据 [rule] 和 [url] 发送 HTTP 请求，返回 HTML 字符串。
  Future<String> _fetchHtml(
    String url, {
    required SourceRule rule,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: _headers(rule),
        ),
        cancelToken: cancelToken,
      );
      return _responseToString(response);
    } on DioException catch (e) {
      throw RuleEngineException('页面请求失败: $url', cause: e);
    }
  }

  /// 根据 [rule] 生成 HTTP 请求头。
  Map<String, String> _headers(SourceRule rule) {
    return {
      // User-Agent 代表浏览器类型，服务器根据 User-Agent 判断是否需要压缩响应
      'User-Agent': rule.userAgent.trim().isEmpty
          ? _defaultUserAgent
          : rule.userAgent,
      // 防盗链
      'Referer': rule.baseUrl,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    };
  }

  /// 根据 [response] 转换为 HTML 字符串。
  String _responseToString(Response<dynamic> response) {
    final data = response.data;
    if (data is String) return data;
    if (data is List<int>) return String.fromCharCodes(data);
    return data?.toString() ?? '';
  }

  // ---------------------------------------------------------------------------
  // HTML 解析（纯函数：方便以后单测 / 用本地 HTML 夹具）
  // ---------------------------------------------------------------------------

  /// 根据 [raw] HTML String 解析为 DOM 文档。
  Element _document(String raw) {
    if (raw.trim().isEmpty) {
      throw const RuleEngineException('页面内容为空');
    }

    // html 包对坏 HTML 很宽容；一般不会抛
    return html_parser.parse(raw).documentElement!;
  }

  /// 解析搜索结果 HTML → SearchItems
  Future<List<SearchItem>> parseSearchHtml(SourceRule rule, String raw) async {
    final root = _document(raw);
    // 根据 rule.searchList 语义规则（//div[2]/text()）搜索结果列表的 nodelist
    final listNodes = root.queryXPath(rule.searchList).nodes;

    final items = <SearchItem>[];
    // 找出所有搜索结果卡片的 name 和 href 属性
    for (var i = 0; i < listNodes.length; i++) {
      final node = listNodes[i];
      final name = node.queryXPath(rule.searchName).node?.text?.trim() ?? '';
      final href =
          node.queryXPath(rule.searchResult).node?.attributes['href']?.trim() ??
          '';

      if (name.isEmpty || href.isEmpty) {
        continue; // 站点常混广告卡、空行。一张卡缺 title/href 就跳过；全部为空才 NoResultException。
      }
      items.add(SearchItem(name: name, src: normalizeUrl(rule.baseUrl, href)));
    }
    if (items.isEmpty) {
      throw const NoResultException();
    }
    return items;
  }

  /// 解析详情页 HTML → Roads
  List<Road> parseChaptersHtml(SourceRule rule, String raw) {
    // 解析 HTML 到 DOM 文档
    final root = _document(raw);
    // 根据 rule.chapterRoads 语义规则（//div[@class='chapterRoads']）播放线路列表的 nodelist
    final roadNodes = root.queryXPath(rule.chapterRoads).nodes;

    final roads = <Road>[];
    // 遍历所有播放线路卡片
    for (var roadIndex = 0; roadIndex < roadNodes.length; roadIndex++) {
      final roadNode = roadNodes[roadIndex];
      // 根据 rule.chapterResult 语义规则（//a[@href]）播放集数列表的 nodelist
      final episodeNodes = roadNode.queryXPath(rule.chapterResult).nodes;

      final urls = <String>[];
      final names = <String>[];
      // 遍历所有播放集数卡片 - 提取 href 和 name 属性
      for (var ep = 0; ep < episodeNodes.length; ep++) {
        final episodeNode = episodeNodes[ep];
        final href = episodeNode.attributes['href']?.trim() ?? '';
        if (href.isEmpty) continue;
        urls.add(normalizeUrl(rule.baseUrl, href));
        final label = (episodeNode.text ?? '').replaceAll(RegExp(r'\s+'), '');
        names.add(label.isEmpty ? '第${ep + 1}集' : label);
      }
      // 空线路丢掉
      if (urls.isEmpty) continue;
      roads.add(
        Road(name: '播放线路${roadIndex + 1}', data: urls, identifier: names),
      );
    }
    return roads;
  }

  /// 把可能相对的 [href] 拼成绝对 URL。
  ///
  /// 规则：[base] 为站点根，例如 `https://www.agedm.io/`
  /// - href 已是 http(s) → 原样返回
  /// - href 以 `/` 开头 → 拼 host + path
  /// - 否则 → 拼 base（保证以 `/` 结尾）+ href
  String normalizeUrl(String base, String href) {
    final h = href.trim();
    if (h.isEmpty) return h;
    if (h.startsWith('http://') || h.startsWith('https://')) {
      return h;
    }

    final baseUri = Uri.parse(base);
    if (h.startsWith('//')) {
      // 协议相对：//cdn.example.com/x
      return '${baseUri.scheme}:$h';
    }
    if (h.startsWith('/')) {
      return Uri.parse('${baseUri.scheme}://${baseUri.host}$h').toString();
    }

    // 相对路径：base 若没有尾斜杠则补上
    var prefix = base;
    if (!prefix.endsWith('/')) {
      prefix = '$prefix/';
    }
    return Uri.parse(prefix).resolveUri(Uri.parse(h)).toString();
  }
}
