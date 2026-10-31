import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/feed_screen/feed_screen.dart';
import 'package:untitled/screens/reels_screen/reels_grid.dart';
import 'package:untitled/screens/tag_screen/tag_controller.dart';
import 'package:untitled/utilities/const.dart';

class TagScreen extends StatelessWidget {
  final String tag;
  final bool isForReel;

  const TagScreen({Key? key, required this.tag, this.isForReel = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(TagController(replaceCharAt(tag, 0, ''),
        PageController(initialPage: isForReel ? 1 : 0)));
    return Scaffold(
      body: Column(
        children: [
          TopBarForInView(title: tag),
          Container(
            color: cDarkBG,
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 15),
                segmentController(controller),
                const SizedBox(height: 15),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: controller.controller,
              onPageChanged: (value) {
                controller.selectedPage.value = value;
              },
              children: [
                GetBuilder(
                  init: controller,
                  builder: (controller) {
                    return FeedsView(
                      controller: controller,
                      id: 'tag_$tag',
                    );
                  },
                ),
                ReelsGrid(
                  reels: controller.reels,
                  reelType: ReelPageType.hashtag,
                  isLoading: controller.isLoading,
                  hashtag: tag,
                  onFetchMoreData: controller.fetchReels,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) +
        newChar +
        oldString.substring(index + 1);
  }

  Widget segmentController(TagController controller) {
    return Obx(
      () => CupertinoSlidingSegmentedControl(
        children: {
          0: buildSegment(LKeys.feed, 0, controller),
          1: buildSegment(LKeys.reels, 1, controller)
        },
        groupValue: controller.selectedPage.value,
        backgroundColor: cWhite.withValues(alpha: 0.12),
        thumbColor: cWhite,
        padding: const EdgeInsets.all(0),
        onValueChanged: (value) {
          controller.onChangeSegment(value ?? 0);
        },
      ),
    );
  }

  Widget buildSegment(String text, int index, TagController controller) {
    return Container(
      alignment: Alignment.center,
      width: (Get.width / 2) - 30,
      child: Text(
        text.tr.toUpperCase(),
        style: MyTextStyle.gilroySemiBold(
                size: 13,
                color: controller.selectedPage == index ? cBlack : cWhite)
            .copyWith(letterSpacing: 2),
      ),
    );
  }
}
