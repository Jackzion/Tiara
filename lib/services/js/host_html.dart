import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// 一份已解析的文档 + 元素/节点句柄表。
///
/// doc key 由 **JS 侧**分配（`HtmlDocument._key++`），元素/节点句柄由 host 分配，
/// 元素级调用会同时带 `doc`（文档 key）和 `key`（句柄），所以句柄只要在单文档内唯一。
class _Doc {
  _Doc(this.document);

  final dom.Document document;
  final _nodes = <int, dom.Node>{};
  int _next = 1;

  int register(dom.Node node) {
    final key = _next++;
    _nodes[key] = node;
    return key;
  }

  dom.Node? node(int key) => _nodes[key];
}

/// `:contains("x")` / `:-soup-contains("x")`：csslib 不支持，这里自己兜底。
/// 用 raw 三引号：raw 字符串里 `\'` 不是转义，单引号会提前终止字面量。
final _containsPattern = RegExp(
  r''':(?:-soup-)?contains\(\s*(['"])(.*?)\1\s*\)''',
);

/// JS Engine `html` 命名空间的 host 桥（协议见 assets/init.js 的 HtmlDocument）。
class HostHtml {
  /// 规则经常忘记 dispose；留一个上限，超了按插入顺序淘汰最旧的文档。
  static const _maxDocs = 24;

  final _docs = <int, _Doc>{};

  Object? handle(Map<String, dynamic> m) {
    final fn = m['function'] as String;

    if (fn == 'parse') {
      final key = m['key'] as int;
      _docs[key] = _Doc(html_parser.parse(m['data'] as String));
      while (_docs.length > _maxDocs) {
        _docs.remove(_docs.keys.first);
      }
      return null;
    }

    // 元素级带 doc，文档级只有 key
    final docKey = (m['doc'] as int?) ?? (m['key'] as int);
    final doc = _docs[docKey];
    if (doc == null) return _emptyFor(fn);
    final key = m['key'] as int?;

    switch (fn) {
      case 'querySelector':
      case 'getElementById':
        final element = fn == 'querySelector'
            ? doc.document.querySelector(m['query'] as String)
            : doc.document.getElementById(m['id'] as String);
        return element == null ? null : doc.register(element);

      case 'querySelectorAll':
        return [
          for (final e in _queryAll(doc.document, m['query'] as String))
            doc.register(e),
        ];

      case 'dom_querySelector':
      case 'dom_querySelectorAll':
        final root = doc.node(key ?? -1);
        if (root is! dom.Element) return _emptyFor(fn);
        final found = _queryAll(root, m['query'] as String);
        if (fn == 'dom_querySelector') {
          return found.isEmpty ? null : doc.register(found.first);
        }
        return [for (final e in found) doc.register(e)];

      case 'getChildren':
        final e = doc.node(key ?? -1);
        if (e is! dom.Element) return <int>[];
        return [for (final child in e.children) doc.register(child)];

      case 'getNodes':
        final n = doc.node(key ?? -1);
        if (n is! dom.Element) return <int>[];
        return [for (final child in n.nodes) doc.register(child)];

      case 'getInnerHTML':
        final e = doc.node(key ?? -1);
        return e is dom.Element ? e.innerHtml : null;

      case 'getParent':
        final parent = doc.node(key ?? -1)?.parent;
        return parent is dom.Element ? doc.register(parent) : null;

      case 'getPreviousSibling':
        final e = doc.node(key ?? -1);
        final prev = e is dom.Element ? e.previousElementSibling : null;
        return prev == null ? null : doc.register(prev);

      case 'getNextSibling':
        final e = doc.node(key ?? -1);
        final next = e is dom.Element ? e.nextElementSibling : null;
        return next == null ? null : doc.register(next);

      case 'getClassNames':
        final e = doc.node(key ?? -1);
        return e is dom.Element ? e.classes.toList() : <String>[];

      case 'getId':
        final e = doc.node(key ?? -1);
        return e is dom.Element ? e.id : null;

      case 'getLocalName':
        final e = doc.node(key ?? -1);
        return e is dom.Element ? e.localName : null;

      case 'getText':
      case 'node_text':
        return doc.node(key ?? -1)?.text;

      case 'getAttributes':
        final e = doc.node(key ?? -1);
        if (e is! dom.Element) return <String, String>{};
        // attributes 的 key 是 Object（可能是 AttributeName），必须 toString
        return {
          for (final entry in e.attributes.entries)
            entry.key.toString(): entry.value,
        };

      case 'node_type':
        return doc.node(key ?? -1)?.nodeType;

      case 'node_toElement':
        final n = doc.node(key ?? -1);
        return n is dom.Element ? doc.register(n) : null;

      case 'dispose':
        _docs.remove(docKey);
        return null;

      default:
        throw 'Host html 未实现: $fn';
    }
  }

  /// 查不到时各函数应返回的「空值」，避免规则 `.map` 拿到 null。
  Object? _emptyFor(String fn) =>
      (fn == 'querySelectorAll' || fn == 'dom_querySelectorAll')
      ? <int>[]
      : null;

  /// 先按标准 CSS 查；`:contains(...)` 从选择器里摘掉后用文本过滤兜底。
  List<dom.Element> _queryAll(dom.Node root, String selector) {
    final contains = <String>[];
    var cleaned = selector;
    for (final match in _containsPattern.allMatches(selector)) {
      contains.add(match.group(2)!);
      cleaned = cleaned.replaceFirst(match.group(0)!, '');
    }
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) cleaned = '*';

    Iterable<dom.Element> found;
    try {
      if (root is dom.Document) {
        found = root.querySelectorAll(cleaned);
      } else if (root is dom.Element) {
        found = root.querySelectorAll(cleaned);
      } else {
        return const [];
      }
    } catch (_) {
      // 选择器语法超出 csslib 能力：当作没命中，别让整条规则挂掉
      return const [];
    }

    if (contains.isEmpty) return found.toList();
    return [
      for (final e in found)
        if (contains.every(e.text.contains)) e,
    ];
  }
}
