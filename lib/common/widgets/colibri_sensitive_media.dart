import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:untitled/utilities/const.dart';

/// 敏感内容媒体遮罩（对齐网页端 SensitiveContentAlert）。
///
/// 网页实现：黑色 70% + backdrop-blur + 眼睛斜杠图标 + 标题/描述/「点击查看」。
/// App 端交互升级：点击遮罩原地揭示媒体（网页是点击打开大图查看器）。
/// 揭示状态为卡片局部状态——列表刷新/重新进入页面后遮罩恢复。
class ColibriSensitiveMedia extends StatefulWidget {
  final bool sensitive;

  /// 媒体内容（图片/视频/GIF 等）
  final Widget child;

  /// 遮罩圆角（与媒体圆角一致，避免方角遮罩盖住圆角媒体）
  final BorderRadius borderRadius;

  const ColibriSensitiveMedia({
    super.key,
    required this.sensitive,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<ColibriSensitiveMedia> createState() => _ColibriSensitiveMediaState();
}

class _ColibriSensitiveMediaState extends State<ColibriSensitiveMedia> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.sensitive || _revealed) return widget.child;

    return Stack(
      children: [
        // 媒体仍占位布局，保证卡片高度稳定
        widget.child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _revealed = true),
              child: const _SensitiveOverlay(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 遮罩层：毛玻璃 + 黑 70% + 眼睛斜杠 + 文案（对齐网页 SensitiveContentAlert）。
class _SensitiveOverlay extends StatelessWidget {
  const _SensitiveOverlay();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Opacity(
              opacity: 0.9,
              child: Icon(Icons.visibility_off_outlined,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 10),
            const Text(
              '敏感内容！',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '此帖子可能包含敏感内容。',
              style: TextStyle(color: Colors.white, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                '点击查看',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
