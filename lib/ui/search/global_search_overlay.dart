import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movies/ui/search/global_search_controller.dart';
import 'package:movies/ui/theme/theme.dart';

/// 全屏幕布 + 居中超大搜索框（全局搜索 UI 层）
///
/// 布局：半透明黑幕布（点击关闭）+ 居中 Material 卡片内的大号 [TextField]。
/// 用 Overlay / Stack 浮在业务页之上，**不** push 路由，避免：
/// - 与 auto_route 返回栈冲突
/// - 触发 AnimeDetail 等页无谓 rebuild（参见窗口缩放重载修复）
///
/// 输入框**常驻树上**（关着时 opacity=0）：
/// - 中文 IME 只有在存在已聚焦的 [TextInput] 客户端时才会出拼音预编辑
/// - 关闭后保持焦点，下一次拼音才能从第一个字母就进搜索框
/// - 有文字 / 组合区时由 [GlobalSearchController] 展开本层
class GlobalSearchOverlay extends StatelessWidget {
  const GlobalSearchOverlay({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onEscape,
  });

  /// 开/关、文本与焦点
  final GlobalSearchController controller;

  /// 回车提交回调；传入「切 Genre + SearchState 搜索请求」
  /// 为空时仅关闭 Overlay
  final ValueChanged<String>? onSubmitted;

  /// 输入框内按 Esc 时回调（默认可只 close；Scope 会再抢回根焦点）
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    // 必须自带 Overlay：本层挂在 MaterialApp.builder 里、Navigator 之外，
    // 没有祖先 Overlay。TextField 的选区菜单 / 右键菜单会 debugCheckHasOverlay
    // 并抛 “No Overlay widget found”。
    //
    // 注意：OverlayEntry.builder 只在 entry 首次构建时求值一次，
    // 外层 rebuild 不会让它重跑。因此 **必须** 在 entry 内再挂
    // ListenableBuilder，由 controller 驱动 open/close 的显隐。
    return Positioned.fill(
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) {
              return ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final open = controller.isOpen;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 测试/调试用：仅 open 时存在
                      if (open)
                        const SizedBox(
                          key: ValueKey('global_search_open'),
                          width: 0,
                          height: 0,
                        ),
                      // 幕布：仅打开时遮挡下层；点空白关闭
                      if (open)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: controller.close,
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      // 搜索卡片常驻：关着时用透明色「隐身」，不用 Opacity(0)。
                      // 部分平台对 opacity=0 的文本框不投递 IME 组合区。
                      Center(
                        child: IgnorePointer(
                          ignoring: !open,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Material(
                                color: open
                                    ? searchBarBackground
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: Focus(
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent &&
                                          event.logicalKey ==
                                              LogicalKeyboardKey.escape) {
                                        if (onEscape != null) {
                                          onEscape!();
                                        } else {
                                          controller.close();
                                        }
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: Shortcuts(
                                      shortcuts:
                                          const <ShortcutActivator, Intent>{
                                        SingleActivator(LogicalKeyboardKey
                                                .backspace):
                                            _DeleteBackwardIntent(),
                                        SingleActivator(
                                                LogicalKeyboardKey.delete):
                                            _DeleteForwardIntent(),
                                      },
                                      child: Actions(
                                        actions: <Type, Action<Intent>>{
                                          _DeleteBackwardIntent:
                                              CallbackAction<
                                                  _DeleteBackwardIntent>(
                                            onInvoke: (_) {
                                              if (controller.isComposing) {
                                                return null;
                                              }
                                              controller.applyBackspace();
                                              return null;
                                            },
                                          ),
                                          _DeleteForwardIntent:
                                              CallbackAction<
                                                  _DeleteForwardIntent>(
                                            onInvoke: (_) {
                                              if (controller.isComposing) {
                                                return null;
                                              }
                                              controller.applyForwardDelete();
                                              return null;
                                            },
                                          ),
                                        },
                                        child: TextField(
                                          key: const ValueKey(
                                              'global_search_field'),
                                          controller:
                                              controller.textController,
                                          focusNode: controller.fieldFocusNode,
                                          autofocus: true,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          enableIMEPersonalizedLearning: false,
                                          smartDashesType:
                                              SmartDashesType.disabled,
                                          smartQuotesType:
                                              SmartQuotesType.disabled,
                                          style: TextStyle(
                                            color: open
                                                ? Colors.white
                                                : Colors.transparent,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          cursorColor: open
                                              ? accentAmber
                                              : Colors.transparent,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: open ? '搜索番剧…' : '',
                                            hintStyle: const TextStyle(
                                              color: posterBorder,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            suffixIcon: open
                                                ? const Icon(
                                                    Icons.search,
                                                    color: posterBorder,
                                                    size: 32,
                                                  )
                                                : null,
                                          ),
                                          textInputAction:
                                              TextInputAction.search,
                                          onSubmitted: (value) {
                                            if (onSubmitted != null) {
                                              onSubmitted!(value);
                                            } else {
                                              controller.close();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeleteBackwardIntent extends Intent {
  const _DeleteBackwardIntent();
}

class _DeleteForwardIntent extends Intent {
  const _DeleteForwardIntent();
}
