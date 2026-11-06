# 项目结构优化方案

> 诊断范围：`lib/`（约 70 个 dart 文件，不含 `.g.dart`）。
> 结论先行：**分层边界模糊 + 一个上帝对象（AnimeViewModel）+ 跨屏通信靠全局可变状态**，是当前混乱的三个根源。缓存、性能、内存问题都是这三个根源的下游症状。
> 本方案按「收益/风险比」排序，每项独立可落地，可分批做也可只挑几项做。

---

## 一、现状诊断

### 1.1 依赖现状（实测）

```
UI (screens/widgets)
  ├─→ lib/ui/anime_viewmodel.dart   ← 534 行，被 widgets 直接依赖
  ├─→ lib/providers.dart            ← 根目录一个文件，混装所有 provider
  ├─→ lib/data/models/              ← 手写解析 + 少量 json_serializable
  └─→ lib/data/database/…           ← drift + SharedPreferences 混用
```

### 1.2 三个根源问题

| # | 问题 | 证据 | 后果 |
|---|------|------|------|
| A | **AnimeViewModel 是上帝对象** | `ui/anime_viewmodel.dart` 534 行：API 调用 + JSON 解析（`_parseSearchResults`）+ 5 个无界缓存 Map + 收藏 CRUD + 类型初始化 + 页面状态字段（`trendingAnimes` 等公开可变 List）+ AniList 搜索，全在一个类里 | 任何改动都碰它；无法单测；`anime_widget.dart`、`favorite_row.dart` 等 UI 直接 import 它 |
| B | **分层/归类混乱** | `anime_viewmodel` 放在 `ui/` 下但干的是 data 层的活；`data/database/models/rules_model.dart` 里放的是 `SearchItem`/`Road`/异常类（规则引擎领域模型，与数据库无关）；`utils/utils.dart` 是杂物袋（typedef + Sorting 枚举 + 工具函数）；`network/` 里 `rule_engine.dart`（HTML 抓取）和 `bangumi_api_service.dart`（REST 客户端）是两种东西 | 找文件靠猜；新人无法建立心智模型 |
| C | **跨屏通信靠全局可变状态** | 根级 `searchTextProvider`/`searchTagProvider`/`currentNavIndexProvider` 被当事件总线用（详情页点标签 → 写 provider → Genre 页 watch）；`genre_screen.dart:257` 有一个全局 `ValueNotifier`（`expandedNotifier`）；`GlobalSearchController` 又是 ChangeNotifier | rebuild 时机不可控，出现过「build 期间改 `widget.genreStates`」「watch 触发 rebuild 但没触发 search」这类 bug（就是你前面问的问题） |

### 1.3 下游症状（前面聊过的）

- **首页慢 2-3s**：4 个请求被 `RequestThrottle`（1s 间隔）串行化；`animeFuture` 只是 widget 级 memo，无持久缓存
- **内存 1GB**：`_detailsCache`/`_subjectCache`/`_trailerCache`/`_characterCache`/`extrasCache` 全部无上限、无淘汰；`extrasCache` 每次保存整体重写 SharedPreferences 大 JSON；图片解码无 `memCacheWidth` 控制
- **解析代码重复**：`_parseDate/_parseInt/_parseDouble` 在 `anime.dart` 和 `anime_details.dart` 各写一份；json_serializable 只用于 `Genre` 一个模型
- **大文件**：`video_page.dart` 606 行、`anime_viewmodel.dart` 534、`home_screen_image.dart` 426、`anime_widget.dart` 389

---

## 二、优化项清单（按优先级）

### P0 — 值得做，收益大、风险可控

#### P0-1 拆解 AnimeViewModel（核心）

**现状**：一个类 = API client + parser + cache + repository + 页面 state。
**目标**：拆成四块，各自可测：

```
lib/
  data/
    api/            bangumi_api_service.dart, anilist_api_service.dart
    parsing/        search_result_parser.dart（搬 _parseSearchResults）
                    anime_json.dart（合并两份 _parseDate/_parseInt/_parseDouble）
    repositories/   anime_repository.dart（取数 + 缓存编排）
                    favorite_repository.dart（收藏 CRUD）
                    rules_repository.dart（已有，移过来）
  state/            home_controller.dart（trending/popular/topRated/nowPlaying）
                    …（按屏拆，用 Riverpod AsyncNotifier）
```

- `AnimeRepository` 只做「取数 + 缓存命中/回填」，返回模型，不持页面状态
- `trendingAnimes` 等公开可变 List 移入 `HomeScreen` 自己的 controller
- UI 只依赖 repository/controller，不再 import 上帝对象

**工作量**：中（1-2 个工作日）　**风险**：中（触点多，但每步可编译验证）

#### P0-2 缓存体系统一

**现状**：5 个无界 Map + SharedPreferences 大 JSON 整体重写。
**目标**：

1. 引入一个通用 `TtlCache<K, V>`（LRU + TTL），替换 5 个裸 Map —— 20 行代码的事
2. 首页四列表落盘缓存（drift 新表或独立 JSON 文件，按 key 分文件避免整体重写），策略 stale-while-revalidate：先展示旧数据 → 后台刷新
3. `extrasCache` 从「整包 JSON」改为按 id 分 key 存储或入 drift

