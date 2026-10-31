import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/buttons/xmark_button.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_category_page.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_explore_page.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_saved_page.dart';
import 'package:untitled/screens/camera_screen/music_sheet/music_sheet_controller.dart';
import 'package:untitled/utilities/const.dart';

class MusicSheet extends StatelessWidget {
  const MusicSheet({super.key});

  @override
  Widget build(BuildContext context) {
    MusicSheetController controller = Get.put(MusicSheetController());
    return SafeArea(
      bottom: false,
      child: Obx(
        () => ClipSmoothRect(
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
                  SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: CupertinoSlidingSegmentedControl(
                      children: {
                        MusicSheetScreenType.explore: buildSegment(
                            LKeys.explore,
                            MusicSheetScreenType.explore,
                            controller),
                        MusicSheetScreenType.category: buildSegment(
                            LKeys.categories,
                            MusicSheetScreenType.category,
                            controller),
                        MusicSheetScreenType.saved: buildSegment(LKeys.saved,
                            MusicSheetScreenType.saved, controller),
                      },
                      groupValue: controller.selectedPage.value,
                      backgroundColor: cWhite.withValues(alpha: 0.08),
                      thumbColor: cWhite,
                      padding: const EdgeInsets.all(0),
                      onValueChanged: (value) {
                        controller.onChangeSegment(value);
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipSmoothRect(
                      radius: SmoothBorderRadius(cornerRadius: 23),
                      child: Container(
                        color: cWhite.withValues(alpha: 0.08),
                        child: TextField(
                          onChanged: controller.search,
                          style: MyTextStyle.gilroyRegular(color: cLightText),
                          decoration: InputDecoration(
                            hintText: LKeys.searchHere.tr,
                            hintStyle: MyTextStyle.gilroyRegular(
                                color: cLightText.withValues(alpha: 0.6)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Expanded(
                    child: PageView(
                      controller: controller.pageController,
                      onPageChanged: controller.onPageChange,
                      children: [
                        MusicExplorePage(
                          controller: controller,
                        ),
                        MusicCategoryPage(
                          controller: controller,
                        ),
                        MusicSavedPage(
                          controller: controller,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSegment(
      String text, MusicSheetScreenType page, MusicSheetController controller) {
    return Container(
      alignment: Alignment.center,
      width: (Get.width / 2) - 30,
      child: Text(
        text.tr.toUpperCase(),
        style: MyTextStyle.gilroySemiBold(
          size: 13,
          color: controller.selectedPage == page ? cBlack : cWhite,
        ).copyWith(
          letterSpacing: 2,
        ),
      ),
    );
  }
}
