import 'dart:math';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/duration_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/buttons/xmark_button.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/musics_model.dart';
import 'package:untitled/screens/camera_screen/music_trim_sheet/music_trim_screen_controller.dart';
import 'package:untitled/utilities/const.dart';

class MusicTrimSheet extends StatelessWidget {
  final SelectedMusic music;
  final int videoDurationInMilliSec;

  const MusicTrimSheet(
      {super.key, required this.music, required this.videoDurationInMilliSec});

  @override
  Widget build(BuildContext context) {
    MusicTrimScreenController _controller =
        Get.put(MusicTrimScreenController(videoDurationInMilliSec, music));

    Widget _waveSlider() {
      return Obx(
        () => FittedBox(
          child: Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) {
                    return Container(
                      width: 3,
                      margin: EdgeInsets.symmetric(horizontal: 1.5),
                      height: index * 4,
                      decoration: ShapeDecoration(
                        shape: StadiumBorder(),
                        color: cWhite.withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: cWhite,
              ),
              Container(
                width: _controller.boxWidth,
                child: SingleChildScrollView(
                  controller: _controller.scrollController,
                  dragStartBehavior: DragStartBehavior.down,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: _controller.boxWidth),
                        child: Row(
                          children: List.generate(
                            _controller.waves.length,
                            (index) {
                              return Container(
                                height: max(2, _controller.waves[index] * 100),
                                margin: EdgeInsets.symmetric(
                                    horizontal:
                                        _controller.barHorizontalMargin),
                                width: _controller.barWidth,
                                decoration: ShapeDecoration(
                                  shape: StadiumBorder(),
                                  color: _controller.currentBars >= index &&
                                          _controller.previousBar <= index &&
                                          _controller.isPlaying.value
                                      ? cPrimary
                                      : cWhite.withValues(alpha: 0.3),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: cWhite,
              ),
              Row(
                children: List.generate(
                  5,
                  (index) {
                    return Container(
                      width: 3,
                      decoration: ShapeDecoration(
                        shape: StadiumBorder(),
                        color: cWhite.withValues(alpha: 0.3),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 1.5),
                      height: (4 - index) * 4,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _bottomOptions() {
      return Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: _controller.playPause,
              child: Icon(
                _controller.isPlaying.value
                    ? CupertinoIcons.pause_circle_fill
                    : (CupertinoIcons.play_circle_fill),
                size: 60,
                color: cLightBg,
              ),
            ),
            Text(
              Duration(milliseconds: _controller.audioStartInMilliSec.value)
                  .toStringTime(),
              style: MyTextStyle.gilroyRegular(size: 16, color: cLightText),
            ),
            InkWell(
              onTap: _controller.onContinueTap,
              child: Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 60,
                color: cPrimary,
              ),
            ),
            // ),
          ],
        ),
      );
    }

    Widget _musicCard() {
      var music = _controller.selectedMusic.music!;
      return Obx(
        () => Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: ClipSmoothRect(
            radius: SmoothBorderRadius(cornerRadius: 13),
            child: Container(
              padding: EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 16),
              color: cWhite.withValues(alpha: 0.08),
              child: Row(
                children: [
                  MyCachedImage(
                    imageUrl: music.image,
                    height: 50,
                    width: 50,
                    cornerRadius: 12,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          music.title ?? '',
                          style: MyTextStyle.gilroySemiBold(
                              size: 14, color: cWhite),
                        ),
                        Row(
                          children: [
                            Text(
                              music.artist ?? '',
                              style: MyTextStyle.gilroyRegular(
                                  size: 14, color: cLightText),
                            ),
                            Spacer(),
                            Text(
                              Duration(
                                      milliseconds: _controller
                                              .durationInMilliSec.value ??
                                          0)
                                  .toStringTime(),
                              style: MyTextStyle.gilroyRegular(
                                  size: 14, color: cLightText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Wrap(
        children: [
          ClipSmoothRect(
            radius: SmoothBorderRadius.vertical(
              top: SmoothRadius(
                  cornerRadius: 30, cornerSmoothing: cornerSmoothing),
            ),
            child: Container(
              color: cBlackSheetBG,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 65,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LKeys.selectMusic.tr,
                            style: MyTextStyle.gilroyRegular(color: cPrimary),
                          ),
                          XmarkButtonForSheet()
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    _musicCard(),
                    SizedBox(height: 40),
                    Container(
                      height: 50,
                      decoration: ShapeDecoration(
                          shape: StadiumBorder(),
                          color: cWhite.withValues(alpha: 0.08)),
                      child: _waveSlider(),
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: 340,
                      child: _bottomOptions(),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
