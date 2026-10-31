import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/screens/camera_screen/create_reel_screen.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_controller.dart';
import 'package:untitled/utilities/const.dart';

class CreateStoryBottomView extends StatelessWidget {
  const CreateStoryBottomView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateStoryController>();

    return Obx(
      () => Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BuildBorderRoundIcon(
                image: MyImages.gallery,
                onTap: controller.pickMedia,
              ),
              Container(
                height: 70,
                width: 70,
                decoration: ShapeDecoration(
                    shape: CircleBorder(
                        side: BorderSide(width: 5, color: cWhite))),
                child: GestureDetector(
                  onTap: () {
                    HapticManager.shared.light();
                    print("on Tap Capture");
                    controller.takePicture();
                  },
                  onLongPressStart: (details) {
                    HapticManager.shared.light();
                    controller.startRecording();
                  },
                  onLongPressEnd: (details) {
                    HapticManager.shared.light();
                    controller.stopRecording();
                  },
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
                                            cornerRadius: 2,
                                            cornerSmoothing: 1),
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
              Visibility(
                visible: !controller.isRecording.value &&
                    controller.isRecordingStarted,
                replacement: const SizedBox(width: 37),
                child: BuildBorderRoundIcon(
                  image: MyImages.check,
                  // onTap: controller.stopRecording,
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
