import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/loader_widget.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/camera_screen/color_filter_pageview_list.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen_controller.dart';
import 'package:untitled/screens/camera_screen/widget/create_reel_top_view.dart';
import 'package:untitled/utilities/const.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart'
    show VisibilityDetector;

import '../reels_screen/reel/reel_page.dart';

/// Stateful widget to fetch and then display video content.
class ReelEditorScreen extends StatelessWidget {
  final CreateReelScreenController cameraScreenController;

  const ReelEditorScreen({super.key, required this.cameraScreenController});

  @override
  Widget build(BuildContext context) {
    Widget _topBar() {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BuildBorderRoundIcon(
              image: MyImages.close,
              onTap: Get.back,
              size: 14,
            ),
            const SizedBox(width: 10),
            Obx(
              () => cameraScreenController.selectedMusic.value == null
                  ? const SizedBox()
                  : SelectedMusicView(
                      controller: cameraScreenController,
                    ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                BuildBorderRoundIcon(
                  onTap: cameraScreenController.onMusicTap,
                  image: MyImages.music,
                ),
                const SizedBox(height: 20),
                BuildBorderRoundIcon(
                  image: MyImages.filter,
                  onTap: () {
                    cameraScreenController.isFilterShow.value =
                        !cameraScreenController.isFilterShow.value;
                  },
                ),
                const SizedBox(height: 20),
              ],
            )
          ],
        ),
      );
    }

    Widget _bottomBar() {
      return Column(
        children: [
          cameraScreenController.isFilterShow.value
              ? ColorFilterPageViewList(
                  onPageChanged: cameraScreenController.onPageChanged,
                  pageController: PageController(
                      initialPage:
                          cameraScreenController.selectedFilterIndex.value,
                      viewportFraction: .22,
                      keepPage: true),
                )
              : Container(),
          const SizedBox(height: 20),
          InkWell(
            onTap: cameraScreenController.goToPreview,
            child: FittedBox(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 10,
                        cornerSmoothing: cornerSmoothing,
                      ),
                    ),
                    color: cPrimary),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      LKeys.continue_.tr,
                      style: MyTextStyle.gilroySemiBold(size: 18),
                    ),
                    SizedBox(width: 10),
                    Image.asset(
                      MyImages.send,
                      width: 22,
                      height: 22,
                    )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: AppBar().preferredSize.height / 2),
        ],
      );
    }

    return Scaffold(
      body: Obx(
        () {
          List<double> filter =
              (cameraScreenController.selectedFilter.value?.colorFilter ?? []);

          return ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Obx(() {
                  return VisibilityDetector(
                    onVisibilityChanged: (info) {
                      var visiblePercentage = info.visibleFraction * 100;
                      if (visiblePercentage > 50) {
                        cameraScreenController.playAudioVideo();
                      } else {
                        cameraScreenController.stopAudioVideo();
                      }
                    },
                    key: const Key('reel_editor_screen'),
                    child: filter.isEmpty
                        ? CustomVideoPlayer(
                            videoPlayerController: cameraScreenController
                                .videoPlayerController.value,
                            onPlayPause: cameraScreenController.playPausePlayer,
                          )
                        : ColorFiltered(
                            colorFilter: ColorFilter.matrix(filter),
                            child: CustomVideoPlayer(
                              videoPlayerController: cameraScreenController
                                  .videoPlayerController.value,
                              onPlayPause:
                                  cameraScreenController.playPausePlayer,
                            )),
                  );
                }),
                IgnorePointer(
                  child: cameraScreenController.isPlaying.value
                      ? Container()
                      : PlayAnimationButton(isPlaying: false.obs),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _topBar(),
                      Spacer(),
                      _bottomBar(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CustomVideoPlayer extends StatelessWidget {
  final VideoPlayerController? videoPlayerController;
  final VoidCallback onPlayPause;

  const CustomVideoPlayer(
      {super.key,
      required this.videoPlayerController,
      required this.onPlayPause});

  @override
  Widget build(BuildContext context) {
    if (videoPlayerController != null &&
        videoPlayerController!.value.isInitialized) {
      final videoSize = videoPlayerController!.value.size;
      final fitType =
          videoSize.width < videoSize.height ? BoxFit.cover : BoxFit.fitWidth;
      return InkWell(
          onTap: onPlayPause,
          child: Container(
            color: cBlack,
            child: SizedBox.expand(
              child: FittedBox(
                fit: fitType,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: VideoPlayer(videoPlayerController!),
                ),
              ),
            ),
          ));
    } else {
      return LoaderWidget();
    }
  }
}

class CustomCacheVideoPlayer extends StatelessWidget {
  final VideoPlayerController? videoPlayerController;
  final VoidCallback onPlayPause;

  const CustomCacheVideoPlayer(
      {super.key,
      required this.videoPlayerController,
      required this.onPlayPause});

  @override
  Widget build(BuildContext context) {
    if (videoPlayerController != null &&
        videoPlayerController?.value.isInitialized == true) {
      final videoSize = (videoPlayerController?.value.size)!;
      final fitType =
          videoSize.width < videoSize.height ? BoxFit.cover : BoxFit.fitWidth;
      return InkWell(
          onTap: onPlayPause,
          child: Container(
            color: cBlack,
            child: SizedBox.expand(
              child: FittedBox(
                fit: fitType,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: VideoPlayer((videoPlayerController)!),
                ),
              ),
            ),
          ));
    } else {
      return LoaderWidget();
    }
  }
}
