import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

/// 网络/加载失败占位组件
class NetErrorView extends StatelessWidget {
  /// 主标题
  final String title;

  /// 副文案
  final String message;

  /// 重试回调；为空则不显示重试按钮
  final VoidCallback? onRetry;

  /// 返回回调；为空则不显示返回按钮
  final VoidCallback? onBack;

  const NetErrorView({
    super.key,
    this.title = '网络开小差了',
    this.message = '请检查网络连接后重试',
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIllustration(),
                  addVerticalSpace(24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  addVerticalSpace(8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 14,
                      height: 1.6,
                      color: textMuted,
                    ),
                  ),
                  addVerticalSpace(28),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 错误插画卡片：白底圆角 + 柔和阴影，让贴纸图融入深色背景
  Widget _buildIllustration() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/error_network.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          // 资源缺失时兜底，避免错误页再抛图片异常
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(40),
            child: Icon(Icons.wifi_off_rounded, size: 96, color: iconPlaceholder),
          ),
        ),
      ),
    );
  }

  /// 操作按钮：主操作「重试」琥珀实心；次操作「返回」描边
  Widget _buildActions() {
    final textStyle = GoogleFonts.notoSansSc(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    final buttons = <Widget>[
      if (onRetry != null)
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryButton,
            foregroundColor: onAccent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: textStyle,
          ),
          child: const Text('重试'),
        ),
      if (onBack != null)
        OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            foregroundColor: textSoft,
            side: const BorderSide(color: posterBorder),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: textStyle,
          ),
          child: const Text('返回'),
        ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }
}