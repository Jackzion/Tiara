import 'package:movies/data/models/novel_source.dart';
import 'package:xml/xml.dart';

/// wenku8 App XML API 响应解析（纯函数）。
///
/// 三种返回形态（协议调研 §2.3–2.5，官方样例实证）：
/// - `<result>`：列表/搜索，`<item aid>` 内含 `<data name="…">` 字段
/// - `<metadata>`：书籍元数据，`<data name="Title" aid>` + value 属性字段
/// - `<package>`：分卷目录，`<volume vid>` 包 `<chapter cid>`
/// 正文是纯文本（另有 normalizeWenku8ChapterText 处理）。

/// 列表/搜索 → NovelItem 列表。
/// item 字段：Title(CDATA)/Author/BookStatus/LastUpdate/Tags/IntroPreview…
List<NovelItem> parseWenku8NovelItems(String xml) {
  final doc = XmlDocument.parse(xml);
  final items = <NovelItem>[];
  for (final item in doc.findAllElements('item')) {
    final aid = item.getAttribute('aid');
    if (aid == null || aid.isEmpty) continue;
    final data = _dataFields(item);
    final title = _text(data['Title']);
    if (title.isEmpty) continue;
    items.add(
      NovelItem(
        id: aid,
        title: title,
        cover: wenku8CoverUrl(aid),
        subtitle: _text(data['Author']),
      ),
    );
  }
  return items;
}

/// 书籍元数据（do=meta）→ NovelDetail.fromInfo 可用的 Map（不含章节，
/// 章节由 parseWenku8Catalog 提供，调用方合并）。
Map<String, dynamic> parseWenku8BookMeta(String xml) {
  final doc = XmlDocument.parse(xml);
  final data = _dataFields(doc.rootElement);
  return {
    if (_text(data['Title']).isNotEmpty) 'title': _text(data['Title']),
    if (_text(data['Author']).isNotEmpty) 'author': _text(data['Author']),
    if (_text(data['IntroPreview']).isNotEmpty) 'intro': _text(data['IntroPreview']),
    if (_text(data['Intro']).isNotEmpty) 'intro': _text(data['Intro']),
  };
}

/// 分卷目录（do=package/list）→ NovelChapter 列表（带分卷名）。
/// `<volume vid="41748"><![CDATA[卷名]]><chapter cid="41749"><![CDATA[章名]]></chapter></volume>`
List<NovelChapter> parseWenku8Catalog(String xml) {
  final doc = XmlDocument.parse(xml);
  final chapters = <NovelChapter>[];
  for (final volume in doc.findAllElements('volume')) {
    // 卷名 = volume 的直接文本/CDATA 子节点（注意：innerText 基于 descendants，
    // 叶子文本节点会返回空串，必须取 value）
    final buffer = StringBuffer();
    for (final node in volume.children) {
      if (node is XmlText) {
        buffer.write(node.value);
      } else if (node is XmlCDATA) {
        buffer.write(node.value);
      }
    }
    final volumeTitle = buffer.toString().trim();
    for (final chapter in volume.findElements('chapter')) {
      final cid = chapter.getAttribute('cid');
      final title = chapter.innerText.trim();
      if (cid == null || cid.isEmpty || title.isEmpty) continue;
      chapters.add(
        NovelChapter(
          chapterId: cid,
          title: title,
          volumeTitle: volumeTitle.isEmpty ? null : volumeTitle,
        ),
      );
    }
  }
  return chapters;
}

/// 正文（do=text 纯文本）→ 阅读器内部格式。
/// 实测（2026-11-20）：段落以单换行分隔（CRLF 为主）、段首有缩进空格；
/// 插图行为 `<!--image-->url<!--image-->` 独立行；空行/纯空格行丢弃。
///
/// 注意：一行可能连排**多个**插图标记（插图章常见
/// `<!--image-->A<!--image-->   <!--image-->B<!--image-->`），
/// 必须拆成每图一段——阅读器约定「一段一图」，混排会把标记流当 URL。
String normalizeWenku8ChapterText(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final paragraphs = <String>[];
  const imageRe = r'<!--image-->(.*?)<!--image-->';
  for (final line in lines) {
    final t = line.trim();
    if (t.isEmpty || t == 'null') continue;
    final matches = RegExp(imageRe).allMatches(t).toList();
    if (matches.isEmpty) {
      paragraphs.add(t);
      continue;
    }
    // 图文混排/一行多图：文本段与图段拆开，图各自成段
    var last = 0;
    for (final m in matches) {
      final before = t.substring(last, m.start).trim();
      if (before.isNotEmpty) paragraphs.add(before);
      final url = m.group(1)!.trim();
      if (url.isNotEmpty) paragraphs.add('<!--image-->$url<!--image-->');
      last = m.end;
    }
    final after = t.substring(last).trim();
    if (after.isNotEmpty) paragraphs.add(after);
  }
  return paragraphs.join('\n\n');
}

/// 版权下架/章节缺失判据（正文里出现即不可读）
bool isWenku8TextUnavailable(String raw) =>
    raw.contains('因版权问题') || raw.trim() == 'null';

/// 提取 `<data name="…">value</data>` 字段：value 属性优先，否则元素文本（CDATA）。
Map<String, String> _dataFields(XmlElement root) {
  final map = <String, String>{};
  for (final el in root.findAllElements('data')) {
    final name = el.getAttribute('name');
    if (name == null || name.isEmpty) continue;
    final attr = el.getAttribute('value');
    map[name] = (attr != null && attr.isNotEmpty) ? attr : el.innerText.trim();
  }
  return map;
}

String _text(String? value) => (value ?? '').trim();

/// 封面 URL 构造（独立函数，避免解析器与 API 服务循环依赖）
String wenku8CoverUrl(String aid) {
  final id = int.tryParse(aid) ?? 0;
  return 'https://img.wenku8.com/image/${id ~/ 1000}/$id/${id}s.jpg';
}
