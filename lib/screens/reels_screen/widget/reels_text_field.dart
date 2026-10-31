import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/reels_screen/reels_screen_controller.dart';
import 'package:untitled/utilities/const.dart';

import '../comments/reel_comment_screen.dart';

class ReelsTextField extends StatelessWidget {
  final ReelsScreenController controller;

  const ReelsTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.reelPageType.shouldShowComment) {
      return const SizedBox();
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
            color: cWhite.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100)),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller.commentTextController,
                decoration: InputDecoration(
                  hintText: LKeys.writeSomething.tr,
                  hintStyle: MyTextStyle.gilroyRegular(color: cLightText),
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(0),
                ),
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                cursorColor: cPrimary,
                style: MyTextStyle.gilroyRegular(color: cWhite),
              ),
            ),
            GestureDetector(
              child: const SendBtn(),
              onTap: controller.addComment,
            )
          ],
        ),
      ),
    );
  }
}
