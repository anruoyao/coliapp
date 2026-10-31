import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/screens/notification_screen/notification_screen.dart';
import 'package:untitled/screens/random_screen/random_screen.dart';
import 'package:untitled/screens/search_screen/search_screen.dart';
import 'package:untitled/utilities/const.dart';

class FeedScreenTopBar extends StatelessWidget {
  const FeedScreenTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double imageSize = 25;
    return Container(
      color: cBG,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const LogoTag(),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.to(() => const NotificationScreen(), opaque: false);
                  },
                  child: Image.asset(
                    MyImages.bell,
                    width: imageSize,
                    height: imageSize,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Get.to(() => RandomScreen(), opaque: false);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Image.asset(
                      MyImages.random,
                      width: 20,
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Get.to(() => const SearchScreen(), opaque: false);
                  },
                  child: Image.asset(
                    MyImages.search,
                    width: imageSize,
                    height: imageSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
