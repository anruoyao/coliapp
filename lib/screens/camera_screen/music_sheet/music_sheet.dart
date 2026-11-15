import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/colibri_bottom_sheet.dart';
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
    final controller = Get.put(MusicSheetController());
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Obx(
        () => ColibriSheetSurface(
          backgroundColor: cBlackSheetBG,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              ColibriSheetHeader(
                title: LKeys.selectMusic.tr,
                foregroundColor: cWhite,
                handleColor: cWhite.withValues(alpha: 0.35),
                trailing: const ColibriSheetCloseButton(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CupertinoSlidingSegmentedControl<MusicSheetScreenType>(
                  children: {
                    MusicSheetScreenType.explore: buildSegment(LKeys.explore,
                        MusicSheetScreenType.explore, controller),
                    MusicSheetScreenType.category: buildSegment(
                        LKeys.categories,
                        MusicSheetScreenType.category,
                        controller),
                    MusicSheetScreenType.saved: buildSegment(
                        LKeys.saved, MusicSheetScreenType.saved, controller),
                  },
                  groupValue: controller.selectedPage.value,
                  backgroundColor: cWhite.withValues(alpha: 0.12),
                  thumbColor: cWhite,
                  padding: const EdgeInsets.all(0),
                  onValueChanged: controller.onChangeSegment,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: cWhite.withValues(alpha: 0.1),
                    child: TextField(
                      onChanged: controller.search,
                      style: MyTextStyle.gilroyRegular(color: cWhite),
                      decoration: InputDecoration(
                        hintText: LKeys.searchHere.tr,
                        hintStyle: MyTextStyle.gilroyRegular(
                            color: cLightText.withValues(alpha: 0.8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 11),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChange,
                  children: [
                    MusicExplorePage(controller: controller),
                    MusicCategoryPage(controller: controller),
                    MusicSavedPage(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSegment(
      String text, MusicSheetScreenType page, MusicSheetController controller) {
    return SizedBox(
      width: (Get.width / 2) - 30,
      child: Center(
        child: Text(
          text.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MyTextStyle.gilroySemiBold(
            size: 13,
            color: controller.selectedPage.value == page ? cBlack : cWhite,
          ),
        ),
      ),
    );
  }
}
