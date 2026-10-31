import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/setting_model.dart';

class SearchPostWithInterestScreenController extends BaseController {
  TextEditingController textEditingController = TextEditingController();
  RxList<Post> posts = RxList();
  Interest interest;

  SearchPostWithInterestScreenController(this.interest);

  @override
  void onReady() {
    startLoading();
    fetchPosts();
    super.onReady();
  }

  Future<void> fetchPosts({bool shouldErase = false}) async {
    var newPosts = await PostService.shared.searchPostsWithInterest(
      query: textEditingController.text,
      start: posts.length,
      interestId: interest.id ?? 0,
    );
    if (shouldErase) {
      posts.clear();
    }
    stopLoading();
    posts.addAll(newPosts);
  }

  void onSearchTextChanged() {
    MyDebouncer.shared.run(() {
      fetchPosts(shouldErase: true);
    });
  }
}
