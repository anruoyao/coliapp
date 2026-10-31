import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';

class TagController extends FeedScreenController {
  String tag;
  RxList<Reel> reels = RxList();

  RxInt selectedPage = 0.obs;

  PageController controller;

  TagController(this.tag, this.controller) {
    selectedPage.value = this.controller.initialPage;
  }

  @override
  void onReady() {
    fetchPosts();
    fetchReels();
    super.onReady();
  }

  void fetchPosts() {
    if (posts.isEmpty) {
      startLoading();
    }
    PostService.shared.fetchPostsByHashtag(tag, posts.length, (p0) {
      stopLoading();
      posts.value = p0;
      update();
    });
  }

  Future<void> fetchReels() async {
    if (reels.isEmpty) {
      // startLoading();
    }
    reels.addAll(
        await ReelService.shared.fetchReelsByHashtag(tag, reels.length));
    // stopLoading();
  }

  void onChangeSegment(int value) {
    selectedPage.value = value;
    controller.jumpToPage(value);
  }
}
