import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/data/database/models/rules_model.dart';
import 'package:movies/data/models/play_context.dart';
import 'package:movies/data/models/source_rule.dart';
import 'package:movies/network/rule_engine.dart';
import 'package:movies/providers.dart';
import 'package:movies/services/video_source/video_source.dart';
import 'package:movies/services/video_source/webview_video_source_service.dart';
import 'package:movies/services/video_source/youtube_stream_service.dart';
import 'package:movies/ui/screens/source_sheet/source_import_dialog.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/system_proxy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:movies/utils/utils.dart';

/// 视频播放页面
/// 使用 media_kit 播放预告片视频，支持播放控制
@RoutePage(name: 'VideoPageRoute')
class VideoPage extends ConsumerStatefulWidget {
  /// 视频 ID 或播放地址
  final String animeVideo;

  /// 视频播放上下文
  final PlayContext? playContext;

  const VideoPage(this.animeVideo, this.playContext, {super.key});
  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  late final Player player;
  late final VideoController controller;

  /// YouTube PV 取流（youtube_explode）
  final YoutubeStreamService _youtubeService = YoutubeStreamService();

  /// 缓存服务，dispose 里不要再碰 ref
  WebviewVideoSourceService? _webviewService;

  /// 当前线路下标（playroads 的 index）
  int _roadIndex = 0;

  /// 当前集下标（roads[_roadIndex].data 的 index，0-based）
  int _episodeIndex = 0;

  /// 正在解析 / 开播
  bool _resolving = false;

  /// 底部/侧栏错误提示（null = 无）
  String? _playError;

  /// 是否正片模式（有 playContext 且 rule 不为 null）
  bool get _isOnlinePlay => widget.playContext?.rule != null;

  /// 浏览器打开番剧站某一集的播放页，复制地址栏整段 URL 粘到这里。
  /// 注意：必须是「分集播放页」，不是首页/详情页。
  static const String _testPageUrl = 'https://www.agedm.io/play/20260322/2/1';

  /// 解析中标志：避免连点，也方便看按钮状态
  bool _parsing = false;

  /// Phase 3 调试：规则引擎测试中
  bool _ruleTesting = false;

