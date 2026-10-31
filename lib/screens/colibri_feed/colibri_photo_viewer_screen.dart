import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

/// 全屏图片查看器：多图左右滑动翻页（PageView）+ 双指缩放 + 下滑关闭 + 页码指示。
/// 帖子单图 / 多图网格点击后均进入此页面。
class ColibriPhotoViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ColibriPhotoViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ColibriPhotoViewerScreen> createState() =>
      _ColibriPhotoViewerScreenState();
}

class _ColibriPhotoViewerScreenState extends State<ColibriPhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    // 与全屏视频（ColibriFullScreenVideo）一致的沉浸退出方式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: DismissiblePage(
          onDismissed: () => Get.back(),
          backgroundColor: Colors.transparent,
          // 垂直拖动关闭交给 DismissiblePage，水平滑动翻页交给 PageView
          direction: DismissiblePageDismissDirection.vertical,
          isFullScreen: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.back(),
            child: Stack(
              children: [
                // 图片分页
                PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    return ZoomOverlay(
                      modalBarrierColor: Colors.transparent,
                      minScale: 1,
                      maxScale: 3.5,
                      animationCurve: Curves.fastOutSlowIn,
                      animationDuration: const Duration(milliseconds: 220),
                      twoTouchOnly: true,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: widget.images[i],
                          fit: BoxFit.contain,
                          fadeInDuration: const Duration(milliseconds: 120),
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: Colors.white54),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: Colors.white38, size: 44),
                              SizedBox(height: 8),
                              Text('图片加载失败',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 顶部渐变遮罩（保证控件可读）
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // 顶部控件：关闭 + 页码
                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => Get.back(),
                        ),
                        const Spacer(),
                        if (widget.images.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_index + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 顶部圆形半透明按钮。
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
