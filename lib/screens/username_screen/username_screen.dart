import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/username_screen/username_controller.dart';
import 'package:untitled/utilities/const.dart';

import '../rooms_you_own/create_room_screen/create_room_screen.dart';

class UserNameScreen extends StatelessWidget {
  const UserNameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(UsernameController());
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: pOnBoarding,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const TopBarForOnBoarding(
                        titleStart: LKeys.setYour,
                        titleEnd: LKeys.username,
                        desc: LKeys.setUsernameDesc,
                      ),
                      // const Spacer(),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: Get.height / 9),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 120,
                              backgroundColor:
                                  cLightText.withValues(alpha: 0.03),
                            ),
                            CircleAvatar(
                              radius: 90,
                              backgroundColor:
                                  cLightText.withValues(alpha: 0.05),
                            ),
                            CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  cLightText.withValues(alpha: 0.07),
                            ),
                            Text(
                              "@",
                              style: MyTextStyle.gilroyExtraBold(
                                  size: 70, color: cPrimary),
                            )
                          ],
                        ),
                      ),
                      // const Spacer(),
                      GetBuilder<UsernameController>(
                        builder: (controller) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      LKeys.username.tr,
                                      style: MyTextStyle.gilroySemiBold(),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      "(${controller.textController.text.length}/${Limits.username})",
                                      style: MyTextStyle.gilroyLight(
                                          color: cLightText),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  decoration: const ShapeDecoration(
                                      shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius.all(
                                              SmoothRadius(
                                                  cornerRadius: 8,
                                                  cornerSmoothing:
                                                      cornerSmoothing))),
                                      color: cLightBg),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                  child: Row(
                                    children: [
                                      Text(
                                        "@",
                                        style: MyTextStyle.gilroyRegular(
                                            color: cLightText),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          maxLength: Limits.username,
                                          decoration: InputDecoration(
                                              hintText: "abc",
                                              hintStyle:
                                                  MyTextStyle.gilroyRegular(
                                                      color: cLightText),
                                              border: InputBorder.none,
                                              counterText: '',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(0)),
                                          cursorColor: cPrimary,
                                          style: MyTextStyle.gilroyRegular(
                                              color: cLightText),
                                          controller: controller.textController,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // const Spacer(),
                    ],
                  ),
                ),
              ),
              CommonButton(
                  text: LKeys.continue1,
                  onTap: () {
                    controller.updateUsername();
                  })
            ],
          ),
        ),
      ),
    );
  }
}

class UserNameTextField extends StatelessWidget {
  final UsernameController controller;

  const UserNameTextField({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UsernameController>(
      init: controller,
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CreateRoomHeading(
              title: LKeys.username,
              bracketText:
                  "(${controller.textController.text.length}/${Limits.username})",
            ),
            const SizedBox(
              height: 0,
            ),
            Container(
              decoration: const ShapeDecoration(
                  shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius.all(SmoothRadius(
                          cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
                  color: cLightBg),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Text(
                    "@",
                    style: MyTextStyle.gilroyRegular(color: cLightText),
                  ),
                  Expanded(
                    child: TextField(
                      maxLength: Limits.username,
                      decoration: InputDecoration(
                          hintText: "abc",
                          hintStyle:
                              MyTextStyle.gilroyRegular(color: cLightText),
                          border: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(0)),
                      cursorColor: cPrimary,
                      style: MyTextStyle.gilroyRegular(color: cLightText),
                      controller: controller.textController,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        );
      },
    );
  }
}
