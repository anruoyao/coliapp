import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/widgets/dashed_circle_painter.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen_controller.dart';
import 'package:untitled/utilities/const.dart';

class CreateReelBottomView extends StatelessWidget {
  const CreateReelBottomView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateReelScreenController>();

    return Obx(
      () => Column(
        children: [
          const _RecordingDurationSelector(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BuildBorderRoundIcon(
                image: MyImages.gallery,
                onTap: () => controller.pickVideoFromGallery(),
              ),
              _RecordingControlButton(controller: controller),
              Visibility(
                visible: !controller.isRecording.value &&
                    controller.isRecordingStarted,
                replacement: const SizedBox(width: 37),
                child: BuildBorderRoundIcon(
                  image: MyImages.check,
                  onTap: controller.stopRecording,
                  size: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: AppBar().preferredSize.height / 2),
        ],
      ),
    );
  }
}

class _RecordingDurationSelector extends StatelessWidget {
  const _RecordingDurationSelector();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateReelScreenController>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            secondsForMakingReel.length,
            (index) {
              int second = secondsForMakingReel[index];
              return Obx(
                () {
                  bool isSelected =
                      second == controller.selectedVideoDurationSec.value;

                  return InkWell(
                    onTap: () {
                      controller.selectedVideoDurationSec.value = second;
                    },
                    child: Container(
                      height: 29,
                      width: 60,
                      decoration: isSelected
                          ? ShapeDecoration(
                              color: cWhite.withValues(alpha: .2),
                              shape: SmoothRectangleBorder(
                                  borderRadius:
                                      SmoothBorderRadius(cornerRadius: 30),
                                  side: BorderSide(
                                      color: cWhite.withValues(alpha: .5),
                                      width: .5)))
                          : null,
                      alignment: Alignment.center,
                      child: Text('${second}s',
                          style: MyTextStyle.gilroyRegular(
                              color: cWhite, size: 15)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecordingControlButton extends StatelessWidget {
  final CreateReelScreenController controller;

  const _RecordingControlButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Center(
        child: SizedBox(
          width: 90,
          height: 90,
          child: GestureDetector(
            onTap: controller.playPauseToggle,
            child: CustomPaint(
              painter: DashedCirclePainter(controller.progress /
                  controller.selectedVideoDurationSec.value),
              child: Center(
                child: controller.isRecording.value
                    ? Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: cWhite.withValues(alpha: .0),
                            shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            2,
                            (index) => Padding(
                              padding:
                                  EdgeInsets.only(left: index == 0 ? 0 : 3),
                              child: Container(
                                height: 30,
                                width: 12,
                                decoration: ShapeDecoration(
                                  color: cWhite,
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(
                                        cornerRadius: 2, cornerSmoothing: 1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 65,
                        height: 65,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
