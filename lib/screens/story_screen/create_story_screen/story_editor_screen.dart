import 'dart:io';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/camera_screen/color_filter_pageview_list.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/camera_screen/reel_editor_screen.dart';
import 'package:untitled/screens/post/video_player_sheet.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_controller.dart';
import 'package:untitled/utilities/const.dart';
import 'package:visibility_detector/visibility_detector.dart'
    show VisibilityDetector;

class StoryEditorScreen extends StatelessWidget {
  final CreateStoryController controller;

  const StoryEditorScreen({super.key, required this.controller});

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
            BuildBorderRoundIcon(
              image: MyImages.filter,
              onTap: () {
                controller.isFilterShow.value = !controller.isFilterShow.value;
              },
            ),
          ],
        ),
      );
    }

    Widget _bottomBar() {
      return SafeArea(
        top: false,
        child: Column(
          children: [
            controller.isFilterShow.value
                ? ColorFilterPageViewList(
                    onPageChanged: controller.onPageChanged,
                    pageController: PageController(
                        initialPage: controller.selectedFilterIndex.value,
                        viewportFraction: .22,
                        keepPage: true),
                  )
                : Container(),
            const SizedBox(height: 20),
            if (controller.storyType.value == StoryType.video)
              VideoSlider(
                controller: controller.videoPlayerController.value,
                onChange: onChange,
              ),
            InkWell(
              onTap: controller.sendStory,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                margin: EdgeInsets.all(10),
                decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 10,
                        cornerSmoothing: cornerSmoothing,
                      ),
                    ),
                    color: cPrimary),
                child: Text(
                  LKeys.share.tr,
                  style: MyTextStyle.gilroySemiBold(size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Obx(
        () {
          List<double> filter =
              (controller.selectedFilter.value?.colorFilter ?? []);

          return ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Obx(() {
                  return VisibilityDetector(
                    onVisibilityChanged: (info) {
                      var visiblePercentage = info.visibleFraction * 100;
                      if (visiblePercentage > 50) {
                        controller.videoPlayerController.value?.play();
                      } else {
                        controller.videoPlayerController.value?.pause();
                      }
                    },
                    key: const Key('reel_editor_screen'),
                    child: filter.isEmpty
                        ? preview()
                        : ColorFiltered(
                            colorFilter: ColorFilter.matrix(filter),
                            child: preview()),
                  );
                }),
                if (controller.storyType.value == StoryType.video)
                  IgnorePointer(
                    child: controller.isPlaying.value
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

  Widget preview() {
    return (controller.storyType.value == StoryType.video)
        ? CustomVideoPlayer(
            videoPlayerController: controller.videoPlayerController.value,
            onPlayPause: controller.playPauseToggle,
          )
        : Image.file(
            File(controller.outputURL),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );
  }

  void onChange(double value) {
    controller.videoPlayerController.value
        ?.seekTo(Duration(milliseconds: value.toInt()));
  }
}
