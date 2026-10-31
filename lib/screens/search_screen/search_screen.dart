import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/extra_views/search_bar.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/interests_screen/interests_controller.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/reels_screen/reels_grid.dart';
import 'package:untitled/screens/search_post_with_interest_screen/search_post_with_interest_screen.dart';
import 'package:untitled/screens/search_reel_with_interest_screen/search_reel_with_interest_screen.dart';
import 'package:untitled/screens/search_screen/search_controller.dart';
import 'package:untitled/screens/tag_screen/tag_screen.dart';
import 'package:untitled/utilities/const.dart';

import '../rooms_screen/rooms_by_interest/room_explore_by_interests.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(SearchScreenController());
    return Scaffold(
      body: GetBuilder(
          init: controller,
          builder: (context) {
            return Column(
              children: [
                const TopBarForInView(title: LKeys.search),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: MySearchBar(
                    controller: controller.textEditingController,
                    onChange: (text) {
                      controller.onSearchTextChanged();
                    },
                  ),
                ),
                // const SizedBox(height: 5),

                segmentController(controller),
                const SizedBox(height: 5),
                Expanded(
                  child: PageView(
                    controller: controller.controller,
                    onPageChanged: controller.onChangePage,
                    children: [
                      usersView(controller),
                      postsView(controller),
                      reelsView(controller),
                      hashtagView(controller),
                    ],
                  ),
                )
              ],
            );
          }),
    );
  }

  Widget hashtagView(SearchScreenController controller) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 10, bottom: Get.bottomBarHeight),
      itemCount: controller.filterTags.length,
      itemBuilder: (context, index) {
        var tag = controller.filterTags[index];
        return InkWell(
          onTap: () {
            Get.to(() => TagScreen(tag: '#${tag.tag ?? ''}'), opaque: false);
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 15),
            child: Row(
              children: [
                Container(
                  decoration: ShapeDecoration(
                      shape: CircleBorder(
                          side: BorderSide(
                              width: 2,
                              color: cLightText.withValues(alpha: 0.1)))),
                  padding: EdgeInsets.all(5),
                  child: Image.asset(
                    MyImages.hashtag,
                    height: 30,
                    width: 30,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${tag.tag ?? ''}',
                      style: MyTextStyle.gilroySemiBold(size: 18),
                    ),
                    Text(
                      '${tag.postCount?.toInt().makeToString() ?? '0'} ${LKeys.posts.tr}',
                      style:
                          MyTextStyle.gilroyMedium(color: cLightText, size: 14),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget reelsView(SearchScreenController controller) {
    return LoadMoreWidget(
      loadMore: controller.searchReel,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 40,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: InterestsController.interests.length,
                itemBuilder: (context, index) {
                  var tag = InterestsController.interests[index];
                  return RoomInterestTag(
                    title: tag.title,
                    onTap: () {
                      Get.to(() => SearchReelWithInterestScreen(interest: tag),
                          opaque: false);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ReelsGrid(
              reels: controller.reels,
              reelType: ReelPageType.search,
              isLoading: controller.isLoading,
              onFetchMoreData: controller.searchReel,
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget postsView(SearchScreenController controller) {
    return LoadMoreWidget(
      loadMore: controller.searchPost,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 40,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: InterestsController.interests.length,
                itemBuilder: (context, index) {
                  var tag = InterestsController.interests[index];
                  return RoomInterestTag(
                    title: tag.title,
                    onTap: () {
                      Get.to(() => SearchPostWithInterestScreen(interest: tag),
                          opaque: false);
                    },
                  );
                },
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: controller.posts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  post: controller.posts[index],
                  onDeletePost: (postID) {
                    controller.posts
                        .removeWhere((element) => element.id == postID);
                    controller.update();
                  },
                  refreshView: () {
                    controller.update();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget usersView(SearchScreenController controller) {
    return LoadMoreWidget(
      loadMore: controller.searchUser,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: controller.users.length,
        itemBuilder: (context, index) {
          return ProfileCard(user: controller.users[index]);
        },
      ),
    );
  }

  Widget segmentController(SearchScreenController controller) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 1,
          color: cLightText.withValues(alpha: 0.3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              controller.allPages.length,
              (index) {
                return InkWell(
                  onTap: () {
                    controller.onChangeSegment(index);
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 1,
                        width: 30,
                        color: controller.selectedPage == index
                            ? cBlack
                            : Colors.transparent,
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        child: Text(
                          controller.allPages.values.toList()[index].tr,
                          style: controller.selectedPage == index
                              ? MyTextStyle.gilroySemiBold(
                                  size: 16, color: cDarkText)
                              : MyTextStyle.gilroyRegular(
                                  size: 16, color: cDarkText),
                        ),
                      ),
                    ],
                  ),
                );
              },
              // scrollDirection: Axis.horizontal,
              // padding: EdgeInsets.symmetric(horizontal: 10),
              // itemBuilder: (context, index) {
              //
              // },
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileCard extends StatelessWidget {
  final User user;
  final Widget? widget;

  const ProfileCard({Key? key, required this.user, this.widget})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => ProfileScreen(userId: user.id ?? 0), opaque: false);
      },
      child: Column(
        children: [
          Container(
            color: Colors.transparent,
            child: Row(
              children: [
                MyCachedImage(
                  imageUrl: user.profile,
                  width: 55,
                  height: 55,
                  cornerRadius: 12,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName ?? 'Unknown',
                              style: MyTextStyle.gilroyBold(size: 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          VerifyIcon(user: user)
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "@${user.username ?? "unknown"}",
                        style: MyTextStyle.gilroyLight(
                            color: cLightText, size: 15),
                      ),
                    ],
                  ),
                ),
                // const Spacer(),
                widget ?? Container()
              ],
            ),
          ),
          const Divider()
        ],
      ),
    );
  }
}
