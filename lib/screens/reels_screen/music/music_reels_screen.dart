import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/duration_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/reels_screen/music/music_reels_screen_controller.dart';
import 'package:untitled/screens/reels_screen/reels_grid.dart';
import 'package:untitled/utilities/const.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MusicReelsScreen extends StatelessWidget {
  final Music? music;

  const MusicReelsScreen({super.key, required this.music});

  @override
  Widget build(BuildContext context) {
    MusicReelsScreenController controller =
        Get.put(MusicReelsScreenController(music));
    return Scaffold(
      body: VisibilityDetector(
        onVisibilityChanged: (info) {
          if (info.visibleFraction < 0.5) {
            controller.pause();
          }
        },
        key: Key('music_reels_screen'),
        child: Column(
          children: [
            TopBarForInView(
              title: LKeys.audio,
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      MyCachedImage(
                        imageUrl: music?.image,
                        height: 60,
                        width: 60,
                        cornerRadius: 10,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            music?.title ?? '',
                            style: MyTextStyle.gilroySemiBold(
                                size: 18, color: cDarkBG),
                          ),
                          SizedBox(height: 5),
                          Text(
                            music?.artist ?? '',
                            style: MyTextStyle.gilroyRegular(
                                size: 16, color: cLightText),
                          ),
                        ],
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            Get.to(() => CreateReelScreen(music: music),
                                opaque: false);
                          },
                          child: Container(
                            decoration: ShapeDecoration(
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: 6,
                                  cornerSmoothing: cornerSmoothing,
                                ),
                              ),
                              color: cPrimary,
                            ),
                            alignment: Alignment.center,
                            height: 40,
                            child: Text(
                              LKeys.useMusic.tr,
                              style: MyTextStyle.gilroyMedium(
                                  color: cBlack, size: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Obx(
                        () => InkWell(
                          onTap: controller.bookmarkTheMusic,
                          child: Container(
                            decoration: ShapeDecoration(
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: 6,
                                  cornerSmoothing: cornerSmoothing,
                                ),
                                side: BorderSide(
                                  color: cLightText.withValues(alpha: 0.3),
                                ),
                              ),
                              color: cLightBg,
                            ),
                            alignment: Alignment.center,
                            height: 40,
                            width: 45,
                            child: Image.asset(
                              controller.isSaved.value
                                  ? MyImages.bookmarkFill
                                  : MyImages.bookmark,
                              width: 22,
                              height: 22,
                              color: cDarkText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 6,
                          cornerSmoothing: cornerSmoothing,
                        ),
                        side: BorderSide(
                          color: cLightText.withValues(alpha: 0.3),
                        ),
                      ),
                      color: cLightBg,
                    ),
                    alignment: Alignment.center,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                    child: Row(
                      children: [
                        Obx(
                          () => InkWell(
                            onTap: controller.playPause,
                            child: Image.asset(
                              controller.isPlaying.value
                                  ? MyImages.pause
                                  : MyImages.play,
                              width: 20,
                              height: 20,
                              color: cPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(() => Slider(
                                value: controller.progress.value,
                                onChanged: (value) {
                                  controller.onProgressChange(value);
                                },
                                activeColor: cPrimary,
                                inactiveColor:
                                    cLightText.withValues(alpha: 0.2),
                                onChangeStart: (value) {
                                  controller.pause();
                                },
                                onChangeEnd: (value) {
                                  controller.play();
                                },
                              )),
                        ),
                        Obx(
                          () => Text(
                            controller.duration.value.toStringTime(),
                            style: MyTextStyle.gilroyMedium(size: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ReelsGrid(
                      reels: controller.reels,
                      reelType: ReelPageType.music,
                      isLoading: controller.isLoading,
                      onFetchMoreData: controller.fetchReels,
                      shrinkWrap: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