  @override
  void initState() {
    super.initState();
    // 直接用 media_kit,Windows desktop 上最稳的视频方案
    // (pod_player 就是包了一层 media_kit,直接用更可控)
    player = Player();
    controller = VideoController(player);

    // 接住播放错误,避免卡死 UI
    player.stream.error.listen((String error) {
      debugPrint('Player error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('视频错误: $error')));
      }
    });

    final play = widget.playContext;
    if (_isOnlinePlay) {
      final indices = play?.resolveStartIndices();
      if (indices != null) {
        _roadIndex = indices.$1;
        _episodeIndex = indices.$2;
      }
      // 首帧后再开播，避免 initState 里 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_playEpisode());
      });
    } else {
      // 预告 / PV：youtube_explode 取流 → media_kit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_playTrailer());
      });
    }
  }

  @override
  void dispose() {
    // 离开播放页：作废在途取流，避免后台继续写状态
    // 注意：dispose 时 widget 已 deactivate，不能用 ref
    _webviewService?.cancel();
    player.dispose();
    super.dispose();
  }

  /// 预告片：YouTube videoId → 直链 → media_kit
  Future<void> _playTrailer() async {
    final idOrUrl = widget.animeVideo.isNotEmpty
        ? widget.animeVideo
        : (widget.playContext?.detailUrl ?? '');
    if (idOrUrl.isEmpty) {
      setState(() => _playError = '缺少预告片视频 ID');
      return;
    }

    setState(() {
      _resolving = true;
      _playError = null;
    });

    try {
      final source = await _youtubeService.resolve(idOrUrl);
      debugPrint('[Play] trailer resolved => ${source.url}');
      if (!mounted) return;

      // 直链签名绑出口 IP：mpv 与解析走同一系统代理
      final proxy = SystemProxy.resolveMpvHttpProxy();
      if (proxy != null) {
        try {
          final native = player.platform;
          if (native is NativePlayer) {
            await native.setProperty('http-proxy', proxy);
          }
        } catch (e) {
          debugPrint('[Play] set http-proxy failed: $e');
        }
      }

      await player.open(
        Media(source.url, httpHeaders: YoutubeStreamService.playbackHeaders),
        play: true,
      );
      if (!mounted) return;
      setState(() => _resolving = false);
    } catch (e) {
      debugPrint('[Play] trailer failed: $e');
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _playError = '预告片解析失败：$e';
      });
    }
  }

  /// ===== Phase 1 临时调试：无头 WebView 取流 =====
  /// 点击后：分集页 URL → HeadlessWebview 钓 m3u8/mp4 → 控制台打印直链
  Future<void> _debugParseVideoSource() async {
    if (_parsing) return;
    setState(() => _parsing = true);

    // SnackBar 的 context 在 await 之后可能失效，先把 messenger 拿在手里
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('开始解析（最多等 10 秒）…')));

    try {
      final service = ref.read(webviewVideoSourceServiceProvider);
      final source = await service.parseVideoSource(_testPageUrl);

      // 成功：直链打到 Debug Console / 终端
      debugPrint('[Phase1] resolved => ${source.url} (${source.format})');
      messenger.showSnackBar(
        const SnackBar(content: Text('拿到直链！详见 Run/Debug Console')),
      );

      // 可选：解析成功后直接丢给 media_kit 试播
      // （确认直链能播的话，把下面注释去掉）
      player.open(Media(source.url));
    } on VideoSourceTimeoutException catch (e) {
      // 超时：用户可感知的失败
      debugPrint('[Phase1] timeout: $e');
      messenger.showSnackBar(SnackBar(content: Text('解析超时：$e')));
    } on VideoSourceCanceledException {
      // 被取消（连点/换任务）：静默，不打扰用户
      debugPrint('[Phase1] cancelled (正常)');
    } catch (e) {
      // 其它错误：站点改版、网络失败、WebView 未就绪等
      debugPrint('[Phase1] error: $e');
      messenger.showSnackBar(SnackBar(content: Text('解析失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _parsing = false);
      }
    }
  }

  /// ===== Phase 3 临时调试：RuleEngine 搜索 + 分集 =====
  /// Phase 2 已能导入规则：优先从仓库读；空则引导导入。
  Future<void> _debugRuleEngine() async {
    if (_ruleTesting || _parsing) return;
    setState(() => _ruleTesting = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Phase3：从仓库读规则并搜索…')));

    try {
      final repo = await ref.read(rulesRepositoryProvider.future);
      final rules = repo.getAll();
      debugPrint('[Phase3] 已导入规则 ${rules.length} 条');

      if (rules.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('还没有规则：先 ⋮ → Sources → Import')),
        );
        // 空库时直接弹导入框，方便验收
        if (mounted) {
          await showSourceImportDialog(context);
        }
        return;
      }

      // 默认用第一条；也可改成 repo.getByName('7sefun')
      final SourceRule rule = rules.first;
      const keyword = '葬送的芙莉莲';
      debugPrint('[Phase3] 使用规则 ${rule.name}  搜索「$keyword」');

      final engine = RuleEngine();

      // ① 搜索
      final items = await engine.search(rule, keyword);
      debugPrint('[Phase3] 搜索命中 ${items.length} 条');
      for (final item in items.take(5)) {
        debugPrint('[Phase3]   - ${item.name} => ${item.src}');
      }

      // ② 对第一条拉线路/分集
      final roads = await engine.queryChapters(rule, items.first.src);
      debugPrint('[Phase3] 线路 ${roads.length} 条');
      for (final road in roads) {
        debugPrint('[Phase3]   ${road.name}: ${road.episodeCount} 集');
        if (road.data.isNotEmpty) {
          debugPrint(
            '[Phase3]     首集 ${road.identifier.first} ${road.data.first}',
          );
        }
      }

      // ③ 可选联调：把首集分集页丢给 Phase 1 无头取流
      String? probePage;
      if (roads.isNotEmpty && roads.first.data.isNotEmpty) {
        probePage = roads.first.data.first;
        debugPrint('[Phase3→1] 试解析分集页 $probePage');
        try {
          final source = await ref
              .read(webviewVideoSourceServiceProvider)
              .parseVideoSource(probePage);
          debugPrint('[Phase3→1] resolved => ${source.url} (${source.format})');
          // 拿到直链就试播（验证整条链路）
          await player.open(Media(source.url));
        } on VideoSourceTimeoutException {
          debugPrint('[Phase3→1] 取流超时（分集页可能改版/需登录）');
        } on VideoSourceCanceledException {
          debugPrint('[Phase3→1] 取流取消');
        } catch (e) {
          debugPrint('[Phase3→1] 取流失败: $e');
        }
      }

      if (!mounted) return;
      final buf = StringBuffer('规则 ${rule.name}：搜索 ${items.length} 条');
      if (roads.isNotEmpty) {
        buf.write('，线路 ${roads.length} / 首线路 ${roads.first.episodeCount} 集');
      }
      if (probePage != null) {
        buf.write('；已尝试取流');
      }
      messenger.showSnackBar(SnackBar(content: Text(buf.toString())));
    } on NoResultException catch (e) {
      debugPrint('[Phase3] NoResult: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('无结果：$e')));
      }
    } on ChapterEmptyException catch (e) {
      debugPrint('[Phase3] ChapterEmpty: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('无分集：$e')));
      }
    } on RuleEngineException catch (e) {
      debugPrint('[Phase3] EngineError: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('引擎错误：$e')));
      }
    } catch (e) {
      debugPrint('[Phase3] error: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _ruleTesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final play = widget.playContext;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: screenBackground,
        leading: BackButton(
          onPressed: () => context.router.maybePop(),
        ),
        centerTitle: false,
        title: Text(
          play?.title ?? 'Back',
          style: Theme.of(context).textTheme.headlineMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: play?.rule == null
          ? _buildTrailerBody()
          : _buildOnlineBody(play!),
    );
  }

  Widget _buildOnlineBody(PlayContext play) {
    return Container(
      color: screenBackground,
      width: double.infinity,
      height: double.infinity,
      child: Row(
        children: [
          // 左：播放器
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  // 视频渲染区:Video widget + VideoController
                  child: Video(
                    controller: controller,
                    fit: BoxFit.contain,
                    controls: (VideoState state) {
                      return MaterialVideoControls(state);
                    },
                  ),
                ),
                if (_resolving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          addVerticalSpace(12),
                          Text('正在解析视频源…', style: body2Regular.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                if (_playError != null && !_resolving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black87,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _playError!,
                              textAlign: TextAlign.center,
                              style: body2Regular.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            addVerticalSpace(16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 重试
                                ElevatedButton(
                                  onPressed: _playEpisode,
                                  child: const Text('重试'),
                                ),
                                addHorizontalSpace(12),
                                // 换线路
                                OutlinedButton(
                                  onPressed: () {
                                    // 换下一条线路的第一集
                                    if (play.roads.length <= 1) return;
                                    final next =
                                        (_roadIndex + 1) % play.roads.length;
                                    _changeEpisode(next, 0);
                                  },
                                  child: const Text('换线路'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 右：线路 + 分集
          SizedBox(width: 240, child: _buildEpisodePanel(play)),
        ],
      ),
    );
  }

  Widget _buildEpisodePanel(PlayContext play) {
    return Container(
      color: searchBarBackground,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('线路', style: body2Bold),
          addVerticalSpace(8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < play.roads.length; i++)
                ChoiceChip(
                  label: Text(play.roads[i].name),
                  selected: i == _roadIndex,
                  onSelected: (_) => _changeEpisode(i, 0),
                ),
            ],
          ),
          addVerticalSpace(12),
          Text('分集', style: body2Bold),
          addVerticalSpace(8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.6,
              ),
              itemCount: play.roads[_roadIndex].data.length,
              itemBuilder: (context, i) {
                final selected = i == _episodeIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _changeEpisode(_roadIndex, i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? accentAmber
                          : buttonGrey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _episodeDisplayName(play, _roadIndex, i),
                      style: body3Regular.copyWith(
                        color: selected ? onAccent : ArchivePalette.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 预告 trailer 视频渲染区
  Widget _buildTrailerBody() {
    return Container(
      color: screenBackground,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: controller,
            fit: BoxFit.contain,
            controls: (VideoState state) => MaterialVideoControls(state),
          ),
          if (_resolving)
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    addVerticalSpace(12),
                    Text('正在解析预告片…', style: body2Regular.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          if (_playError != null && !_resolving)
            ColoredBox(
              color: Colors.black87,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _playError!,
                        style: body2Regular.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      addVerticalSpace(16),
                      FilledButton(
                        onPressed: () => unawaited(_playTrailer()),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  /// 解析并播放当前 (_roadIndex, _episodeIndex) -> sourceurl -> media_kit 开流
  Future<void> _playEpisode() async {
    // 验证 playContext 是否存在
    if (widget.playContext == null) return;
    final play = widget.playContext!;

    // 验证 playContext 数据是否齐全
    if (play.roads.isEmpty ||
        _roadIndex >= play.roads.length ||
        play.roads[_roadIndex].data.isEmpty ||
        _episodeIndex >= play.roads[_roadIndex].data.length) {
      setState(() => _playError = '集数解析失败');
      return;
    }

    final service = ref.read(webviewVideoSourceServiceProvider);
    _webviewService = service;

    // 作废上一次解析；
    service.cancel();
    // 停掉上一个媒体
    await player.stop();

    final pageUrl = play.episodePageUrl(_roadIndex, _episodeIndex);
    final episodeLabel = _episodeDisplayName(play, _roadIndex, _episodeIndex);

    debugPrint('[Play] 解析 $episodeLabel → $pageUrl');

    // 开始解析
    setState(() {
      _resolving = true;
      _playError = null;
    });

    try {
      // 无头 WebView 钓直链
      final source = await service.parseVideoSource(pageUrl);
      debugPrint('[Play] resolved => ${source.url} (${source.format})');

      // 判断组件是否已销毁
      if (!mounted) return;

      // 组装请求头（规则 UA / Referer）
      final headers = _buildHttpHeaders(play);

      // if (source.format == VideoSourceFormat.hls) {
      //   try {
      //     await player.platform?.setProperty('demuxer-lavf-format', 'hls');
      //   } catch (e) {
      //     debugPrint('[Play] set demuxer-lavf-format failed: $e');
      //   }
      // }

      // media_kit 开流
      await player.open(Media(source.url, httpHeaders: headers), play: true);
      if (!mounted) return;

      setState(() => _resolving = false);
    } on VideoSourceTimeoutException {
      debugPrint('[Play] 取流超时');
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _playError = '视频解析超时，请重试或换线路';
      });
    } on VideoSourceCanceledException {
      // 换集/退出导致的主动取消：静默
      debugPrint('[Play] 取消（正常）');
      if (mounted) {
        setState(() => _resolving = false);
      }
    } catch (e) {
      debugPrint('[Play] 失败: $e');
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _playError = '视频解析失败：$e';
      });
    }
  }

  /// 规则 → 播放请求头
  Map<String, String> _buildHttpHeaders(PlayContext play) {
    const fallbackUa =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Safari/537.36';
    // 从规则中获取 UA / Referer
    final ua = play.rule?.userAgent.trim() ?? fallbackUa;
    final referer = play.rule?.referer.trim() ?? '';
    return {
      'user-agent': ua.isEmpty ? fallbackUa : ua,
      if (referer.isNotEmpty) 'referer': referer,
    };
  }

  /// 集显示名：优先 identifier，否则「第N集」
  String _episodeDisplayName(PlayContext play, int road, int ep) {
    final id = play.roads[road].identifier;
    if (ep < id.length && id[ep].isNotEmpty) return id[ep];
    return '第${ep + 1}集';
  }

  /// 用户点分集 / 换线路入口
  Future<void> _changeEpisode(int roadIndex, int episodeIndex) async {
    if (_roadIndex == roadIndex &&
        _episodeIndex == episodeIndex &&
        !_resolving) {
      return; // 点当前集 no-op
    }
    setState(() {
      _roadIndex = roadIndex;
      _episodeIndex = episodeIndex;
    });
    await _playEpisode();
  }
}
