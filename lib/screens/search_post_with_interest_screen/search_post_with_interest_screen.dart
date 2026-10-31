import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/extra_views/search_bar.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/room_explore_by_interests.dart';
import 'package:untitled/screens/search_post_with_interest_screen/search_post_with_interest_screen_controller.dart';

class SearchPostWithInterestScreen extends StatelessWidget {
  final Interest interest;

  const SearchPostWithInterestScreen({super.key, required this.interest});

  @override
  Widget build(BuildContext context) {
    SearchPostWithInterestScreenController controller =
        Get.put(SearchPostWithInterestScreenController(interest));
    return Scaffold(
      body: Column(
        children: [
          TopBarForInView(
            title: LKeys.posts,
            child: RoomInterestTag(title: interest.title ?? '', onTap: () {}),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: MySearchBar(
              controller: controller.textEditingController,
              onChange: (text) {
                controller.onSearchTextChanged();
              },
            ),
          ),
          Expanded(
            child: Obx(
              () => NoDataView(
                showShow:
                    controller.posts.isEmpty && !controller.isLoading.value,
                title: LKeys.noPosts,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: controller.posts.length,
                  itemBuilder: (context, index) {
                    return PostCard(
                      post: controller.posts[index],
                      onDeletePost: (postID) {},
                      refreshView: () {
                        controller.update();
                      },
                    );
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
