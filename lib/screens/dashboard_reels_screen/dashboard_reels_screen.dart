import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/dashboard_reels_screen/dashboard_reels_controller.dart';
import 'package:untitled/screens/reels_screen/reels_screen.dart';
import 'package:untitled/utilities/const.dart';

class DashboardReelsScreen extends StatelessWidget {
  const DashboardReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DashboardReelsController controller = Get.put(DashboardReelsController());
    Widget topTag(DashboardReelPageType type) {
      final isRTL = Directionality.of(context) == TextDirection.rtl;
      return Obx(
        () => Expanded(
          child: InkWell(
            onTap: () {
              controller.changeTheType(type);
            },
            child: Container(
              height: 50,
              alignment: isRTL
                  ? (type == DashboardReelPageType.forYou
                      ? Alignment.centerRight
                      : Alignment.centerLeft)
                  : (type == DashboardReelPageType.forYou
                      ? Alignment.centerLeft
                      : Alignment.centerRight),
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                child: Text(
                  type.title.tr,
                  style: (type == controller.selectedPageType.value
                          ? MyTextStyle.gilroyBold(color: cWhite, size: 18)
                          : MyTextStyle.gilroyRegular(color: cWhite, size: 18))
                      .copyWith(
                    shadows: [
                      BoxShadow(
                          color: cBlack.withValues(alpha: 0.3), blurRadius: 50)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: cBlack,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.onChangePage,
            physics: NeverScrollableScrollPhysics(),
            children: [
              ReelsScreen(
                reels: controller.reelsOfFollowings,
                position: 0.obs,
                pageType: ReelPageType.following,
                isLoading: controller.isLoading,
                onFetchMoreData: controller.fetchFollowingReels,
                onRefresh: controller.fetchReels,
                noReelDescription: LKeys.noReelsFromFollowings,
                overlayTabBar: true,
              ),
              ReelsScreen(
                reels: controller.reels,
                position: 0.obs,
                pageType: ReelPageType.home,
                isLoading: controller.isLoading,
                onFetchMoreData: controller.fetchReels,
                onRefresh: controller.refreshReels,
                overlayTabBar: true,
              )
            ],
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                topTag(DashboardReelPageType.following),
                Container(
                  height: 15,
                  width: 1,
                  color: cWhite,
                ),
                topTag(DashboardReelPageType.forYou),
              ],
            ),
          )
        ],
      ),
    );
  }
}
