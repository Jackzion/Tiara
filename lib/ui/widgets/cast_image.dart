import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies/ui/theme/theme.dart';
import 'package:movies/utils/utils.dart';

/// 演员头像和名字展示组件
/// 支持网络图片加载，图片为空时显示默认占位符
class CastImage extends StatelessWidget {
  /// 演员头像的网络地址
  final String imageUrl;
  /// 演员名字
  final String name;
  const CastImage({super.key, required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          height: 78,
          child: getAvatar(),
        ),
        addVerticalSpace(4),
        Align(
          alignment: Alignment.center,
          child: AutoSizeText(
            name,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 获取演员头像组件
  /// 如果 imageUrl 不为空，显示网络图片；否则显示默认人物图标
  Widget getAvatar() {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(
          imageUrl,
          maxHeight: 76,
          maxWidth: 76,
        ),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: buttonGrey,
        child: Icon(Icons.person, size: 76.0, color: posterBorder),
      );
    }
  }
}