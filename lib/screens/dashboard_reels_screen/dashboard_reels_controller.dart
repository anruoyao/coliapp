import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_model.dart';

class DashboardReelsController extends BaseController {
  RxList<Reel> reels = <Reel>[].obs;
  RxList<Reel> reelsOfFollowings = <Reel>[].obs;
  PageController pageController =
      PageController(initialPage: DashboardReelPageType.forYou.value);
  Rx<DashboardReelPageType> selectedPageType = DashboardReelPageType.forYou.obs;

  @override
  void onReady() {
    fetchReels();
    fetchFollowingReels();
    super.onReady();
  }

  Future<void> fetchReels({bool shouldReset = false}) async {
    isLoading.value = true;
    var newReels = await ReelService.shared.fetchExploreReels(
      start: shouldReset ? 0 : reels.length,
      type: selectedPageType.value.value,
    );
    if (shouldReset) {
      reels.clear();
    }
    reels.addAll(newReels);
    isLoading.value = false;
  }

  Future<void> refreshReels() async {
    await fetchReels(shouldReset: true);
  }

  Future<void> fetchFollowingReels({bool shouldReset = false}) async {
    isLoading.value = true;
    var newReels = await ReelService.shared.fetchExploreReels(
      start: shouldReset ? 0 : reelsOfFollowings.length,
      type: DashboardReelPageType.following.value,
    );
    if (shouldReset) {
      reelsOfFollowings.clear();
    }
    reelsOfFollowings.addAll(newReels);
    isLoading.value = false;
  }

  Future<void> refreshFollowingReels() async {
    await fetchFollowingReels(shouldReset: true);
  }

  void onChangePage(int value) {
    selectedPageType.value = DashboardReelPageType.values
        .firstWhere((element) => element.value == value);
  }

  void changeTheType(DashboardReelPageType type) {
    selectedPageType.value = type;
    pageController.animateToPage(type.value,
        duration: Duration(milliseconds: 200), curve: Curves.bounceInOut);
  }
}

enum DashboardReelPageType {
  forYou(1),
  following(0);

  final int value;

  const DashboardReelPageType(this.value);

  String get title {
    switch (this) {
      case DashboardReelPageType.forYou:
        return LKeys.forYou;
      case DashboardReelPageType.following:
        return LKeys.following;
    }
  }
}
