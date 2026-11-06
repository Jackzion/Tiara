import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movies/state/main_nav_index.dart';
import 'package:movies/state/search_state.dart';
import 'package:movies/ui/search/global_search_controller.dart';
import 'package:movies/ui/search/global_search_overlay.dart';

/// 全局搜索的键盘路由与 Overlay 挂载点（应放在 App 根，如 MaterialApp.builder）。
///
/// 中文 IME 的前提（否则拼音根本到不了 Flutter）：
/// - 必须有一个**已聚焦**的 TextField 作为 TextInput 客户端
/// - 关闭态也保持该焦点；根 FocusScope 不要 autofocus，否则会抢走它
/// - 拼音第一键：只 open、不 consume，让 IME 从第一字母就开始组合
class GlobalSearchScope extends StatefulWidget {
  const GlobalSearchScope({super.key, required this.child});

  /// 原 App 内容（路由子树）
  final Widget child;

  @override
  State<GlobalSearchScope> createState() => _GlobalSearchScopeState();
}

class _GlobalSearchScopeState extends State<GlobalSearchScope> {
  final GlobalSearchController _controller = GlobalSearchController();

  /// 根键盘 Scope：KeyEvent 从 primaryFocus 向上冒泡时经过这里。
  /// **不要** autofocus —— 会把焦点从大输入框抢走，中文 IME 就哑了。
  final FocusScopeNode _rootFocusNode = FocusScopeNode(debugLabel: 'GlobalSearchRoot');

  /// 同一次物理按键可能先后进入 HardwareKeyboard 与 Focus 两条路径。
  KeyEvent? _lastConsumedKey;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    FocusManager.instance.addListener(_onFocusChanged);
    // 首帧后把焦点钉在搜索框上，IME 才有 client
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.ensureFieldFocused();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _controller.dispose();
    _rootFocusNode.dispose();
    super.dispose();
  }

  /// 焦点被业务页/按钮抢走时，空闲则抢回搜索框（中文 IME 依赖）。
  ///
  /// 仅在**没有业务输入**时抢：否则 Tab 在业务输入框之间跳会被打断。
  void _onFocusChanged() {
    if (!mounted) return;
    if (_controller.isOpen || _controller.isComposing) return;
    if (_isBusinessTyping) return;
    if (_controller.fieldFocusNode.hasFocus) return;
    final primary = FocusManager.instance.primaryFocus;
    // 按钮等非输入控件持焦时也抢回：无 TextInput client 时中文 IME 是哑的
    if (primary == null || !_isEditableContext(primary.context)) {
      _controller.ensureFieldFocused();
    }
  }

  bool _isEditableContext(BuildContext? ctx) {
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// 焦点是否落在**业务**输入框（不是我们自己的大搜索框）。
  bool get _isBusinessTyping {
    if (_controller.fieldFocusNode.hasFocus) return false;
    return _isEditableContext(FocusManager.instance.primaryFocus?.context);
  }

  bool _isControlChar(String ch) {
    final code = ch.codeUnitAt(0);
    return code < 0x20 || code == 0x7f;
  }

  bool _dispatch(KeyEvent event) {
    if (identical(_lastConsumedKey, event)) return true;
    if (_tryHandleKey(event)) {
      _lastConsumedKey = event;
      return true;
    }
    return false;
  }

  bool _tryHandleKey(KeyEvent event) {
    // Esc：开着就关；焦点留在搜索框
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (event is! KeyDownEvent) return false;
      if (!_controller.isOpen) return false;
      _controller.close();
      return true;
    }

    // Overlay 打开：backspace 等交给输入框 Shortcuts
    if (_controller.isOpen) return false;
    if (event is! KeyDownEvent) return false;

    // Ctrl/Cmd+K：强制唤起
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      _controller.open();
      return true;
    }

    if (isCtrl ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return false;
    }

    // 业务输入框中不抢
    if (_isBusinessTyping) return false;

    // character 为空：多半是 IME 键（拼音阶段 Windows 可能不带 character）。
    // 只展开、放行，让 IME 从第一键开始做完整组合（nihao 而不是 n+hong）。
    final raw = event.character;
    if (raw == null || raw.isEmpty) {
      final label = event.logicalKey.keyLabel;
      if (label.length == 1 && !_isControlChar(label)) {
        _controller.ensureFieldFocused();
        _controller.open();
        return false;
      }
      return false;
    }
    if (_isControlChar(raw)) return false;

    // 明确的拉丁字符：
    // - 焦点已在搜索框 → 只展开并放行，由 TextInput 写入（避免双重插入）
    // - 焦点不在输入框 → seed，否则这一键会丢
    if (_controller.fieldFocusNode.hasFocus) {
      _controller.open();
      return false;
    }
    _controller.open(seed: raw);
    return true;
  }

  bool _onHardwareKey(KeyEvent event) {
    if (!mounted) return false;
    try {
      return _dispatch(event);
    } catch (e, s) {
      debugPrint('GlobalSearch key error: $e\n$s');
      return false;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    return _dispatch(event) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  /// Enter 提交：关框 → 切 Genre Tab → 写入 SearchState。
  /// Genre 页消费该请求并 search()；seq 递增保证同词再搜也会触发。
  void _submitToGenre(String raw) {
    final keyword = raw.trim();
    _controller.close();
    if (keyword.isEmpty) return;

    final container = ProviderScope.containerOf(context, listen: false);
    container.read(currentNavIndexProvider.notifier).goTo(1);
    container.read(searchStateProvider.notifier).searchByKeyword(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _rootFocusNode,
      // 故意不 autofocus：焦点必须留给大搜索框，中文 IME 才能投递拼音
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          widget.child,
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return GlobalSearchOverlay(
                controller: _controller,
                onEscape: _controller.close,
                onSubmitted: _submitToGenre,
              );
            },
          ),
        ],
      ),
    );
  }
}
