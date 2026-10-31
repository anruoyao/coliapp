import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/black_gradient_shadow.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/screens/camera_screen/reel_editor_screen.dart';
import 'package:untitled/screens/post/double_click_like.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/reels_screen/reel/widget/side_bar_list.dart';
import 'package:untitled/screens/reels_screen/reel/widget/user_info_and_description.dart';
import 'package:untitled/utilities/const.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelPage extends StatelessWidget {
  final Reel? reelData;
  final VideoPlayerController? videoPlayerController;
  final bool overlayTabBar;

  const ReelPage(
      {super.key,
      required this.reelData,
      this.videoPlayerController,
      this.overlayTabBar = false});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(ReelController(reelData.obs), tag: '${reelData?.id}');
    RxBool isPlaying = true.obs;

    void onPlayPause() {
      if (videoPlayerController != null) {
        if (videoPlayerController?.value.isPlaying == true) {
          videoPlayerController?.pause();
          isPlaying.value = false;
        } else {
          videoPlayerController?.play();
          isPlaying.value = true;
        }
      }
    }

    return Scaffold(
      backgroundColor: cBlack,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
              child: CupertinoActivityIndicator(
            color: cWhite,
          )),
          VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo info) {
              var visiblePercentage = info.visibleFraction * 100;
              if (videoPlayerController?.value.isInitialized == true &&
                  videoPlayerController?.value.isPlaying == false) {
                if (visiblePercentage > 50) {
                  videoPlayerController?.play();
                  isPlaying.value = true;
                } else {
                  videoPlayerController?.pause();
                  isPlaying.value = false;
                }
              }
            },
            key: Key(
                'key_${reelData?.content ?? ''}_${DateTime.now().millisecondsSinceEpoch}'),
            child: DoubleClickLikeAnimator(
              onAnimation: controller.likeWithDoubleTap,
              onTap: onPlayPause,
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    videoPlayerController != null
                        ? CustomCacheVideoPlayer(
                            videoPlayerController: videoPlayerController,
                            onPlayPause: onPlayPause)
                        : const SizedBox(),
                    const BlackGradientShadow(),
                    PlayAnimationButton(isPlaying: isPlaying),
                  ],
                ),
              ),
            ),
          ),
          ReelInfoSection(controller: controller, overlayTabBar: overlayTabBar)
        ],
      ),
    );
  }
}

class ReelInfoSection extends StatelessWidget {
  final ReelController controller;
  final bool overlayTabBar;

  const ReelInfoSection(
      {super.key, required this.controller, this.overlayTabBar = false});

  @override
  Widget build(BuildContext context) {
    // When sitting over the floating Liquid Glass tab bar, lift the action row
    // above the bar; otherwise keep the original 20px bottom spacing. The extra
    // 15px (description font size) gives breathing room between the row and the bar.
    final double bottomSpacing = overlayTabBar
        ? MediaQuery.of(context).padding.bottom +
            kLiquidNavBarReservedHeight +
            15
        : 20.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ReelInfoRow(controller: controller),
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class ReelInfoRow extends StatelessWidget {
  final ReelController controller;

  const ReelInfoRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: UserInfoAndDescription(controller: controller)),
        SideBarList(controller: controller),
      ],
    );
  }
}

class PlayAnimationButton extends StatelessWidget {
  final RxBool isPlaying;

  const PlayAnimationButton({super.key, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Opacity(
        opacity: isPlaying.value ? 0 : 1,
        child: Align(
          alignment: Alignment.center,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: cBlack.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  isPlaying.value ? MyImages.pauseFill : MyImages.playFill,
                  width: 20,
                  height: 20,
                  color: cWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
