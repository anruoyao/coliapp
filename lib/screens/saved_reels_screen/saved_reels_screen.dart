import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/reels_screen/reels_grid.dart';
import 'package:untitled/screens/saved_reels_screen/saved_reels_screen_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SavedReelsScreen extends StatelessWidget {
  const SavedReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SavedReelsScreenController controller =
        Get.put(SavedReelsScreenController());
    return Scaffold(
      body: VisibilityDetector(
        key: Key('saved_reels'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 1) {
            if (!controller.isLoading.value) {
              controller.fetchReels(shouldRefresh: true);
            }
          }
        },
        child: Column(
          children: [
            TopBarForInView(title: LKeys.savedReels),
            Expanded(
              child: ReelsGrid(
                reels: controller.reels,
                reelType: ReelPageType.saved,
                isLoading: controller.isLoading,
                onFetchMoreData: controller.fetchReels,
              ),
            )
          ],
        ),
      ),
    );
  }
}
