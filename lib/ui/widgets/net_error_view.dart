import 'package:flutter/material.dart';
import 'package:movies/ui/theme/archive_tokens.dart';
import 'package:movies/ui/widgets/archive/archive_ui.dart';

/// 网络/加载失败占位：一张档案图版 + 一段通知书。
class NetErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
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
    final tone = ArchiveTone.of(context);
    return Scaffold(
      backgroundColor: tone.pageEnd,
      body: Atmosphere(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: ArchiveGeometry.pagePadding,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIllustration(context),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: ArchiveType.section.copyWith(
                        fontSize: 20,
                        color: tone.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: ArchiveType.bodyRegular.copyWith(
                        height: 1.7,
                        color: tone.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 图版：3px 圆角 + 发丝线，没有白卡和投影
  Widget _buildIllustration(BuildContext context) {
    final tone = ArchiveTone.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(ArchiveGeometry.panelRadius),
        border: Border.all(
          color: tone.hairline,
          width: ArchiveGeometry.hairlineWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ArchiveRegistration(
        child: Image.asset(
          'assets/error_network.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Padding(
            padding: const EdgeInsets.all(40),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 72,
              color: tone.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (onRetry != null)
          ArchivePillButton(label: '重试', onPressed: onRetry),
        if (onBack != null)
          ArchiveTextButton(onPressed: onBack, child: const Text('返回')),
      ],
    );
  }
}
