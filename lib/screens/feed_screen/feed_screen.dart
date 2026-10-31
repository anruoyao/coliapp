import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/buttons/floating_btn_for_creating.dart';
import 'package:untitled/common/widgets/loader_widget.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';
import 'package:untitled/screens/feed_screen/feed_screen_top_bar.dart';
import 'package:untitled/screens/feed_screen/feed_stories_controller.dart';
import 'package:untitled/screens/feed_screen/feed_story_screen.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/rooms_screen/room_card.dart';
import 'package:untitled/utilities/const.dart';

final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
    new GlobalKey<RefreshIndicatorState>();

class FeedScreen extends StatelessWidget {
  final ScrollController scrollController;

  const FeedScreen({Key? key, required this.scrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    FeedScreenController controller = FeedScreenController(
        isFromFeedScreen: true, scrollController: scrollController);
    FeedStoriesController feedStoriesController = FeedStoriesController();
    return Scaffold(
      backgroundColor: cWhite,
      body: GetBuilder(
          init: feedStoriesController,
          builder: (feedStoriesController) {
            return GetBuilder(
                init: controller,
                builder: (controller) {
                  return Column(
                    children: [
                      const FeedScreenTopBar(),
                      Container(color: cLightBg, height: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            if (controller.isLoading.value &&
                                controller.posts.isEmpty)
                              LoaderWidget()
                            else
                              RefreshIndicator(
                                key: refreshIndicatorKey,
                                triggerMode:
                                    RefreshIndicatorTriggerMode.anywhere,
                                color: refreshIndicatorColor,
                                backgroundColor: refreshIndicatorBgColor,
                                child: SingleChildScrollView(
                                  controller: controller.scrollController,
                                  primary: false,
                                  child: Column(
                                    children: [
                                      FeedStoryScreen(
                                          controller: feedStoriesController),
                                      Container(color: cLightBg, height: 5),
                                      Container(
                                        color: cWhite,
                                        child: FeedsView(
                                          controller: controller,
                                          id: controller.feedViewID,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onRefresh: () async {
                                  await controller.fetchFeeds(
                                      isForRefresh: true);
                                  await feedStoriesController.fetchStories();
                                  return await feedStoriesController
                                      .fetchMyStories();
                                },
                              ),
                            FloatingBtnForCreating(
                              overlayTabBar: true,
                              onPostBack: (feed) {
                                Future.delayed(Duration(milliseconds: 100), () {
                                  controller.posts.insert(0, feed);
                                  controller.update([controller.feedViewID]);
                                  controller.update();
                                });
                              },
                              onStoryBack: () {
                                feedStoriesController.fetchMyStories();
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                });
          }),
    );
  }
}

class FeedsView extends StatelessWidget {
  const FeedsView({
    super.key,
    required this.controller,
    required this.id,
  });

  final FeedScreenController controller;
  final String id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      tag: id,
      builder: (controller) {
        return NoDataView(
          showShow: controller.posts.isEmpty && !controller.isLoading.value,
          title: LKeys.noPosts.tr,
          child: SafeArea(
            top: false,
            child: ListView.builder(
              primary: false,
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 5),
              itemCount: controller.posts.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    (index == 2 && controller.suggestedRooms.isNotEmpty)
                        ? Container(
                            color: cBlack,
                            padding: const EdgeInsets.only(
                                top: 20, right: 10, left: 10, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      LKeys.suggested.tr,
                                      style: MyTextStyle.gilroyLight(
                                          color: cWhite, size: 17),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      LKeys.rooms.tr,
                                      style: MyTextStyle.gilroyBold(
                                          color: cWhite, size: 17),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 250,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: controller.suggestedRooms.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: Get.width / 50),
                                        child: RoomCard(
                                          room:
                                              controller.suggestedRooms[index],
                                          isFromHome: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          )
                        : Container(),
                    PostCard(
                      post: controller.posts[index],
                      onDeletePost: (postID) {
                        controller.posts
                            .removeWhere((element) => element.id == postID);
                        controller.update();
                      },
                      refreshView: () {
                        controller.update();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
