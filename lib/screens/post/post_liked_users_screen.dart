import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/post/post_liked_users_controller.dart';
import 'package:untitled/screens/search_screen/search_screen.dart';

class PostLikedUsersScreen extends StatelessWidget {
  final int postId;

  const PostLikedUsersScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    PostLikedUsersController controller = PostLikedUsersController(postId);
    return Scaffold(
      body: GetBuilder(
        init: controller,
        builder: (controller) {
          return Column(
            children: [
              TopBarForInView(title: LKeys.users.tr),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: controller.users.length,
                  itemBuilder: (context, index) {
                    return ProfileCard(user: controller.users[index]);
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
