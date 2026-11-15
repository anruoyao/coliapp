import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

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
    final imageUrl = image.addBaseURL();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: DismissiblePage(
        onDismissed: () {
          Navigator.of(context).pop();
        },
        backgroundColor: Colors.transparent,
        direction: DismissiblePageDismissDirection.vertical,
        isFullScreen: false,
        child: PhotoViewGestureDetectorScope(
          axis: Axis.vertical,
          child: Stack(
            children: [
              PhotoView(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                initialScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                backgroundDecoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                heroAttributes: PhotoViewHeroAttributes(
                  tag: tag,
                  transitionOnUserGestures: true,
                ),
                loadingBuilder: (_, event) {
                  final expectedBytes = event?.expectedTotalBytes;
                  final loadedBytes = event?.cumulativeBytesLoaded;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      value: expectedBytes != null && loadedBytes != null
                          ? loadedBytes / expectedBytes
                          : null,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white38,
                  size: 44,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: LKeys.feedClose.tr,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
