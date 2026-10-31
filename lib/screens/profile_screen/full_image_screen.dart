import 'dart:ui';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

class FullImageScreen extends StatelessWidget {
  final String image;
  final String tag;
  final double? width;
  final double? height;
  final double cornerRadius;

  const FullImageScreen({
    super.key,
    required this.image,
    required this.tag,
    this.height,
    this.width,
    this.cornerRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.back();
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DismissiblePage(
          onDismissed: () {
            Navigator.of(context).pop();
          },
          backgroundColor: Colors.transparent,
          // Note that scrollable widget inside DismissiblePage might limit the functionality
          // If scroll direction matches DismissiblePage direction
          direction: DismissiblePageDismissDirection.multi,
          isFullScreen: false,
          child: ZoomOverlay(
            modalBarrierColor: Colors.black.withValues(alpha: 0.5),
            minScale: 1,
            maxScale: 3.0,
            animationCurve: Curves.fastOutSlowIn,
            animationDuration: const Duration(milliseconds: 300),
            twoTouchOnly: true,
            child: Stack(
              children: [
                Center(
                  child: Hero(
                    tag: tag,
                    // 直接显示图片（图片本身已带水印与圆角），不再套灰色边框层
                    child: MyCachedProfileImage(
                      imageUrl: image,
                      width: width,
                      height: height,
                      cornerRadius: cornerRadius,
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
