import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/interests_screen/interests_controller.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/rooms_by_interest_screen.dart';
import 'package:untitled/utilities/const.dart';

class RoomExploreByInterests extends StatelessWidget {
  const RoomExploreByInterests({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData().copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        iconColor: cPrimary,
        tilePadding: const EdgeInsets.only(right: 10, left: 10, top: 5),
        title: const TopBarForLogin(
          titleEnd: LKeys.interests,
          titleStart: LKeys.exploreBy,
          alignment: MainAxisAlignment.start,
          size: 22,
        ),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              alignment: WrapAlignment.start,
              children: InterestsController.interests.map((tag) {
                return RoomInterestTag(
                  title: tag.title,
                  count: tag.totalRoomOfInterest?.toInt(),
                  onTap: () {
                    Get.to(() => RoomsByInterestScreen(interest: tag),
                        opaque: false);
                  },
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

class RoomInterestTag extends StatelessWidget {
  const RoomInterestTag({Key? key, required this.title, this.onTap, this.count})
      : super(key: key);
  final String? title;
  final int? count;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: cPrimary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: FittedBox(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Text(
                  title?.toUpperCase() ?? '',
                  style: MyTextStyle.gilroyBold(size: 14, color: cBlack)
                      .copyWith(letterSpacing: 0.5),
                ),
                count != null
                    ? Row(
                        children: [
                          const SizedBox(width: 7),
                          Text(
                            count?.makeToString() ?? '',
                            style: MyTextStyle.gilroyLight(
                                size: 14, color: cBlack),
                          ),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
