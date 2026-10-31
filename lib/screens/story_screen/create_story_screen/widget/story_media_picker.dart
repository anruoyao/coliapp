import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/story_screen/create_story_screen/create_story_controller.dart';
import 'package:untitled/utilities/const.dart';

class StoryMediaPicker extends StatelessWidget {
  final CreateStoryController controller;

  const StoryMediaPicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          decoration: const BoxDecoration(
              color: cBlackSheetBG,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30))),
          padding: const EdgeInsets.all(25),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Spacer(),
                    XMarkButton(),
                  ],
                ),
                Text(
                  LKeys.howDoYouWant.tr,
                  style: MyTextStyle.gilroyBold(size: 22, color: cWhite),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    btn(
                        title: LKeys.image,
                        onTap: controller.pickImageFromGallery),
                    const SizedBox(
                      width: 10,
                    ),
                    btn(
                      title: LKeys.video,
                      onTap: controller.pickVideoFromGallery,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget btn({required String title, required Function() onTap}) {
    return Expanded(
      child: CommonSheetButton(
        title: title.tr,
        onTap: onTap,
      ),
    );
  }
}
