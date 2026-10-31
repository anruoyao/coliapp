import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/black_gradient_shadow.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_controller.dart';
import 'package:untitled/screens/story_screen/create_story_screen/widget/create_story_bottom_view.dart';
import 'package:untitled/screens/story_screen/create_story_screen/widget/create_story_top_view.dart';
import 'package:untitled/screens/story_screen/story_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CreateStoryScreen extends StatelessWidget {
  final bool shouldShowStory;
  final User user;

  const CreateStoryScreen(
      {super.key, required this.user, this.shouldShowStory = true});

  @override
  Widget build(BuildContext context) {
    final CreateStoryController controller = CreateStoryController();
    return GetBuilder(
        init: controller,
        builder: (controller) {
          return Container(
              color: cBlack,
              child: user.stories?.isNotEmpty == true &&
                      controller.shouldAddStory == false &&
                      shouldShowStory
                  ? existingStoryView(controller)
                  : VisibilityDetector(
                      key: Key('create_story_screen'),
                      onVisibilityChanged: (info) {
                        if (info.visibleFraction == 1) {
                          controller.initCameraView();
                        }
                      },
                      child: Container(
                        color: cBlack,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: .52,
                              child: ClipSmoothRect(
                                radius: SmoothBorderRadius(
                                    cornerRadius: 20, cornerSmoothing: 1),
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: RetrytechPlugin.shared.cameraView,
                                ),
                              ),
                            ),
                            const Align(
                                alignment: Alignment.bottomCenter,
                                child: BlackGradientShadow()),
                            SafeArea(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CreateStoryTopView(),
                                  CreateStoryBottomView(),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ));
        });
  }

  Widget existingStoryView(CreateStoryController controller) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        StoryScreen(users: [user], index: 0),
        SafeArea(
          child: GestureDetector(
            onTap: controller.createAnotherStory,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding:
                  const EdgeInsets.only(right: 20, left: 20, top: 7, bottom: 5),
              decoration: BoxDecoration(
                  color: cWhite, borderRadius: BorderRadius.circular(100)),
              child: Text(
                LKeys.create.tr.toUpperCase(),
                style: MyTextStyle.gilroySemiBold(color: cBlack, size: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