**工作量**：小-中（半天-1 天）　**风险**：低　**直接解决**：首页 2-3s、内存 1GB

#### P0-3 跨屏通信改为显式契约

**现状**：详情页 → 写全局 provider → Genre 页 watch 并在 build 里做副作用。
**目标**：

1. 消灭 `expandedNotifier` 这类全局 `ValueNotifier`，状态归 `GenreScreen` 自己
2. `searchTextProvider`/`searchTagProvider` 的「事件」语义改为「状态」语义：Genre 页用 `ref.listen`（而非 build 里的 `ref.watch` 做副作用）响应变化后触发 search
3. build 方法保持纯净：不在 build 里 `widget.genreStates.add(...)`（这是你之前遇到的 rebuild 不触发 search 的根源之一）

**工作量**：小（半天）　**风险**：低　**直接解决**：rebuild/search 不同步那类 bug

### P1 — 建议做，改善可维护性

#### P1-1 目录归位（纯移动，不改逻辑）

| 移动 | 从 | 到 | 理由 |
|------|----|----|------|
| `rules_model.dart`（SearchItem/Road/异常） | `data/database/models/` | `network/` 或 `domain/` | 它是规则引擎的领域模型，不是数据库模型 |
| `anime_viewmodel.dart` 拆完后的残余 | `ui/` | `data/` / `state/` | 见 P0-1 |
| `utils.dart` 拆开 | `utils/utils.dart` | `utils/typedefs.dart` + `data/models/sorting.dart` + `utils/helpers.dart` | 杂物袋拆分 |
| `rule_engine.dart` | `network/` | `services/rule_engine/` | 它是 HTML 抓取引擎，不是 REST client |

**工作量**：小（2-3 小时，IDE 移动 + 修 import）　**风险**：低

#### P1-2 模型解析统一

- 合并 `anime.dart` / `anime_details.dart` 里重复的 `_parseDate/_parseInt/_parseDouble` 到一个 `json_parsing.dart`
- 全部模型走 json_serializable（或全部手写，二选一，不要混）；`Anime.fromSearchJson` 这类 API 专用工厂保留

**工作量**：小-中（半天）　**风险**：低（有 `models_test.dart` 兜底）

#### P1-3 providers.dart 拆分

根目录 `providers.dart` 混装：SharedPreferences、DB、两个 API service、RuleEngine、Webview 服务、UI 状态 provider。
按层拆到各层自己的 `providers.dart`（`data/providers.dart`、`state/providers.dart`…），根文件只做 export 或直接删除。

**工作量**：小（2 小时）　**风险**：低（`.g.dart` 需重跑 build_runner）

### P2 — 锦上添花，时间富余再做

| 项 | 说明 | 工作量 |
|----|------|--------|
| P2-1 拆大文件 | `video_page.dart`(606) / `home_screen_image.dart`(426) / `anime_widget.dart`(389) 按职责拆子组件 | 中 |
| P2-2 图片内存 | `CachedNetworkImage` 加 `memCacheWidth`（列表缩略图解码成原图是内存大头之一） | 小 |
| P2-3 请求层 | `RequestThrottle` 串行导致首页 2-3s；首页 4 个请求可放行并行（限流只为防封禁，可以批量窗口化而非严格串行） | 小 |
| P2-4 测试补强 | repository + parser 层补单测（拆完 P0-1 后才值得做） | 中 |

---

## 三、不建议做的事

- **不要上 Clean Architecture / usecase 层**：项目规模不到，加一层纯仪式感
- **不要换状态管理**：Riverpod 用得没问题，问题在用法（build 里做副作用、事件当状态用），换库解决不了
- **不要一步到位全重构**：P0-1 拆 ViewModel 时容易顺手大改，建议「先拆结构、行为不变」，跑通后再做行为优化
- **不要给 SharedPreferences 上重型方案**：缓存用 drift 新表或分 key 文件即可，不值得为此引 hive/isar

---

## 四、建议的实施顺序

```
第一批（解决当下痛点）：  P0-3（通信任）→ P0-2（缓存/内存）→ P2-3（首页提速）
第二批（结构治理）：      P0-1（拆 ViewModel）→ P1-1（归位）→ P1-2（解析）→ P1-3（providers）
第三批（可选）：          P2-1 / P2-2 / P2-4
```

第一批全是低风险、立竿见影（首页秒开 + 内存下降 + 修 rebuild bug）；
第二批是还债，做完后项目结构会清晰一个量级；
第三批看心情。

---

## 五、一页纸目标结构（供参考）

```
lib/
  main.dart
  app/                  router, theme, main_screen
  data/
    api/                bangumi / anilist REST client + throttle + interceptor
    parsing/            json 解析（统一一处）
    cache/              TtlCache + 首页持久缓存
    local/              drift + prefs
    repositories/       anime / favorite / rules
    models/             Anime / AnimeDetails / Genre / …（纯数据）
  domain/               rule_engine（HTML 抓取）+ 异常
  state/                各屏 controller（Riverpod）
  ui/
    screens/… widgets/… search/…（只做展示，依赖 state/ 和 models）
  services/             video_source / youtube
  utils/                typedefs / helpers
```

依赖方向：`ui → state → repositories → api/local`，单向，不回头。
