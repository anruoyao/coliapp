import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/cupertino_controller.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/search_hashtags_model.dart';

class SearchScreenController extends CupertinoController {
  List<User> users = [];
  List<Post> posts = [];
  RxList<Reel> reels = RxList();
  List<SearchTag> tags = [];
  List<SearchTag> filterTags = [];
  TextEditingController textEditingController = TextEditingController();

  var allPages = {
    0: LKeys.users,
    1: LKeys.posts,
    2: LKeys.reels,
    3: LKeys.hashtags,
  };

  @override
  void onReady() {
    super.onReady();
    searchUser();
    searchPost();
    searchReel();
    fetchAllHashtags();
  }

  void onSearchTextChanged() {
    MyDebouncer.shared.run(() {
      _performSearch();
    });
  }

  void _performSearch() {
    searchUser(shouldErase: true);
    searchPost(shouldErase: true);
    searchReel(shouldErase: true);
    searchHashtags();
  }

  void fetchAllHashtags() {
    PostService.shared.searchHashtags(
      textEditingController.text,
      tags.length,
      (newTags) {
        tags = newTags;
        filterTags = newTags;
        update();
      },
    );
  }

  void searchHashtags({bool shouldErase = false}) {
    String searchText = textEditingController.text.toLowerCase();
    if (searchText.isEmpty) {
      filterTags = tags;
    } else {
      filterTags = tags.where((element) {
        return element.tag?.toLowerCase().contains(searchText) ?? false;
      }).toList();
    }
    update();
  }

  Future<void> searchReel({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      reels.clear();
    }
    isLoading.value = true;

    var newReels = await ReelService.shared
        .searchReels(start: reels.length, keyword: searchText);
    reels.addAll(newReels);
  }

  Future<void> searchPost({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      posts = [];
    }
    isLoading.value = true;

    await PostService.shared.searchPosts(
      searchText,
      posts.length,
      (newPosts) {
        isLoading.value = false;
        if (shouldErase) {
          posts = newPosts;
        } else {
          posts.addAll(newPosts);
        }
        update();
      },
    );
  }

  Future<void> searchUser({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      users = [];
    }
    isLoading.value = true;

    await UserService.shared.searchProfile(
      searchText,
      users.length,
      (newUsers) {
        isLoading.value = false;
        if (shouldErase) {
          users = newUsers;
        } else {
          users.addAll(newUsers);
        }
        update();
      },
    );
  }
}
