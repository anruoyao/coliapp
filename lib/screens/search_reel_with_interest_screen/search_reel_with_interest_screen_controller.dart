import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/setting_model.dart';

class SearchReelWithInterestScreenController extends BaseController {
  RxList<Reel> reels = RxList();
  Interest interest;
  TextEditingController textEditingController = TextEditingController();

  SearchReelWithInterestScreenController(this.interest);

  @override
  void onReady() {
    searchReels();
    super.onReady();
  }

  Future<void> searchReels({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      reels.clear();
    }
    isLoading.value = true;

    var newReels = await ReelService.shared.searchReels(
      start: reels.length,
      keyword: searchText,
      interestId: interest.id,
    );
    isLoading.value = false;
    reels.addAll(newReels);
  }

  void onSearchTextChanged() {
    MyDebouncer.shared.run(() {
      searchReels(shouldErase: true);
    });
  }
}
