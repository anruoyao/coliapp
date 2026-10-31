import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/screens/reels_screen/reels_screen.dart';
import 'package:untitled/screens/single_reel_screen/single_reel_screen_controller.dart';

class SingleReelScreen extends StatelessWidget {
  final int reelId;

  const SingleReelScreen({super.key, required this.reelId});

  @override
  Widget build(BuildContext context) {
    SingleReelScreenController controller =
        Get.put(SingleReelScreenController(reelId));
    return ReelsScreen(
      reels: controller.reels,
      position: 0.obs,
      pageType: ReelPageType.single,
      isLoading: controller.isLoading,
    );
  }
}
